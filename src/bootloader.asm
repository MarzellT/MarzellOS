; bootloader.asm
; containing an MBR partition table

[BITS 16]

; as the first part of the bootloader
; we want to disable the A20 signal
; see: https://www.win.tue.nl/~aeb/linux/kbd/A20.html
main:
cli
mov ax, 0x7fff  ; some high available memory
                ; check https://wiki.osdev.org/Memory_Map_(x86)
mov ss, ax  ; stack segment register
mov sp, 0x0  ; stack pointer
test_a20:
sub ax, ax  ; make ax = 0
mov es, ax  ; extra segment register

not ax      ; make ax = ffff
mov ds, ax  ; data segment register

mov di, 0x0500  ; addresses to look at
mov si, 0x0510

mov al, 0x00
mov [es:di], al  ; now move dummy values to test against
mov al, 0xff
mov [ds:si], al

mov al, [es:di]
cmp al, 0xff    ; check if a20 is enabled
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
push dx  ; save drive number to stack
sub ax, ax
mov es, ax
mov di, ax
mov ah, 0x08   ; for int 13 to get drive parameters
int 0x13       ; call the bios function
; check parameters: http://www.ctyme.com/intr/rb-0621.htm#Table242
cmp ah, 0x00   ; is zero on success (currently not used)
mov [test_a20], cx ; save parameters into memory
mov [test_a20+2], dx
; for error codes check: http://www.ctyme.com/intr/rb-0606.htm#Table234
pop dx  ; restore drive number
cmp dx, 0x80   ; check if we use a hard drive
jl read_floppy_setup  ; jump to read the floppy
; else we assume a hard drive


; check for int 13 extensions (only needed for hard drives)
; carry will be set if not present
check_int_13_extensions:
mov ah, 0x41
push dx  ; save drive number
mov bx, 0x55aa
int 0x13
pop dx  ; restore drive number

; read from hard drive
; first we need to create the disk address packet:
; see: http://www.ctyme.com/intr/rb-0708.htm#Table272
read_drive:
sub ax, ax
mov ds, ax
mov si, disk_address_packet
mov ah, 0x42
push dx  ; save drive number
int 0x13
pop dx  ; restore drive number
cmp ax, 0x0  ; check if read was successful (0)
je load_gdt

read_floppy_setup:
mov bp, 4   ; retry at least 5 times
read_floppy:
sub dh, dh  ; head number 0
sub ax, ax
mov es, ax      ; buffer to place data in
mov bx, 0x7e00  ; we want to start right after the bootloader
mov cx, [test_a20]  ; restore values from get drive parameters call
and cl, 0x3f        ; we only take bytes 0-5 and thereby
sub ch, ch          ; make cylinder number to 0
mov ah, 0x02
mov al, cl          ; read max sector count
mov cl, 0x01        ; start from sector 1
push dx  ; save the drive number
int 0x13
pop dx   ; restore the drive number
dec bp       ; decrease max retry counter
or bp, bp  ; bp==0
je load_gdt
or ah, ah
je load_gdt
jmp read_floppy

load_gdt:  ; load global descriptor table

disk_address_packet:
db 0x10  ; size of packet
db 0x00  ; reserved (0)
dw 0x0001 ; number of blocks to transfer
dd 0x00007e00  ; transfer buffer starting after the bootloader memory
dq 0x0000000000000000  ; check if this was source of error

; add the boot signature at the end
times 510-($-$$) db 0
db 0x55
db 0xaa
