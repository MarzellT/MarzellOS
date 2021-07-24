bootloader.bin: bootloader.asm
	nasm bootloader.asm -f bin -o bootloader.bin
clean:
	rm -f bootloader.bin
