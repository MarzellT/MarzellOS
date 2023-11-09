; bios_utils.asm
; Collection of functions that interact with the bios in real mode.

global set_text_mode
global clear_screen
global write_string
global int_to_str

[BITS 16]

section .text

set_text_mode:
; set text mode
; 80x25 text 9x16 box 720x400 res 16 colors 8 pages B800 ? VGA
mov al, 0x03  ; text mode
mov ah, 0x00
int 10h
ret


clear_screen:
push ebx  ; callee saved

; Move cursor to top-left corner
mov ah, 0x06
mov al, 0x00
xor bh, bh
mov cx, 0x0000  ; pos 0:0
int 10h

; Overwrite with spaces
mov ah, 0x09  ; write character
mov al, ' '   ; space
mov bl, 0x07 ; White on black
xor cx, cx
mov dx, 0x184f ; Number of spaces to write
int 10h

pop ebx  ; callee saved
ret


write_string:
; arguments:
; pointer to null-terminated string
; pointer to data segment
push ebx  ; callee saved
xor bx, bx
mov bx, sp
mov di, [bx+0x08]  ; second argument
mov si, [bx+0x06]  ; first argument
mov ds, di

; interrupt parameters
mov ah, 0eh     ; int 10h: teletype output
mov bh, 0x00    ; page number = current page
mov bl, 0x00    ; foreground color

write_string_loop:
mov al, [ds:si]  ; current char
cmp al, 0x0   ; check for null termination
jz write_string_done
int 10h;
inc si  ; point to the next char
jmp write_string_loop

write_string_done:
pop ebx  ; callee saved
ret
