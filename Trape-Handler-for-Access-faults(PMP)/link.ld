OUTPUT_ARCH("riscv")
ENTRY(_start)

PHDRS
{
  text PT_LOAD FLAGS(0x5);     /* R + X */
  data PT_LOAD FLAGS(0x6);     /* R + W */
  handler PT_LOAD FLAGS(0x5);  /* R + X */
}

SECTIONS
{
  . = 0x80000000;

  .text.init : { *(.text.init) } :text

  . = ALIGN(0x1000);    /* 0x80001000 */
  .tohost : { *(.tohost) } :data

  . = ALIGN(0x1000);    /* 0x80002000 */
  .text : { *(.text) } :text

  . = ALIGN(0x1000);    /* 0x80003000 */
  .data : { *(.data) } :data
  .bss  : { *(.bss) }  :data

  . = ALIGN(0x1000);    /* 0x80004000 */
  . = 0x80003000;       /* explicitly placing .handler */
  .handler : { *(.handler) } :handler

  _end = .;
}

