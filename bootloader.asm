; booatloader.asm

[BITS 16]
[ORG 0x7c00]

; as the first part of the bootloader
; we want to disable the A20 signal
; see: https://www.win.tue.nl/~aeb/linux/kbd/A20.html
test_a20:
sub ax, ax  ; make ax = 0
mov ss, ax  ; stack segment register
mov sp, 0x9c00  ; stack pointer
mov es, ax  ; extra segment register

not ax      ; make ax = ffff
mov ds, ax  ; data segment register

mov di, 0x0500  ; addresses to look at
mov si, 0x0510

mov byte [es:di], 0x00  ; now move dummy values to test against
mov byte [ds:si], 0xff

cmp byte [es:di], 0xff  ; check if a20 is enabled
                        ; if enabled zf is 0
jne load_gdt  ; because a20 is set we continue with the bootloading


; we will try to enable a20 now
; we dont use the "order of least risk"
; but instead try the fastest method first
; for more info see: https://wiki.osdev.org/A20_Line


fast_a20:
in al, 0x92
or al, 2
out 0x92, al

jmp test_a20  ; check if a20 was enabled


keyboard_controller_a20:  ; no then try keyboard controller
; first we try the ps/2 controller
mov al, 0xd1   ; write next byte to controller output port
out 0x64, al  ; the ps/2 command register
call empty_8042
mov al, 0xdf  ; set a20 line
out 0x60, al  ; byte to write to data register


empty_8042:     ; from the source mentioned above
in al, 0x64     ; read ps/2 status register
cmp al, 0x02    ; check if system flag is set
jne empty_8042  ; not ready yet
ret

; assume a20 is enabled by now
; else we can still try bios (not done here)

load_gdt:  ; load global descriptor table


times 510-($-$$) db 0
db 0x55
db 0xaa
