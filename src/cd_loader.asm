; cd_load.asm
; check all usb drives for boot magic
; and check if they emulate a hard drive to boot from
; load the first (maybe add some logic to give the user a selection)

[BITS 16]

global _start
_start:
; we don't care about A20 here because we will not use more than 1M of RAM
; but we still need to setup the stack
cli  ; clear interrupts
mov ax, 0x7fff  ; some high available memory
                ; check https://wiki.osdev.org/Memory_Map_(x86)
mov ss, ax  ; stack segment register
mov sp, 0x0  ; stack pointer

; now set the data segment register to 0
mov ds, sp  ; stack pointer is 0 at this point


; we use pci to access usb controller
; use bios to check pci configuration space access mechanism
; https://wiki.osdev.org/PCI#Detecting_Configuration_Space_Access_Mechanism.2Fs
mov ax, 0xb101
xor di, di
int 0x1a

after_int:
nop
nop
nop

; add the boot signature at the end
times 510-($-$$) db 0
db 0x55
db 0xaa