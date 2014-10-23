x86rc4: x86rc4.s test.c
	gcc -m32 -c test.c -o test.o
	gcc -m32 -c x86rc4.s -o x86rc4.o
	gcc -m32 x86rc4.o test.o -o x86rc4
	objcopy -O binary x86rc4.o x86rc4.bin
	# ld -melf_i386 x86rc4.o test.o -o x86rc4
