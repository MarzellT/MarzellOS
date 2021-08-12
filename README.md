# MarzellOS

x86\_64 operating system for learning purposes.

## Info
Right now the 'Bootloader' only tries to enable A20.
On the (emulated) hard disk we want to do something different.
When compiling with `make` we create an iso image emulating
a 1440 kB floppy. This enables to use int 13h bios functions.
We want to create an MBR on the hard disk and do MBR bootstrap:
<https://wiki.osdev.org/MBR_(x86)>
Then the bootloader needs to load the kernel image into the memory.
Only then we enter protected mode and setup runtime environment.


## Compile
To compile simply use `make`.
This creates a binary file which can the be used with QEMU using `-fda`.   
To create an iso use `make bootloader.iso`. This creats an iso file to
be used with QEMU using `-cdrom`.

## QEMU
To run with **QEMU** + **GDB** do:
```shell
qemu-system-i386 -cdrom bin/bootloader.iso -s -S & gdb bin/mbr_loader.elf
-ex 'target remote localhost:1234'
-ex 'set architecture i8086'
-ex 'set tdesc filename src/target.xml'
-ex 'b *0x7c00'
```
[\(Other possible QEMU parameters)](https://manned.org/qemu-system-x86_64/129d1fa3)    

## Todo
### MBR loader
- create a special mbr loader that will be used to load the actual
bootloader into the memory so we don't need to worry about the size
and we can do all the required stuff
- the mbr loader needs to load our bootloader into memory
- we need to check how to put everything onto a file (hard drive)
so that we can chs address it
- maybe add chain loading
### bootloader
- debug int 13, ah=42
- linker script (not required yet)
- Bootloader
  - load into memory
      - use check for extensions
      - check if read was successful
      - make this a function to be called (maybe)
  - enable protected mode
  - prepare the runtime environment
look into <https://wiki.osdev.org/Rolling_Your_Own_Bootloader>

## Learnings
There are differences in bootable .iso files. A problem was that I
using an El Torito image instead of a floppy emulated image.
That's the reason the int 13h calls didn't work.
    
Only the `bx` register can be used as indexing register in real
mode check <https://stackoverflow.com/questions/2809141/invalid-effective-address-calculation>
and also <https://wiki.osdev.org/X86-64_Instruction_Encoding#SIB>.