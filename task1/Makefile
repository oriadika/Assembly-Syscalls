all: task1 

task1: start.o util.o
	ld -m elf_i386 start.o util.o -o task1

util.o: Util.c
	gcc -m32 -Wall -g -ansi -c -nostdlib -fno-stack-protector Util.c -o util.o

start.o: start.s
	nasm -f elf32 start.s -o start.o

.PHONY: clean

clean:
	rm -f *.o task1