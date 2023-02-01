; bios_utils.asm
; Collection of functions that interact with the bios in real mode.

global clear_screen

[BITS 16]

section .text

clear_screen:
mov ax, 0x0003 ; Set text mode
int 0x10  ; ah=00, al=03

mov ax, 0x0600 ; Move cursor to top-left corner
xor bh, bh
mov cx, 0x0000
int 0x10

mov ah, 0x09  ; write character
mov al, ' '   ; space
mov bl, 0x07 ; White on black
xor cx, cx
mov dx, 0x184f ; Number of spaces to write
int 0x10
ret