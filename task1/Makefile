all: task1 

task1: start.o Util.o
	ld -m elf_i386 start.o Util.o -o task1

Util.o: Util.c
	gcc -m32 -Wall -g -ansi -c -nostdlib -fno-stack-protector Util.c -o Util.o

start.o: start1.s
	nasm -f elf32 start1.s -o start.o

.PHONY: clean

clean:
	rm -f *.o task1