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

struc mbr_struc
code:              resb 446
partition_entry_1: resb 16
partition_entry_2: resb 16
partition_entry_3: resb 16
partition_entry_4: resb 16
boot_signature:    resb 2
endstruc

mbr_loader_main:  ; entry point
cli  ; we dont want any maskable interrupts
mov [mbr_loader_main], dx  ; save the boot drive number

; setup the stack
mov ax, 0x7c0  ; stack address just before the bootloader code
mov ss, ax     ; set the stack segment register to this value
mov sp, 0x0

;;;;;;;;;; maybe remove this later ;;;;;;;;;;
; relocate ourself to 0x500
; we use the rep movs instruction to do so
; so we need to load the registers cx, ds:si, and es:di
mov cx, 0x100  ; 0x100 words to move (512 bytes)
mov ds, 0x7c0  ; relocate from 0x7c00
sub si, si
mov es, 0x50   ; relocate to 0x500
sub di, di
rep movsw
jmp (0x500+check_partitions-0x7c00)
;;;;;;;;;; maybe remove this later ;;;;;;;;;;

check_partitions:
; now we will load the first sector of the first active partition to 0x7c00
mov ax, ($$+446)
mov cx, -0x4
check_partitions_loop:
mov bx, [ax]
and bx, 0x80
jne load_partition  ; valid partition found
inc cx
cmp cx, 0
je no_valid_entry_found
add ax, 0x10  ; check the next entry
jmp check_partitions_loop

load_partition:  ; we have a valid partition we need to load it now
                 ; for this we will use int 13/ah=42 extended read
                 ; check: http://www.ctyme.com/intr/rb-0708.htm
mov di, [mbr_loader_main]  ; restore the boot drive number
mov ds, 0x50  ; the segment of the disk address packet
mov si, disk_address_packet
mov [start_sector], (ax+mbr_partition_entry.lba_first_sector)
mov [number_of_sectors], (ax+mbr_partition_entry.number_of_sectors)
mov ah, 0x42
int 13
mov di, [mbr_loader_main]
jmp 0x7c00
disk_address_packet:
db 0x10  ; size of packet
db 0x0   ; reserved (0)
number_of_sectors:
dw 0x0  ; rewrite this
dd 0x00007c00  ; write to this address
start_sector:
dq 0x0  ; rewrite this



times 440-($-$$) db 0
; mbr partition table (check https://wiki.osdev.org/MBR)
mbr_unique_id:
dd 0x1337
mbr_reserved:
dw 0x0
mbr_first_pt_entry: istruc mbr_partition_entry
at status, db 0x80  ; set 7th bit to set it bootable (active)
at chs_first_sector, ; we make the first partition start at 0/1/1 chs
                     ; compare to https://www.thomas-krenn.com/en/wiki/CHS_and_LBA_Hard_Disk_Addresses
db 0x1  ; head 7-0
db 0x1  ; cylinder 9-8, sector 5-0
db 0x0  ; cylinder 7-0

at partition_type,  ; check https://en.wikipedia.org/wiki/Partition_type
;db 0x0c  ; fat32 with lba
db 0x01

at chs_last_sector,
db 0x1
db 0x2
db 0x0

at lba_first_sector,
dd 0x3f
at number_of_sectors,
dd 0x2

times 16*3 db 0x0  ; fill the remaining 3 boot sectors with 0s
db 0x55  ; add the boot signature
db 0xaa