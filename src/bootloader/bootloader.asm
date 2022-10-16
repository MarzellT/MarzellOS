; bootloader.asm
; containing an MBR partition table

[BITS 16]

; we want to disable the A20 signal
; as the first part of the bootloader
; see: https://www.win.tue.nl/~aeb/linux/kbd/A20.html
main:
cli
mov ax, 0x0     ; make stack just below the bootloader
                ; check https://wiki.osdev.org/Memory_Map_(x86)
mov ss, ax      ; stack segment register
mov sp, 0x7c00  ; stack pointer

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
jne detect_low_memory  ; because a20 is set we continue with the bootloading


; we will try to enable a20 now
; we dont use the "order of least risk"
; but instead try the fastest method first
; for more info see: https://wiki.osdev.org/A20_Line


fast_a20:
in al, 0x92
or al, 2
out 0x92, al

jmp test_a20  ; check if a20 was enabled


; TODO: check if this is actually reachable and not an infinite loop
keyboard_controller_a20:  ; no then try keyboard controller
; first we try the ps/2 controller
mov al, 0xd1   ; write next byte to controller output port
out 0x64, al  ; the ps/2 command register
call empty_8042
mov al, 0xdf  ; set a20 line
out 0x60, al  ; byte to write to data register
jmp detect_low_memory  ; assume a20 is enabled by now
                       ; else we can still try bios (not done here)

; help function to wait for the ps/2 controller
empty_8042:     ; from the source mentioned above
in al, 0x64     ; read ps/2 status register
cmp al, 0x02    ; check if system flag is set
jne empty_8042  ; not ready yet
ret

; first make sure what memory we can use
detect_low_memory:  ; probably not needed but hey
clc  ; clear carry flag

xor ax, ax
int 0x12  ; returns memory size in ax until 0x080000 (ebda start)  TODO: check this

jc hang  ; shouldn't happen


; now we want to load some data into that memory from boot device
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
cmp dx, 0x80   ; check if we use a hard drive  TODO: this is very hacky check for better solution
               ; maybe take result of ah and if it's zero it's a hdd (but this ist just a theory)
jl read_floppy_setup  ; jump to read the floppy

;                               ||
; else we assume a hard drive   |
;                              \/


; check for int 13 extensions (only needed for hard drives)
; carry will be set if not present
check_int_13_extensions:
mov ah, 0x41
push dx  ; save drive number
mov bx, 0x55aa
int 0x13
pop dx  ; restore drive number
jc read_floppy  ; extensions not installed


; get the drive parameters
get_drive_parameters_extension:
push dx  ; save drive number
xor ax, ax  ; buffer for drive parameters
mov ds, ax
mov si, drive_parameters_extension_buffer + 0x7c00  ; TODO: hacky, chceck if this can be improved on
mov ah, 0x48
int 0x13
pop dx


; read from hard drive
; first we need to create the disk address packet:
; see: http://www.ctyme.com/intr/rb-0708.htm#Table272
read_drive:
xor ax, ax  ; buffer to read to
mov ds, ax
mov ax, [drive_parameters_extension_number_of_sectors_total + 0x7c00]  ; we read the number of sectors we have
                                                                       ; so read them all
sub ax, 0x1  ; we don't want to read the first since it's loaded already
mov [disk_address_packet + 0x2 + 0x7c00], ax  ; move that value to the appropriate memory location
mov si, disk_address_packet + 0x7c00  ; hacky way to get correct address TODO: check if this can be done better
mov ah, 0x42
push dx  ; save drive number
int 0x13
pop dx  ; restore drive number
jnc detect_high_memory  ; carry flag is not set if no error
jc hang  ; some error


read_floppy:
read_floppy_setup:
mov bp, 4   ; retry at least 5 times
read_floppy_main:
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
je detect_high_memory
or ah, ah    ; why these
je detect_high_memory  ; two here?
jmp read_floppy_main

hang:
jmp hang  ; some error

detect_high_memory:
jmp hang  ; TODO: implement

disk_address_packet:
db 0x10  ; size of packet
db 0x00  ; reserved (0)
dw 0x0000 ; number of blocks to transfer
dd 0x00007e00  ; transfer buffer starting after the bootloader memory
dq 0x0000000000000001  ; don't read the first block

drive_parameters_extension_buffer:
drive_parameters_extension_buffer_size:
dw 0x0042  ; size of buffer  (42h for v3.0 (better save than sorry)) (not sure if needed to specify TODO: check without)
drive_parameters_extension_information_flags:
dw 0x0  ; information flags (http://www.ctyme.com/intr/rb-0715.htm#table274)
drive_parameters_extension_number_of_cylinders:
dd 0x0  ; number of physical cylinders
drive_parameters_extension_number_of_heads:
dd 0x0  ; number of heads
drive_parameters_extension_number_of_sectors:
dd 0x0  ; number of sectors
drive_parameters_extension_number_of_sectors_total:
dq 0x0  ; total number of sectors
drive_parameters_extension_bytes_per_sector:
dw 0x0  ; bytes per sector
times 28 db 0x0 ; buffer for the rest

; add the boot signature at the end
times 510-($-$$) db 0
db 0x55
db 0xaa

; test to see if disk can be read
db 0xfe
db 0xaf
