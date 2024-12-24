all: task2 

task2: main.o start.o Util.o
	ld -m elf_i386 start.o main.o Util.o -o task2

Util.o: Util.c
	gcc -m32 -Wall -ansi -c -nostdlib -fno-stack-protector Util.c -o Util.o

main.o: main.c
	gcc -m32 -Wall -ansi -c -nostdlib -fno-stack-protector main.c -o main.o

start.o: start1.s
	nasm -f elf32 start.s -o start.o

.PHONY: clean

clean:
	rm -f *.o task2