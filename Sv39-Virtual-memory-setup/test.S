# TEST THEME   : PACHTAWA
# TEST OUTCOME : YOU WILL HATE WITH THE NUMBER "39"

#define RVTEST_DATA_BEGIN                                                    \
        .pushsection .tohost,"aw",@progbits;                                 \
        .align 6; .global tohost; tohost: .dword 0; .size tohost, 8;         \
        .align 6; .global fromhost; fromhost: .dword 0; .size fromhost, 8;   \
        .popsection;                                                         \
        .align 4; .global begin_signature; begin_signature:


#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .align  3;                                                      \
        .global _start;                                                 \
_start:;                                                                \
        li t0, 0x00000000200020c7;                                      \
        li t1, 0x00000000800050a0;                                      \
        sd t0, 0(t1);                                                   \
        j main                                                       
 
 #define Vaddr 0x00C0C0C000
RVTEST_CODE_BEGIN
main:
    
    # Set up trap handler
    la t0, trap_handler
    csrw mtvec, t0
    // 
 
/*
################### Put Your Code Here  ###################
*/
  sfence.vma

  la t1,Root_Page_Table
  // shifitng out 12 bit offest form address
  srli t1,t1,12
  // we only 27 bit addrss // and operation with mask  
  li t3, 0x8000000000000000 // Mode= sv39 
  or t3,t3,t1
  csrw satp ,t3 // writng satp with mode and 27 address 
  //// satp is completed
  sfence.vma
  
  
  //// setuping ROOT PAGE  PTE 
  la t0 ,Root_Page_Table
  la a0,Level_one_Page_Table
  srli a0,a0,12
  slli a0,a0,10
  li t1,0x01    // Permissions
  or a0,a0,t1
  li a1,0x00C0C0C000
  srli a1,a1,30
  slli a1,a1,3
  add t0,t0,a1
  sd a0,0(t0)
  /// Root page entry PTE is completed 
  
  
  ///  setuping The PTE fpr level_one page
  la a0, Level_one_Page_Table
  la a1,Level_zero_Page_Table
  srli a1,a1,12
  slli a1,a1,10
  li a3,0x01
  or a1,a1,a3
  li t0,Vaddr
  srli t0,t0,21
  li t1, 0x1FF
  and t0,t0,t1
  slli t0,t0,3
  add a0,a0,t0
  sd a1,0(a0)
  /// page level_one_page_entry is completed
  
  /// setup PTE of zero level
  la a0 ,Level_zero_Page_Table
  la a1 ,Test_Instruction
  srli a1,a1,12
  slli a1,a1,10
  li a2,0xCF
  or a1,a1,a2
  li t0,0x1FF
  li t1,Vaddr
  srli t1,t1,12
  and t1,t1,t0
  slli t1,t1,3
  add a0,a0,t1 
  sd a1,0(a0)
  
  ///////  swithcing to supervisor mode 
  li t1, 0x001800
  csrc mstatus,t1
  li t1, 0x000800
  csrs mstatus, t1
  li t0,Vaddr
  csrw mepc ,t0
  mret   


/*
Hint:  
1. Setup only 1 PTE at any random offset of each page table definded in .text section
2. Your code must point to the "Test_Instruction" at your leaf PTE in L0
3. You only need to setup 3 PTEs (One in each page)
4. Then you just need to setup mstatus, mepc and satp CSR (You need to store your VA into mepc and change the privilege)
5. USe this tool for quick calculations:: https://www.rapidtables.com/convert/number/hex-to-binary
*/



/*
################### End Your Code Here ###################

*/



/*
############## Don't Change The Below Code ###############
*/

test_pass:
    li a0, 1                    
    j write_tohost


test_fail:
    li a0, 2                 
    j write_tohost

    
write_tohost:
    la t5, tohost
    sd a0, 0(t5)
    j write_tohost

.align 12 
trap_handler:
    csrr t0, mcause  
    li t1, 0x9
    bne t0, t1, test_fail                                            
    li t3, 3
    slli t3, t3, 11
    csrs mstatus, t3  
    csrw mepc, ra                                                 
    mret  


.text                           # Defined in linker
.align 12                       # 4KB alignment
.data                           # This section/region serve as final 4k page
.global data
.align 12 
/* 
            You Need Some Page Tables In Memory (In Which You Have Your PTEs)
            So Use Below Page Tables To Setup Your PTEs
*/
Root_Page_Table:
    .space 4096                 # 8 bytes space per PTE for 512 entries. (4k total size for root page table)
Level_one_Page_Table:
    .space 4096                 # 8 bytes space per PTE for 512 entries. (4k total size for L1 page table)
Level_zero_Page_Table:
    .space 4096                 # 8 bytes space prt PTE for 512 entries. (4k total size for L2 page table)
.align 12 
Test_Instruction: 

    # Test 01: Load Data from a Random Location of "Random_Data"
    li t0, 0x0100 
    ld t1, 0(t0)                # load data from virtual addrress to t1
    li t2, 0x1234567890abcdef   # Actual data at virtual address 
    bne t1, t2, test_fail       # Compare loaded data with actual data

    # Test 02: Load Data from a Random Location of "Random_Data"
    li t0, 0x0100
    ld t1, 0(t0)                # load data from virtual addrress to t1
    li t2, 0xBADDCAFEFEEDFACE   # Actual data at virtual address make 
    bne t1, t2, test_fail       # Compare loaded data with actual data

    # Test 03: Store and then check Random Data at a Random Location of "Random_Data"
    li t0, 0x0100
    li t1, 0xAAAAAAAAAEEDFACE
    sd t1, 0(t0)                # Store data of t1 at virtual addrress saved in t0
    ld t2, 0(t0)                # Load new data of t0 at virtual addrress saved in t3
    bne t2, t1, test_fail       # Compare loaded data with actual data after stored new one

    ecall                       # (trap) Switch Privilege Mod


.align 12                       # 4KB alignment

Random_Data:

    .dword 0x1234567890ABCDEF, 0x0BADCAFEFEEDBEEF, 0xDEADBEEF12345678, 0xCAFEBABE87654321
    .dword 0x0011223344556677, 0x89ABCDEF01234567, 0xFEEDC0DEBEEFFACE, 0xBADDCAFEFEEDFACE
    .dword 0x1A2B3C4D5E6F7081, 0x9B8A7C6D5E4F3E2D, 0x0F1E2D3C4B5A6978, 0x0123456789ABCDEF
    .dword 0xF1F1F1F1F1F1F1F1, 0xA0A0A0A0A0A0A0A0, 0x7F00DCAFEF00DBAD, 0xDEADBEEFDEADBEEF
    .dword 0xC0FFEEBADDCAFEFE, 0xFEEDFACEBFDDCAFE, 0x12345658DEADBEEF, 0x9BADC0DE87EDC0DE
    .dword 0x0BADCAFEFEEDB0EF, 0xCAFEBABE87654321, 0x12345678DE555555, 0x9BADC0DEFEEDC786
    .dword 0xC0FF25BADDCAFEFE, 0xFEEDFACEBADDCAFE, 0xDEADBCCF12345678, 0x9BADC0DEFEE44444

RVTEST_DATA_BEGIN
