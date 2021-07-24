; booatloader.asm

[BITS 16]
[ORG 0x7c00]

; as the first part of the bootloader
; we want to disable the A20 signal
; see: https://www.win.tue.nl/~aeb/linux/kbd/A20.html
test_a20:
mov ax, 0x0fff  ; some high memory
mov ss, ax  ; stack segment register
mov sp, 0xfffe  ; stack pointer
sub ax, ax  ; make ax = 0
mov es, ax  ; extra segment register

not ax      ; make ax = ffff
mov ds, ax  ; data segment register

mov di, 0x0500  ; addresses to look at
mov si, 0x0510

mov byte [es:di], 0x00  ; now move dummy values to test against
mov byte [ds:si], 0xff

cmp byte [es:di], 0xff    ; check if a20 is enabled
                          ; if enabled zf is 0
jne get_drive_parameters  ; because a20 is set we continue with the bootloading


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
jmp get_drive_parameters  ; assume a20 is enabled by now
                          ; else we can still try bios (not done here)

; help function to wait for the ps/2 controller
empty_8042:     ; from the source mentioned above
in al, 0x64     ; read ps/2 status register
cmp al, 0x02    ; check if system flag is set
jne empty_8042  ; not ready yet
ret

; now we want to load some data into memory from boot device
; boot device is stored in dl register (we must ensure that
; it hasn't been changed yet)
; with the bios int 13h ah=08h we can get the drive parameters
; this will be stored in registers for the register pls look at:
; http://www.ctyme.com/intr/rb-0621.htm
get_drive_parameters:
push es  ; save these registers
push di  ; for after the bios call
sub ax, ax
mov es, ax
mov di, ax
push dx  ; save the drive number
mov ah, 0x08   ; for int 13 to get drive parameters
               ; and then add 200h to the offset (512 bytes)
int 0x13       ; call the bios function
cmp ah, 0x00   ; is zero on success
je load_gdt    ; skip the stack push for the error (maybe change this later)
push ax        ; for error codes check: http://www.ctyme.com/intr/rb-0606.htm#Table234

load_gdt:  ; load global descriptor table
pop dx  ; restore drive number
pop di  ; restore theses registers
pop es  ; after bios call

; check for int 13 extensions
; carry will be set if not present
check_int_13_extensions:
mov ah, 0x41
push dx
mov bx, 0x55aa
int 0x13
pop dx

; test to see if int 13 ah=42 works
; first we need to create the disk address packet:
; see: http://www.ctyme.com/intr/rb-0708.htm#Table272
mov cx, 5
read_drive:
sub ax, ax
mov ds, ax
mov si, disk_address_packet
mov ah, 0x42
int 0x13
cmp ax, 0x0  ; check if read was successful (0)
dec cx
or cx, cx  ; cx==0
jne read_drive
disk_address_packet:
db 0x10  ; size of packet
db 0x00  ; reserved (0)
dw 0x0001 ; number of blocks to transfer
dd 0x00008000  ; transfer buffer starting after the bootloader memory
dq 0x0000000000000000  ; check if this was source of error
times 510-($-$$) db 0
db 0x55
db 0xaa
