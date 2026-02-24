bits 64
SC_R  equ 0
SC_W  equ 1
SC_CL equ 3
SC_SK equ 41
SC_AC equ 43
SC_SH equ 48
SC_B  equ 49
SC_L  equ 50
SC_SO equ 54
SC_EX equ 60
AF    equ 2
ST    equ 1
TCP   equ 6
SOL   equ 1
RA    equ 2
RP    equ 15
ND    equ 1
DA    equ 9
QA    equ 12
FO    equ 23
SW    equ 1
PORT  equ 0x901F
DBSZ  equ 1472

section .data
rsp:
    db "HTTP/1.1 200 OK",13,10
    db "Content-Type: text/plain",13,10
    db "Content-Length: 2",13,10
    db "Connection: close",13,10,13,10
    db "OK"
rsl equ $ - rsp
sa:
    dw AF
    dw PORT
    dd 0
    dq 0
ov  dd 1
ms:
    db "[*] http_server :8080 | zero-alloc | ultra-fast",10
    db "    opts: NODELAY QUICKACK DEFER_ACCEPT REUSEPORT FASTOPEN",10
msl equ $ - ms
mf:
    db "[-] fatal: startup failed",10
mfl equ $ - mf
mbf:
    db "[-] fatal: bind failed (port in use?)",10
mbfl equ $ - mbf
mlf:
    db "[-] fatal: listen failed",10
mlfl equ $ - mlf

section .bss
db_: resb DBSZ

section .text
global _start
_start:
    mov  rax, SC_W
    mov  rdi, 1
    lea  rsi, [rel ms]
    mov  rdx, msl
    syscall
    xor  r15, r15
    lea  r12, [rel ov]
    mov  rax, SC_SK
    mov  rdi, AF
    mov  rsi, ST
    xor  rdx, rdx
    syscall
    test rax, rax
    js   .ft
    mov  r15, rax
    mov  rax, SC_SO
    mov  rdi, r15
    mov  rsi, SOL
    mov  rdx, RA
    mov  r10, r12
    mov  r8,  4
    syscall
    mov  rax, SC_SO
    mov  rdi, r15
    mov  rsi, SOL
    mov  rdx, RP
    mov  r10, r12
    mov  r8,  4
    syscall
    mov  rax, SC_SO
    mov  rdi, r15
    mov  rsi, TCP
    mov  rdx, DA
    mov  r10, r12
    mov  r8,  4
    syscall
    mov  rax, SC_SO
    mov  rdi, r15
    mov  rsi, TCP
    mov  rdx, FO
    mov  r10, r12
    mov  r8,  4
    syscall
    mov  rax, SC_B
    mov  rdi, r15
    lea  rsi, [rel sa]
    mov  rdx, 16
    syscall
    test rax, rax
    jnz  .bf
    mov  rax, SC_L
    mov  rdi, r15
    mov  rsi, 4096
    syscall
    test rax, rax
    jnz  .lf
.al:
    mov  rax, SC_AC
    mov  rdi, r15
    xor  rsi, rsi
    xor  rdx, rdx
    syscall
    test rax, rax
    js   .al
    mov  r14, rax
    mov  rax, SC_SO
    mov  rdi, r14
    mov  rsi, TCP
    mov  rdx, ND
    mov  r10, r12
    mov  r8,  4
    syscall
    mov  rax, SC_SO
    mov  rdi, r14
    mov  rsi, TCP
    mov  rdx, QA
    mov  r10, r12
    mov  r8,  4
    syscall
.dl:
    mov  rax, SC_R
    mov  rdi, r14
    lea  rsi, [rel db_]
    mov  rdx, DBSZ
    syscall
    test rax, rax
    jle  .sr
    cmp  rax, DBSZ
    je   .dl
.sr:
    mov  rax, SC_W
    mov  rdi, r14
    lea  rsi, [rel rsp]
    mov  rdx, rsl
    syscall
    mov  rax, SC_SH
    mov  rdi, r14
    mov  rsi, SW
    syscall
    mov  rax, SC_CL
    mov  rdi, r14
    syscall
    jmp  .al
.bf:
    mov  rax, SC_W
    mov  rdi, 2
    lea  rsi, [rel mbf]
    mov  rdx, mbfl
    syscall
    jmp  .cl
.lf:
    mov  rax, SC_W
    mov  rdi, 2
    lea  rsi, [rel mlf]
    mov  rdx, mlfl
    syscall
    jmp  .cl
.ft:
    mov  rax, SC_W
    mov  rdi, 2
    lea  rsi, [rel mf]
    mov  rdx, mfl
    syscall
.cl:
    test r15, r15
    jz   .ex
    mov  rax, SC_CL
    mov  rdi, r15
    syscall
.ex:
    mov  rax, SC_EX
    mov  rdi, 1
    syscall
