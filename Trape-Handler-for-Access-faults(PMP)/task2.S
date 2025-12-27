#define RVTEST_DATA_BEGIN                                               \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 6; .global tohost; tohost: .dword 0; .size tohost, 8;    \
        .align 6; .global fromhost; fromhost: .dword 0; .size fromhost, 8;\
        .popsection;                                                    \
        .align 4; .global begin_signature; begin_signature:
#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .align  6;                                                      \
        .global _start;                         \
        .global function;\
_start:                                 \
        j main;                             \
trap_vector:                                                            \
    csrr t5, mcause ;                       \
    nop;                                \
    nop;                                \
    nop;                                \
    nop;                                \
    nop;                                \
    j write_tohost
RVTEST_CODE_BEGIN
main:
//  PMP region Set
   la t0, trap_handler
   li t1, ~1
   and t0, t0, t1        # Clear LSB to enforce direct mode
   csrw mtvec, t0
    // setup inst_text_section
    li t0, 0x80000000
    srli t0,t0,2
    ori t0,t0,0x1FF  
    csrw pmpaddr0,t0
    //setup tor section
    li t0,0x80002000
    srli t0,t0,2
    li t1,0x80003000
    srli t1,t1,2 
    csrw pmpaddr2,t1
    csrw pmpaddr1,t0
    //setup tohost 
    li t0,0x80001000
    srli t0,t0,2
    ori t0,t0,0x1FF 
    csrw pmpaddr3,t0
    li t1, 0x1b0c0319
    csrw pmpcfg0,t1 
    li a0 ,0x80003000
    srli a0,a0,2
    ori a0,a0,0x1FF
    csrw pmpaddr4,a0
    li a0,0x1F
    csrw pmpcfg1,a0
    // switching the supervisor mode
    li a0,0
    jal ra ,function
    li a5,0x80002100
    li t1,2
    sw t1,0(a5)
    jal ra , s_user_mode
    li a1,0 // will use in trap handler
    /// now apply permmission restriction on machine mode on both region 
    li a0, 0x020004
    csrc pmpcfg0 ,a0
    li a0,0x800080
     csrs pmpcfg0 ,a0
    //  switching back to machine mode
    
m_inst_test:
load_m_mode_test:
store_m_mode_test:
    j test_pass
.align 6

function:
 li t2,1
 beq a0 ,x0, supervisor
 beq a0 ,t2,user
 j test_fail
 user:
  li t2,0x00000c00
  csrrc t1,mstatus,t2
  csrrw t1,mepc,ra
  mret
  supervisor:
  li t2,0x00001000
  csrrc t1 ,mstatus ,t2
  li t2 ,0x00000800
  csrrs t1,mstatus,t2
  csrrw t1,mepc,ra
  mret
  
  
user_mode:
s_user_mode: 
  ecall
.section .handler,"ax"
.global trap_handler
trap_handler:
// handling exception base on exception code 
  csrr t0,pmpcfg0
  li a0,0x80
  and t0,t0,a0
  beq t0 ,a0 ,m_lock
  
  
  csrrs t0,mcause ,x0
  addi t1,x0,8
  addi t2,x0,9
  addi t3,x0,1
  addi t4,x0,5
  addi t6,x0,7
  beq t1 ,t0,user_casue
  beq t2,t0, s_cause
  beq t3,t0, int_access_fault
  beq t4 ,t0 , load_access_fault
  beq t6 ,t0, store_access_fault 
  j test_fail
int_access_fault :
  li t1, 0x040004
  csrr t0,pmpcfg0
  or t0,t0,t1
  csrw pmpcfg0 ,t0
  mret
load_access_fault:
  li t1,0x010001
  csrr t0,pmpcfg0
  or t0,t0,t1
  csrw pmpcfg0 ,t0
  mret
store_access_fault:
  li t1,0x030303
  csrr t0,pmpcfg0
  or t0,t0,t1
  csrw pmpcfg0 ,t0
  mret
m_lock:
li t1,2
beq a1,t1 ,test_pass
 li a1,2
 li t1,0x80002100
 sw t1,0(t1)
 j test_pass
user_casue:
  li t2,0xFFFEFFF
  csrrc t1,mstatus,x0
  and t2,t2,t1
  csrrw t1,mstatus,t2
  li t2,0x00000800
  csrrs t1,mstatus,t2
  csrrw t1,mepc,ra
  mret
s_cause:
  li t2,0x0001800
  csrrs t1,mstatus,t2
  csrrw t1,mepc,ra
  li t1,0
  mret 
  


test_fail:
	j test_fail
    
test_pass:
    j write_tohost
.align 2    
write_tohost:
    li gp, 1
    sw gp, tohost, t5
    j write_tohost
    
.data
base:
.word 0xcafebeef
RVTEST_DATA_BEGIN
