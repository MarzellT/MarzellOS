BIN = ./bin/
SRC = ./src


all: bootloader.bin bootloader.iso

bootloader.bin: bootloader.asm
	nasm $(SRC)bootloader.asm -f bin -o $(BIN)bootloader.bin

bootloader.iso: bootloader.bin
	rm -rf $(BIN)isocontents
	mkdir $(BIN)isocontents
	truncate -s 1474560 $(BIN)bootloader.bin
	cp $(BIN)bootloader.bin README.md $(BIN)isocontents
	mkisofs -o $(BIN)bootloader.iso -V MarzellOS -b bootloader.bin $(BIN)isocontents/

bootloader.o: bootloader.asm
	nasm -f elf64 -g -F dwarf $(SRC)bootloader.asm -o $(BIN)bootloader.o

bootloader.elf: bootloader.o
	ld -Ttext=0x7c00 -melf_x86_64 $(BIN)bootloader.o -o $(BIN)bootloader.elf
	objcopy -O binary $(BIN)bootloader.elf $(BIN)bootloader.img

clean:
	rm -rf $(BIN)*
