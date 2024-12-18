.SILENT: link compile_main compile_util assemble clean run
.PHONY: all link compile_main compile_util assemble clean run

all: clean compile_util compile_main assemble link

compile_util:
	# Compile Util.c to util.o
	gcc -m32 -Wall -nostdlib -fno-stack-protector -c ../Util.c -o util.o

compile_main:
	# Compile main.c to main.o
	gcc -m32 -Wall -nostdlib -fno-stack-protector -c main.c -o main.o

assemble:
	# Assemble start.s into start.o
	nasm -f elf32 start.s -o start.o

link:
	# Link main.o, start.o, and util.o into final executable
	gcc -m32 -nostdlib -o task2 main.o start.o util.o

clean:
	# Clean up generated files
	rm -f *.o task2

run:
	# Run the task2 executable
	./task2
