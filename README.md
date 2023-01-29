# MarzellOS

**x86\_64 bootloader and operating system for learning purposes.**

---

## Info
Right now the 'Bootloader' only tries to enable A20.
On the (emulated) hard disk we want to do something different.
When compiling with `make` we create an iso image emulating
a 1440 kB floppy. This enables to use int 13h bios functions.
We want to create an MBR on the hard disk and do MBR bootstrap:
<https://wiki.osdev.org/MBR_(x86)>
Then the bootloader needs to load the kernel image into the memory.
Only then we enter protected mode and setup runtime environment.

---

## Compile
To compile simply use `make`.
This creates a binary file which can the be used with QEMU using `-fda` for floppy or
`-hda` for a hard drive.   
To create an iso use `make bootloader.iso`. This creates an iso file to
be used with QEMU using `-cdrom`.

## QEMU
To run with **QEMU** + **GDB** do:
```shell
qemu-system-i386 -cdrom bin/bootloader.iso -s -S & gdb bin/mbr_loader.elf \
-ex 'target remote localhost:1234' \
-ex 'set architecture i8086' \
-ex 'set tdesc filename src/tools/qemu/target.xml' \
-ex 'b *0x7c00'
```
or USB controller emulator (xhci)
```shell
emu-system-i386 -cdrom bin/cd_loader.iso -s -S -device qemu-xhci & gdb bin/cd_loader.elf \
-ex 'target remote localhost:1234' \
-ex 'set architecture i8086' \
-ex 'set tdesc filename src/tools/qemu/target.xml' \
-ex 'b *0x7c00'
```
or directly into TUI
```shell
qemu-system-i386 -hda bin/bootloader.img -s -S & gdbtui ./bin/bootloader.elf  \
-ex 'target remote localhost:1234' \
-ex 'set architecture i8086' \
-ex 'set tdesc filename src/tools/qemu/target.xml' \
-ex 'b *0x7c00' \
-ex 'layout src' \
-ex 'layout regs'
```
[\(Other possible QEMU parameters)](https://manned.org/qemu-system-x86_64/129d1fa3)    

## Current Development Status
- `bootloader.asm` sets a20 and will be used to load the actual kernel.
- `mbr_load.asm` loads `bootloader.asm` into memory. It relocates itself to 0x500.
- `cd_loader.asm` is meant to allow devices that can't boot from USB to boot from CD and boot a USB.

## Bootstrap
### Boot loading
- if booted from hard drive load kernel stuff
- if booted from cd / usb / whatever show installer

---

## CD USB MBR loader  (!forget this for now!)
### Idea
Make the CD loader read a USB and write the contents to the hard drive for testing.
### We will later have to test if this actually needed on the real hardware
- make a cd to load HDD MBR formated USB sticks this way the bootloader
can be compatible with any pc that can boot from floppy drives but not
USB sticks
- should check all USB drives for magic boot bits

---
 
## MBR loader
- create a special mbr loader that will be used to load the actual
bootloader into the memory so we don't need to worry about the size
and we can do all the required stuff
- the mbr loader needs to load our bootloader into memory (only first 512 bytes)
- we need to check how to put everything onto the hard drive
so that we can chs address it *- what did I mean by this ?*
- maybe add chain loading *- I forgot why this should be necessary here?*

---

## Bootloader
This one should be saved onto the hard disk together with the mbr loader
and be able to boot itself

#### Purpose
- load yourself into memory
  - use check for extensions (hdd read bios interrupt)
  - check if read was successful
- detect memory and hardware
- enable protected mode
- prepare the runtime environment
  look into <https://wiki.osdev.org/Rolling_Your_Own_Bootloader>

#### System Discovery
 
##### Memory Detection
###### Low Memory
- use int 0x12 (https://wiki.osdev.org/Detecting_Memory_(x86)#Detecting_Low_Memory)
###### High Memory
- use int 0x15 ax=E820
- store results at 0x500

##### Extended Bios Data Area (EBDA)
1. [(ebda)](https://uefi.org/sites/default/files/resources/ACPI_Spec_6_4_Jan22.pdf#subsubsection.5.2.5.1)
   - location is stored at address 0x40e
2. Read ACPI tables
   - [detect Root System Description Pointer](https://wiki.osdev.org/RSDP#Detecting_the_RSDP)
    which points to the Root System Description Table and potentionally eXtended System Description Table (XSDT)
   - (check on [ACPICA](https://wiki.osdev.org/ACPICA))
 
##### System Management BIOS (SMBIOS)
https://wiki.osdev.org/SMBIOS

1. Locate SMBIOS Entry Point Table
   1. Search through addresses 0xF0000 - 0xFFFFF on 16 bit boundaries for the String "\_SM\_"
   2. Check checksum
2. Parse the table
 
#### General TODOs
- detect hardware
- linker script (not required yet)
- make check for extensions a function to be called (maybe)
- check elf dynamic section and relocation (http://stffrdhrn.github.io/hardware/embedded/openrisc/2019/11/29/relocs.html)

---

## Learnings
There are differences in bootable .iso files. A problem was that I
using an El Torito image instead of a floppy emulated image.
That's the reason the int 13h calls didn't work.
    
Only the `bx` register can be used as indexing register in real
mode check <https://stackoverflow.com/questions/2809141/invalid-effective-address-calculation>
and also <https://wiki.osdev.org/X86-64_Instruction_Encoding#SIB>.

`mov [reg16], something` will always(?) translate to `[mov] [ds:reg16], something`.

Debugging 16 Bit real mode with gdb: <https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr>

Hard drive emulated cdrom boot can't use `int 0x13` extensions.

"All of the 32-bit registers (EAX, ...) are still usable, by simply adding the "Operand Size Override Prefix" (0x66) 
to the beginning of any instruction. Your assembler is likely to do this for you, if you simply try to use a 32-bit 
register." https://wiki.osdev.org/Real_Mode#Common_Misconception

[Enhanced Disk Drive services (EDD)](https://lwn.net/Articles/12544/)

## Trivia
[The Gang of Nine](https://en.wikipedia.org/wiki/Extended_Industry_Standard_Architecture#The_Gang_of_Nine)   

http://uruk.org/   (GRUB inventor and high memory detection tutorial)   
Detecting Memory relies heavily on standardized bios. For older systems it can be super tricky. (https://wiki.osdev.org/Detecting_Memory_(x86))   

[int 12h ax=4350h/bx=4920h CPI-standard virus - Friend Check](http://www.ctyme.com/intr/rb-0603.htm)   

multiple ways to zero a register  
`xor reg, reg`  is the best way to 0 a register.   
On 64 bit machines do `xor r32, r32` as it saves a byte and will clear the upper 32 bit.
