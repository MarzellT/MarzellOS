INPUT (
	bootloader.o
	bios_utils.o
	utils.o
	messages.o
)


/* move the start of the output to 0x7c00 */
. = 0x7c00;
SECTIONS {
    .text : {  /* name of the output section is just bootloader */
        bootloader.o(.text)  /* specifying .text is important */
        bios_utils.o(.text)  /* otherwise debug information is lost */
        utils.o
        messages.o
    }
}