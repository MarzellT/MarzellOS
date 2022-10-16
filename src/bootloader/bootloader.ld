/* no input files,
    they are provided by the makefile */


/* output format
    (can be overridden on command line).
    Don't do this for now
OUTPUT_FORMAT("coff-sh")
    */

/* our program’s entry point
ENTRY(_start)

/* list of our memory sections */
MEMORY
{
vect : o = 0, l = 1k
bda (rx) : o = 0x400, l = 256
ram (wx) : o = 0x500, l = 510k
}

/* how we’re organizing memory sections
    defined in each module */
SECTIONS
{
/* the interrupt vector table */
.vect :
{
__vect_start = .;
*(.vect);
__vect_end = .;
} > vect

/* code and constants */
.text :
{
__text_start = .;
*(.text)
*(.strings)
__text_end = .;
} > rom
/* uninitialized data */
.bss :
{
__bss_start = . ;
*(.bss)
*(COMMON)
__bss_end = . ;
} > ram

/* initialized data */
.init : AT (__text_end)
{
__data_start = .;
*(.data)
__data_end = .;
} > ram
/* application stack */
.stack :
{
__stack_start = .;
*(.stack)
__stack_end = .;
} > ram
}