BIN = ./bin/


all: bootloader.bin bootloader.iso

bootloader.bin: bootloader.asm
	nasm bootloader.asm -f bin -o $(BIN)bootloader.bin

bootloader.iso: bootloader.bin
	rm -rf $(BIN)isocontents
	mkdir $(BIN)isocontents
	cp $(BIN)bootloader.bin $(BIN)isocontents
	mkisofs -no-emul-boot -o $(BIN)bootloader.iso -V MarzellOS -b bootloader.bin $(BIN)isocontents/

clean:
	rm -rf $(BIN)/*
