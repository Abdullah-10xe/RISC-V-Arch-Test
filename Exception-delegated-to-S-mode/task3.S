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
   /// setting up mtvec and stvec
    la t0,m_trap_handler
    csrw mtvec,t0
    la t0 ,supervisor_trap_handler
    csrw stvec,t0
    // set 4 th bit for illegal instruction delegation bit 
    csrr t0,medeleg
    li t1,0x04
    or t0,t0,t1
    csrw medeleg,t0
    li a0,0
    jal ra ,function
   // C.add a0, a6
   .word 0x8542
    li t1,1
    beq a0, t1 , test_pass
    nop
    j test_pass
.align 6

function:
 li t2,1
 beq a0 ,x0, supervisor
 beq a0 ,t2,user
 j test_fail
 user:
  li t2,0x00001800
  csrrc t1,mstatus,t2
  csrrw t1,mepc,ra
  mret
  supervisor:
  li t2,0x00001800
  csrc mstatus,t2
  li t2,0x00000800
  csrs mstatus ,t2
  csrrw t1,mepc,ra
  mret
  
  
user_mode:
 ecall
 
s_user_mode: 
  ecall
  
  
  
  
supervisor_trap_handler:
     csrr t0,stval
     li t1, 0x8542
     beq t1,t0,emulate
     li a0,0
     csrr t1,sepc
     addi t1,t1,4
     csrw sepc,t1
     sret
     
emulate:
     add s1,s1,a0
     addi a0 ,x0,1
     csrr t1,sepc
     addi t1,t1,4
     csrw sepc,t1
     sret
   
   //  
m_trap_handler:
   j test_pass


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
