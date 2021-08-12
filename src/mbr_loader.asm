; mbr_loader.asm
; contains an MBR partition table and load
; the first bootable partition

[BITS 16]

; define MBR data structures for ease of use
struc mbr_partition_entry
status:            resb 1
chs_first_sector:  resb 3
partition_type:    resb 1
chs_last_sector:   resb 3
lba_first_sector:  resb 4
number_of_sectors: resb 4
endstruc


section .before_relocate
mbr_loader_main:  ; entry point
cli  ; we dont want any maskable interrupts

; setup the stack
mov ax, 0x7c0  ; stack address just before the bootloader code
mov ss, ax     ; set the stack segment register to this value
mov sp, 0x0
push dx  ; save the boot drive number

; relocate ourself to 0x500
; we use the rep movs instruction to do so
; so we need to load the registers cx, ds:si, and es:di
mov cx, 0x100  ; 0x100 words to move (512 bytes)
mov ax, 0x7c0  ; relocate from 0x7c00
mov ds, ax
sub si, si
mov ax, 0x50   ; relocate to 0x500
mov es, ax
sub di, di
rep movsw
jmp (0x500+check_partitions-0x7c00)

section .after_relocate
check_partitions:
; now we will load the first sector of the first active partition to 0x7c00
mov di, 446  ; offset to the first entry
mov cx, -0x4
check_partitions_loop:
mov al, [es:di]
cmp al, 0x80  ; check the status bit of the partition entry
je load_partition  ; valid partition found
; not tested \/
inc cx
cmp cx, 0
je no_valid_entry_found
add di, 0x10  ; check the next entry
jmp check_partitions_loop
; not tested /\

load_partition:  ; we have a valid partition we need to load it now
                 ; for this we will use int 13/ah=42 extended read
                 ; check: http://www.ctyme.com/intr/rb-0708.htm
pop dx
push dx
mov ah, 0x41
mov bx, 0x55aa
int 0x13
pop dx   ; restore the boot drive number
push dx  ; we cant do mov dx, [sp] in real mode
sub ax, ax  ; make ds = 0
mov ds, ax  ; the segment of the disk address packet
mov ax, [di+0x8+0x500]
;mov si, (dap_start_sector+0x4)  ; we need to enter this in the middle
;                              ; of the quadword (compare with int 13/ah=42 doc)
;mov [si], ax
;mov ax, [di+0xc+0x500]
;mov si, dap_number_of_sectors
;mov [si], ax
mov si, disk_address_packet
mov ah, 0x42
int 0x13
pop dx  ; restore the drive number for the next loader
jmp 0x7c00


no_valid_entry_found:
jmp no_valid_entry_found


disk_address_packet:
db 0x10  ; size of packet
db 0x0   ; reserved (0)
dap_number_of_sectors:
dw 0x1  ; rewrite this
dd 0x00007e00  ; write to this address
dap_start_sector:
dq 0x0  ; rewrite this



times 440-($-$$)-32 db 0  ; there is some issue here the -32 shouldn't be necessary
; mbr partition table (check https://wiki.osdev.org/MBR)
mbr_unique_id:
dd 0x1337
mbr_reserved:
dw 0x0
mbr_first_pt_entry: istruc mbr_partition_entry
at status, db 0x80  ; set 7th bit to set it bootable (active)
; we make the first partition start at 0/1/1 chs
; compare to https://www.thomas-krenn.com/en/wiki/CHS_and_LBA_Hard_Disk_Addresses
at chs_first_sector, db 0x1 ,0x1 ,0x0

; check https://en.wikipedia.org/wiki/Partition_type
at partition_type, db 0x01  ; db 0x0c  fat32 with lba

at chs_last_sector, db 0x1 ,0x2 ,0x0
at lba_first_sector, dd 0x3f
at number_of_sectors, dd 0x2
iend

times 16*3 db 0x0  ; fill the remaining 3 boot sectors with 0s
db 0x55  ; add the boot signature
db 0xaa
