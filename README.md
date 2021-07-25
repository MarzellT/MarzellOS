# MarzellOS

x86\_64 operating system for learning purposes.

## Info
Right now the 'Bootloader' only tries to enable A20.
On the hard disk we want to do something different.
When compiling with `make` we create an iso image emulating
a 1440 kB floppy. This enables to use int 13h bios functions.
We want to create a MBR on the hard disk and do MBR bootstrap:
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
qemu-system-x86\_64 -cdrom bin/bootloader.iso -s -S & gdb bin/bootloader.elf \
        -ex 'target remote localhost:1234' \
        -ex 'set architecture i8086'
```
[\(Other possible QEMU parameters)](https://manned.org/qemu-system-x86_64/129d1fa3)    

## Todo
- linker script (not required yet)
- Bootloader
  - check disk type (int 13, ah=15)
  - load into memory
      - use check for extensions
      - check if read was successful
      - make this a function to be called
      - doesn't work for cd/dvd yet
  - enable protected mode
  - prepare the runtime environment
look into <https://wiki.osdev.org/Rolling_Your_Own_Bootloader>

## Learnings
There are differences in bootable .iso files. A problem was that I
using an El Torito image instead of a floppy emulated image.
That's the reasong why the int 13h calls didn't work.
