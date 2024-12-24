WRITE EQU 4
OPEN EQU 5
CLOSE EQU 6
STDOUT EQU 1

section .data
    msg: db "Hello, Infected File", 10, 0
    msg_len EQU $-msg

section .text
global _start
global system_call
global infector
extern main
extern strlen

_start:
    pop    dword ecx
    mov    esi,esp
    mov    eax,ecx
    shl    eax,2
    add    eax,esi
    add    eax,4
    push   dword eax
    push   dword esi
    push   dword ecx

    call   main

    mov    ebx,eax
    mov    eax,1
    int    0x80
    nop

system_call:
    push   ebp
    mov    ebp, esp
    sub    esp, 4
    pushad                  ; Save all general-purpose registers

    mov    eax, [ebp+8]     ; Load system call number into eax
    mov    ebx, [ebp+12]    ; Load first argument into ebx
    mov    ecx, [ebp+16]    ; Load second argument into ecx
    mov    edx, [ebp+20]    ; Load third argument into edx
    int    0x80             ; Trigger the system call interrupt

    mov    [ebp-4], eax     ; Save the system call result in local var
    popad                   ; Restore all general-purpose registers
    mov    eax, [ebp-4]     ; Place the return value into eax
    leave                   ; Restore stack and base pointer
    ret

code_start:
infection:
    push   ebp
    mov    ebp, esp
    sub    esp, 4
    pushad

    mov    eax, WRITE
    mov    ebx, STDOUT
    mov    ecx, msg
    mov    edx, msg_len
    int    0x80

    popad
    leave
    ret

infector:
    push   ebp
    mov    ebp, esp
    sub    esp, 4
    pushad

    mov    eax, [ebp+8]

    mov    edx, 0644
    mov    ecx, 1025
    mov    ebx, eax
    mov    eax, OPEN
    int    0x80

    mov    esi, eax

    mov    edx, code_end - code_start
    mov    ecx, code_start
    mov    ebx, esi
    mov    eax, WRITE
    int    0x80

    mov    eax, CLOSE
    mov    ebx, esi
    int    0x80

    popad
    leave
    ret

code_end:
