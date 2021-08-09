BIN = ./bin/
SRC = ./src/
PARTITION_SIZE = 1  # 1 MB


all: bootloader.bin hd_bootloader.iso

bootloader.bin:
	nasm $(SRC)bootloader.asm -f bin -o $(BIN)bootloader.bin

floppy_bootloader.iso: bootloader.elf
	rm -rf $(BIN)isocontents
	mkdir $(BIN)isocontents
	truncate -s 1474560 $(BIN)bootloader.img
	cp $(BIN)bootloader.img $(BIN)isocontents
	mkisofs -o $(BIN)bootloader.iso -V MarzellOS -b bootloader.img $(BIN)isocontents/

hd_bootloader.iso: bootloader.elf
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
	cp $(BIN)bootloader.img $(BIN)isocontents
	mkisofs -hard-disk-boot -o $(BIN)bootloader.iso -V MarzellOS -b bootloader.img $(BIN)isocontents/

bootloader.o:
	nasm -f elf32 -g3 -F dwarf $(SRC)bootloader.asm -o $(BIN)bootloader.o

bootloader.elf: bootloader.o
	ld -Ttext=0x7c00 -melf_i386 $(BIN)bootloader.o -o $(BIN)bootloader.elf
	objcopy -O binary $(BIN)bootloader.elf $(BIN)bootloader.img

clean:
	rm -rf $(BIN)*
