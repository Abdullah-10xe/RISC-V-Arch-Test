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
 la a0,trap_handler           // Trap handler address setup
 csrw mtvec,a0
 sfence.vma x0,x0             // Flushing TLB
 la a0  ,0x80000000          //  Virtual address space                        
 la a1,lv0_table            // Root table address
 li a2, 0x01               // Permission set for PPN1
 li a3,1                  // Level 1 page root page
 jal ra ,PTE_SETUP           // Setup the root page 
 li a0  ,0x80000000          // Virtual address                    
 la a1,Data_and_int_page    // Leaf page address 
 li a2, 0xCF                // Permission initialize all permissions
 li a3,0
 jal ra ,PTE_SETUP        // Jump to leaf PTE_SETUP level 0

 li a0,0                 
 la t0, lv1_table        // Root node address 
 srli t0,t0,12          // Shift out offset
 li t1,0x80000000
 or t0,t0,t1
 csrw satp,t0          // Set SATP with mode 1 and PPN with LV1TABLE>>12
 li a0,0
 li ra ,0x80000000    //  This will use for MEPC, first virtual instruction address 
 j function           //  Switch to supervisor and execute some instruction read/write also tested in this 
 
 ///   In virtual address, ECALL instruction that switches mode to M and PC this label
gen_inst_page_fault:      
 li a0  ,0x80000000 //  Virtual address                        
 la a1,Data_and_int_page
 li a2, 0xC1          ///    Permissions are zero as we jumped to virtual address, it generates instruction page fault
 li a3,0
 jal ra ,PTE_SETUP
 li a0,0
 li ra ,0x80000020      //  MEPC will load this virtual address 
 j function             // Switch the mode from M to supervisor
  
gen_load_page_fault:    // We jumped from trap handler after testing inst page fault
 
 li a0  ,0x80000000 //  Virtual address                        
 la a1,Data_and_int_page
 li a2, 0xC9             ///  Only execution is allowed, now this will generate load page fault
 li a3,0
 jal ra ,PTE_SETUP
 li a0,0
 li ra ,0x80000020      //  MEPC will load this virtual address 
 j function            // MEPC will load this virtual address

gen_store_page_fault:
 li a0  ,0x80000000 //  Virtual address                        
 la a1,Data_and_int_page
 li a2, 0xC9             // This will generate the store page fault
 li a3,0
 jal ra ,PTE_SETUP
 li a0,0
 li ra ,0x8000002c     // MEPC loads this virtual address and these instructions use store instruction 
 j function            // Switch from M-mode to supervisor mode

end_main:
 j test_pass

PTE_SETUP:
  li t0,1
  beq a3,t0,LV1_PTE_SETUP
  beq a3,x0,LV0_PTE_SETUP
  j  test_fail            // Fail if page level is greater than 1

LV1_PTE_SETUP:
  la t0,lv1_table  // Physical address of level 1 
  srli t1,a0,22     // Extract VPN1
  slli t1,t1,2
  add t0,t0,t1       // Generated physical address for level 1 PTE
  // Setup PTE for level 1
  srli a1,a1,12   // Extract 22 bits which are level 0 page, first PTE 0x80003 000
  slli a1,a1,10
  or a1,a1,a2    // Add permissions
  sw a1,0(t0)
  ret
  
LV0_PTE_SETUP:
  la t0,lv0_table /// Level 0 page address 
  // Extract the VPN0
  li t1,0x003FF000
  and t1,t1,a0    /// Extraction of VPN0
  srli t1,t1,10
  add t0,t0,t1   /// lv0_PTE physical address is constructed 
  
  // Add upper 22 bits of DATA page address
  srli a1,a1,12  // a1 holds DATA_INST page address
  slli a1,a1,10
  or a1,a1,a2  // Set permissions 
  sw a1,0(t0)
  ret	

///// THIS FUNCTION IS USED TO SWITCH THE MODE 

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

/////  TRAP HANDLER 
trap_handler:
  csrr t0,mcause
  li a0,9
  beq t0,a0,s_cause
  li a0,12
  beq t0,a0,ints_page_fault
  li a0,13
  beq t0,a0,load_page_fault
  li a0,15
  beq a0,t0,store_page_fault
  j test_fail

ints_page_fault:
  j gen_load_page_fault
load_page_fault:
  j gen_store_page_fault
store_page_fault:
  j end_main 

s_cause:
  li t2,0x0001800
  csrrs t1,mstatus,t2
  la ra,gen_inst_page_fault
  csrrw t1,mepc,ra
  li t1,0
  mret 
  

test_fail:
    li gp, 2
    sw gp, tohost, t5
    j write_tohost

trap_handle:
test_pass:
    j write_tohost

.align 2    
write_tohost:
    li gp, 1
    sw gp, tohost, t5
    j write_tohost

.data
base:
// Node page table 
.section .vm ,"ax"  // Creating the page space for first level table
lv1_table: 
  .space 4096
lv0_table:         // For second level
.space 4096
Data_and_int_page:  // Page for data and instruction
 li a0,1            // 0x80000000  Test with permission: load, store and inst
 li a1,2
 li a0,4
 li a0,0x80000124
 li t0 ,50
 sw t0,0(a0)
 ecall              // This will switch supervisor mode to M-mode and PC jump to gen_inst_fault 

 li a0,0x80000124      // 0x80000020  Test the load without permissions
 lw a1, 0(a0)
 
 li a0,0x80000124      // 0x80000028  This tests the store without permissions
 li a1,40
 sw a1,0(a0)

.space 4092
RVTEST_DATA_BEGIN

