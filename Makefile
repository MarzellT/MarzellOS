BIN = ./bin/
SRC = ./src/
BOOTLOADER_SRC = $(SRC)bootloader/
PARTITION_SIZE = 1  # 1 MB

# Compiler Options
CROSS-COMPILE-TARGET:=x86_64-elf
LD = build-tools/bin/$(CROSS-COMPILE-TARGET)-ld
CC = build-tools/bin/$(CROSS-COMPILE-TARGET)-gcc
CXX = build-tools/bin/$(CROSS-COMPILE-TARGET)-g++



all: bootloader.bin hd_bootloader.iso
cd_loader:
	make cd_loader.bin
	make floppy_cd_loader.iso

cd_loader.bin:
	nasm $(BOOTLOADER_SRC)cd_loader.asm -f bin -o $(BIN)cd_loader.bin

bootloader.bin:
	nasm $(BOOTLOADER_SRC)bootloader.asm -f bin -o $(BIN)bootloader.bin
	nasm $(BOOTLOADER_SRC)mbr_loader.asm -f bin -o $(BIN)mbr_loader.bin

floppy_cd_loader.iso: cd_loader.img
	rm -rf $(BIN)isocontents
	mkdir $(BIN)isocontents
	truncate -s 1474560 $(BIN)cd_loader.img
	cp $(BIN)cd_loader.img $(BIN)isocontents
	mkisofs -o $(BIN)cd_loader.iso -V MarzellOS -b cd_loader.img $(BIN)isocontents/

hd_bootloader.iso: bootloader.img
	# here i tried to create a loop device so that we can use the os to write to the filesystem
	# but we dont actually need it as of now
	#	dd if=/dev/zero of=$(BIN)diskimage.dd bs=1048576 count=$(PARTITION_SIZE)
	#	fdisk $(BIN)diskimage.dd < $(SRC)create_mbr_fdisk.txt
	#	losetup -o 1 --sizelimit 1048576 -f $(BIN)diskimage.dd
	#	$(eval DEVNAME := $(shell losetup -j $(BIN)diskimage.dd | python3 $(SRC)get_losetup_loop_dev.py))
	#	mkfs.vfat -F 12 -n "MarzellOS" $(DEVNAME)
	#	losetup -d $(DEVNAME)
	rm -rf $(BIN)isocontents
	mkdir $(BIN)isocontents
	cp $(BIN)*.img $(BIN)isocontents
	mkisofs -hard-disk-boot -o $(BIN)bootloader.iso -V MarzellOS -b mbr_loader.img $(BIN)isocontents/

bootloader.o:
	nasm -f elf32 -g3 -F dwarf $(BOOTLOADER_SRC)bootloader.asm -o $(BIN)bootloader.o
	nasm -f elf32 -g3 -F dwarf $(BOOTLOADER_SRC)mbr_loader.asm -o $(BIN)mbr_loader.o

cd_loader.o:
	nasm -f elf32 -g3 -F dwarf $(BOOTLAODER_SRC)cd_loader.asm -o $(BIN)cd_loader.o

bootloader.elf: bootloader.o
	$(LD) -Ttext=0x7c00 -melf_i386 $(BIN)bootloader.o -o $(BIN)bootloader.elf
	$(LD) -T $(BOOTLOADER_SRC)mbr_loader.ld -melf_i386 $(BIN)mbr_loader.o -o $(BIN)mbr_loader.elf

cd_loader.elf: cd_loader.o
	$(LD) -Ttext=0x7c00 -melf_i386 $(BIN)cd_loader.o -o $(BIN)cd_loader.elf

bootloader.img: bootloader.elf
	objcopy -O binary $(BIN)bootloader.elf $(BIN)bootloader.img
	objcopy -O binary $(BIN)mbr_loader.elf $(BIN)mbr_loader.img
	cat $(BIN)bootloader.img >> $(BIN)mbr_loader.img

cd_loader.img: cd_loader.elf
	objcopy -O binary $(BIN)cd_loader.elf $(BIN)cd_loader.img

clean:
	rm -rf $(BIN)*
