%define syscall_exit    1
%define syscall_read    3
%define syscall_write   4
%define syscall_open    5
%define syscall_close   6

%define O_RDONLY        0
%define O_WRONLY        1
%define O_CREAT         0x40
%define O_TRUNC         0x200

section .data
    input_flag db "-i", 0         ; "-i" flag
    output_flag db "-o", 0        ; "-o" flag
    newline db 10, 0              ; newline character for output
    error_msg db "Error: Invalid argument", 10
    error_len equ $ - error_msg
    char_buffer db 0              ; single character buffer

section .bss
    infile resd 1                 ; input file descriptor
    outfile resd 1                ; output file descriptor

section .text
extern strlen                     ; Externally provided strlen function
global _start                     ; Entry point

_start:
    ; Initialize file descriptors
    mov dword [infile], 0         ; Default to stdin
    mov dword [outfile], 1        ; Default to stdout

    ; Parse command-line arguments
    mov ecx, [esp]                ; argc (argument count)
    lea esi, [esp + 4]            ; argv (pointer to arguments array)

    call parse_args

    ; Perform encoding
    call encode_input

    ; Exit program
    mov eax, syscall_exit
    xor ebx, ebx
    int 0x80

; ------------------------------------------------------
; parse_args: Parses command-line arguments for -i and -o
; ------------------------------------------------------
parse_args:
    mov ecx, [esp]          ; argc (argument count)
    mov esi, [esp + 4]      ; argv (pointer to arguments array)
    add esi, 4              ; Skip program name (argv[0])

    cmp ecx, 1              ; Check if there are arguments
    jle end_parse_args

arg_loop:
    cmp ecx, 1                  ; If all arguments are processed, exit loop
    jle end_parse_args

    mov edi, [esi]              ; Load the current argument pointer (argv[i])
    test edi, edi               ; Ensure the pointer is not NULL
    jz next_arg

    ; Debug: Print the current argument
    mov eax, syscall_write
    mov ebx, 1                  ; stdout
    mov ecx, edi                ; Current argument pointer
    call strlen                 ; Get argument length
    mov edx, eax                ; Argument length
    int 0x80

    ; Validate that the argument starts with '-'
    cmp byte [edi], '-'         
    jne next_arg

    ; Check for input flag "-i"
    cmp dword [edi], '-i'       
    je open_input

    ; Check for output flag "-o"
    cmp dword [edi], '-o'       
    je open_output

next_arg:
    add esi, 4                  ; Move to the next argv entry
    dec ecx                     ; Decrement argument count
    jmp arg_loop


open_input:
    add edi, 2              ; Skip "-i"
    mov eax, syscall_open
    mov ebx, edi            ; File name pointer
    mov ecx, O_RDONLY       ; Open in read-only mode
    int 0x80
    cmp eax, 0              ; Check if open succeeded
    jl error_open
    mov [infile], eax       ; Save input file descriptor
    jmp next_arg

open_output:
    add edi, 2              ; Skip "-o"
    mov eax, syscall_open
    mov ebx, edi            ; File name pointer
    mov ecx, O_WRONLY | O_CREAT | O_TRUNC ; Write-only, create, truncate
    mov edx, 0666           ; Permissions for new file
    int 0x80
    cmp eax, 0
    jl error_open
    mov [outfile], eax      ; Save output file descriptor
    jmp next_arg

error_open:
    mov eax, syscall_write
    mov ebx, 2              ; Write to stderr
    mov ecx, error_msg
    mov edx, error_len
    int 0x80
    mov eax, syscall_exit
    xor ebx, ebx
    int 0x80

end_parse_args:
    ret


; ------------------------------------------------------
; encode_input: Reads characters, encodes, and writes output
; ------------------------------------------------------
encode_input:
    mov ebx, [infile]             ; Input file descriptor
    test ebx, ebx
    jnz read_input
    mov ebx, 0                    ; Default to stdin

read_input:
    mov eax, syscall_read
    mov ecx, char_buffer
    mov edx, 1                    ; Read one character
    int 0x80
    test eax, eax                 ; Check for EOF or error
    jle end_encode

    ; Encode character
    mov al, [char_buffer]
    cmp al, 'A'
    jl write_output               ; Skip encoding if < 'A'
    cmp al, 'z'
    jg write_output               ; Skip encoding if > 'z'
    inc al                        ; Increment character

write_output:
    mov [char_buffer], al
    mov eax, syscall_write
    mov ebx, [outfile]            ; Output file descriptor
    test ebx, ebx
    jnz use_output
    mov ebx, 1                    ; Default to stdout

use_output:
    mov ecx, char_buffer
    mov edx, 1
    int 0x80
    jmp read_input

end_encode:
    ret
