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
    new_line: db 10, 0      ; Newline character followed by null terminator
    new_line_len EQU 1      ; Length of the newline character
    Infile: dd STDIN        ; Default input is standard input (STDIN)
    Outfile: dd STDOUT      ; Default output is standard output (STDOUT)

section .bss
    buffer: resb 1          ; 1-byte buffer for reading and processing characters

section .text
global _start
extern strlen

_start:
    ; Process arguments and environment pointers
    pop     dword ecx    ; ecx = argc
    mov     esi, esp     ; esi = argv
    mov     eax, ecx     ; copy argc to eax
    shl     eax, 2       ; multiply argc by 4 to get the size of argv in bytes

    add     eax, esi     ; add the size of argv to the argv address
    add     eax, 4       ; skip the null pointer after argv
    push    dword eax    ; char *envp[]
    push    dword esi    ; char* argv[]
    push    dword ecx    ; int argc

    call    main         ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx, eax
    mov     eax, EXIT
    int     0x80
    nop
        
main:
    ; Prolog
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for return value on stack
    pushad                  ; Save some more caller state


    ; Copy and set "variables"
    mov     esi, [ebp+12]   ; esi = argv
    add     esi, 4          ; esi = argv[1]

    ;;;;;;;;;;;;;;; Debug mode start ;;;;;;;;;;;;;;;
start_debug_loop:
    cmp     dword [esi], 0
    je     end_debug_loop

    ; Check for flags
    mov     ecx, dword [esi]
    cmp     byte [ecx], '-'
    jne     start_print
    inc     ecx
    cmp     byte [ecx], 'i' 
    je      change_infile
    cmp     byte [ecx], 'o' 
    je      change_outfile
start_print:
    call    print_arg

    ; Update variable
    add     esi, 4
end_debug_loop:
    cmp     dword [esi], 0
    jne     start_debug_loop
    ;;;;;;;;;;;;;;; Debug mode end ;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;; Encoder start ;;;;;;;;;;;;;;;
start_encode_loop:
    ; Read the char from infile
    mov     edx, 1
    mov     ecx, buffer
    mov     ebx, [Infile]
    mov     eax, READ
    int     0x80

    cmp     eax, 0
    je      end_encode_loop

    call    encode

    ; Print the encoded char
    mov     edx, 1
    mov     ecx, buffer
    mov     ebx, [Outfile]
    mov     eax, WRITE
    int     0x80

end_encode_loop:
    cmp     eax, 0
    jne      start_encode_loop
    ;;;;;;;;;;;;;;; Encoder end ;;;;;;;;;;;;;;;

    mov     eax, CLOSE
    mov     ebx, [Infile]
    int     0x80

    mov     eax, CLOSE
    mov     ebx, [Outfile]
    int     0x80


    mov     dword [ebp-4], EXIT_SUCCESS    ; Save returned value...

    ; Epilog
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

print_arg:
    push    dword [esi]
    call    strlen
    add     esp, 4
    mov     edx, eax
    mov     ecx, dword [esi]
    mov     ebx, STDERR
    mov     eax, WRITE
    int     0x80

    mov     edx, new_line_len
    mov     ecx, new_line
    mov     ebx, STDERR
    mov     eax, WRITE
    int     0x80
    ret

encode:
    cmp     dword [ecx], 'A'
    jl      end_encode
    cmp     dword [ecx], 'z'
    jg      end_encode
    cmp     dword [ecx], 'Z'
    jle     encode_capital
    cmp     dword [ecx], 'a'
    jge     encode_lower

end_encode:
    ret
    
encode_capital:
    cmp     dword [ecx], 'Z'
    je      put_A
    inc     dword [ecx]
    jmp     end_encode

put_A:
    mov     dword [ecx], 'A'
    jmp     end_encode

encode_lower:
    cmp     dword [ecx], 'z'
    je      put_a
    inc     dword [ecx]
    jmp     end_encode

put_a:
    mov     dword [ecx], 'a'
    jmp     end_encode

change_infile:
    inc     ecx
    mov     eax, OPEN
    mov     ebx, ecx
    mov     ecx, 0
    mov     edx, 0644
    int     0x80
    mov     [Infile], eax

    jmp     start_print

change_outfile:
    inc     ecx
    mov     eax, OPEN
    mov     ebx, ecx
    mov     ecx, 1
    mov     edx, 0644
    int     0x80
    mov     [Outfile], eax

    jmp     start_print