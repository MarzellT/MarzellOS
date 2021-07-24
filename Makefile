bootloader.bin: bootloader.asm
	nasm bootloader.asm -f bin -o bootloader.bin
bootloader.iso: bootloader.bin
	mkdir cdcontents
	cp bootloader.bin cdcontents
	mkisofs -no-emul-boot -o bootloader.iso -V MarzellOS -b bootloader.bin cdcontents/
clean:
	rm -f bootloader.bin
