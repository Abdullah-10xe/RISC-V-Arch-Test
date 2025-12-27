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
 // PMP region setup
 // Set the mseccfg RLB bit (bit 2) 

   li t0,0x4
   csrw mseccfg ,t0
  
   la t0, trap_handler  // Set mtvec to trap handler base address
   li t1, 0xFFFFFFFC    // Clear lower 2 bits (ensure it's aligned)
   and t0, t0, t1     
   csrw mtvec, t0
                                                              
   li t0,0x80000000  // 4KB NAPOT region for main code: M-mode execute-only permission
   srli t0,t0,2
   li t1,0x1FF
   or t1,t1,t0
   csrw pmpaddr0,t1
   
   li t0,0x80001000  // 4KB NAPOT region for 'tohost': read/write permissions as we set MLL bit
   srli t0,t0,2
   li t1,0x1FF
   or t1,t1,t0
   csrw pmpaddr1,t1
     
   li t0,0x80002000  // 4KB NAPOT region: locked, read-only permissions  
   srli t0,t0,2
   li t1,0x1FF
   or t1,t1,t0
   csrw pmpaddr2,t1
   
   li t0,0x80003000  // 4KB NAPOT region: locked, M-mode execute-only permission (used for trap handler) as we set MML
   srli t0,t0,2
   li t1,0x1FF
   or t1,t1,t0
   csrw pmpaddr3,t1
   
   li t0,0x9C999A9C    // Configure PMP entries with permissions and locking
   csrw pmpcfg0,t0

   li t0,0x5          // Set mseccfg with MML and RLB
   csrw mseccfg ,t0

   addi a0,x0,40      // Dummy instruction
   j only_read_permission  // Jump to a read-only region (will trigger access fault)

.align 6

test_pass:
    j write_tohost

.align 2    

write_tohost:
    li gp, 1
    sw gp, tohost, t5
    j write_tohost

.text 

only_read_permission:
   addi a0,x0,40      // Instruction in read-only region (not executable), will trap
   j test_pass       // jump to test pass section
   
.section .handler,"ax"
.global trap_handler

trap_handler:  
  li a0, 0x9C9A1A9C   // Update PMP to give execute permission to M-mode for trapped region
  csrw pmpcfg0,a0
  mret                // Return from trap

.data

base:
.word 0xcafebeef

RVTEST_DATA_BEGIN

