.SILENT: link assemble compile_util clean run
.PHONY: all link assemble compile_util clean run

all: clean assemble compile_util link

compile_util:
	# Correct path for Util.c
	gcc -m32 -Wall -nostdlib -fno-stack-protector -g -c ./Util.c -o util.o

assemble:
	# Assemble start.s into start.o
	nasm -f elf32 -g -F dwarf start.s -o start.o

link:
	# Link start.o and util.o into final executable
	ld -m elf_i386 -o task1 start.o util.o

clean:
	# Clean up generated files
	rm -f *.o task1

run:
	# Run the task1 executable
	./task1
