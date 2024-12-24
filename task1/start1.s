; Constants for standard file descriptors and system calls
%define STDERR 2
%define STDOUT 1
%define STDIN 0

%define CLOSE 6
%define OPEN 5
%define WRITE 4
%define READ 3
%define EXIT 1

%define EXIT_SUCCESS 0

section .data
    ; Define a newline character and its length
    new_line: db 10, 0      ; Newline character followed by null terminator
    new_line_len EQU 1      ; Length of the newline character

    ; Default file descriptors for input and output
    Infile: dd STDIN        ; Default input is standard input (STDIN)
    Outfile: dd STDOUT      ; Default output is standard output (STDOUT)

section .bss
    ; Allocate a 1-byte buffer for character processing
    buffer: resb 1

section .text
global _start
extern strlen

_start:
    ; Initialize arguments and environment variables
    pop     dword ecx       ; Store argc in ecx
    mov     esi, esp        ; Store argv in esi
    mov     eax, ecx        ; Copy argc to eax
    shl     eax, 2          ; Multiply argc by 4 to get argv size in bytes
    add     eax, esi        ; Add argv size to argv address
    add     eax, 4          ; Skip the null pointer after argv
    push    eax             ; Push envp
    push    esi             ; Push argv
    push    ecx             ; Push argc

    call    main            ; Call the main function

    ; Exit with the return value from main
    mov     ebx, eax
    mov     eax, EXIT       ; Exit system call
    int     0x80

main:
    ; Prolog for the main function
    push    ebp
    mov     ebp, esp
    sub     esp, 4          ; Reserve space for return value
    pushad                  ; Save registers state

    ; Process the command-line arguments
    mov     esi, [ebp+12]   ; Load argv into esi
    add     esi, 4          ; Skip the program name (argv[0])

arg_loop:
    cmp     dword [esi], 0  ; Check if argv[i] is null (end of arguments)
    je      after_args

    mov     ecx, [esi]      ; Load the current argument
    cmp     byte [ecx], '-' ; Check if it starts with a dash (flag)
    jne     print_argument

    ; Handle input file flag (-i)
    inc     ecx
    cmp     byte [ecx], 'i'
    je      set_input_file

    ; Handle output file flag (-o)
    cmp     byte [ecx], 'o'
    je      set_output_file

print_argument:
    ; Print the current argument
    push    [esi]
    call    strlen          ; Get the length of the argument
    add     esp, 4
    mov     edx, eax        ; Set length for write
    mov     ecx, [esi]      ; Set string address for write
    mov     ebx, STDERR     ; Write to standard error
    mov     eax, WRITE      ; System call: write
    int     0x80

    ; Print a newline after the argument
    mov     edx, new_line_len
    mov     ecx, new_line
    mov     ebx, STDERR
    mov     eax, WRITE
    int     0x80

    add     esi, 4          ; Move to the next argument
    jmp     arg_loop

after_args:
    ; Begin encoding loop
encoding_loop:
    mov     edx, 1          ; Read one byte at a time
    mov     ecx, buffer     ; Buffer for reading
    mov     ebx, [Infile]   ; Input file descriptor
    mov     eax, READ       ; System call: read
    int     0x80

    cmp     eax, 0          ; Check for end of file
    je      close_files

    ; Encode the character in buffer
    call    encode_character

    ; Write the encoded character to output
    mov     edx, 1
    mov     ecx, buffer
    mov     ebx, [Outfile]  ; Output file descriptor
    mov     eax, WRITE
    int     0x80

    jmp     encoding_loop

close_files:
    ; Close input file
    mov     eax, CLOSE
    mov     ebx, [Infile]
    int     0x80

    ; Close output file
    mov     eax, CLOSE
    mov     ebx, [Outfile]
    int     0x80

    mov     dword [ebp-4], EXIT_SUCCESS ; Set return value

    ; Epilog for the main function
    popad
    mov     eax, [ebp-4]    ; Return value
    add     esp, 4
    pop     ebp
    ret

set_input_file:
    inc     ecx             ; Move to the file name
    mov     eax, OPEN
    mov     ebx, ecx        ; File name
    mov     ecx, 0          ; Read-only mode
    mov     edx, 0644       ; File permissions
    int     0x80
    mov     [Infile], eax   ; Store file descriptor
    jmp     arg_loop

set_output_file:
    inc     ecx             ; Move to the file name
    mov     eax, OPEN
    mov     ebx, ecx        ; File name
    mov     ecx, 1          ; Write mode
    mov     edx, 0644       ; File permissions
    int     0x80
    mov     [Outfile], eax  ; Store file descriptor
    jmp     arg_loop

encode_character:
    ; Encode alphabetic characters in buffer
    cmp     byte [buffer], 'A'
    jl      end_encode
    cmp     byte [buffer], 'z'
    jg      end_encode
    cmp     byte [buffer], 'Z'
    jle     encode_uppercase
    cmp     byte [buffer], 'a'
    jge     encode_lowercase

end_encode:
    ret

encode_uppercase:
    cmp     byte [buffer], 'Z'
    jne     increment_char
    mov     byte [buffer], 'A'
    jmp     end_encode

encode_lowercase:
    cmp     byte [buffer], 'z'
    jne     increment_char
    mov     byte [buffer], 'a'
    jmp     end_encode

increment_char:
    inc     byte [buffer]
    jmp     end_encode
