bits 64
SYS_READ        equ 0
SYS_WRITE       equ 1
SYS_CLOSE       equ 3
SYS_SOCKET      equ 41
SYS_ACCEPT      equ 43
SYS_SHUTDOWN    equ 48
SYS_BIND        equ 49
SYS_LISTEN      equ 50
SYS_SETSOCKOPT  equ 54
SYS_EXIT        equ 60
AF_INET         equ 2
SOCK_STREAM     equ 1
IPPROTO_TCP     equ 6
SOL_SOCKET      equ 1
SO_REUSEADDR    equ 2
SO_REUSEPORT    equ 15
TCP_NODELAY     equ 1
TCP_DEFER_ACCEPT equ 9
TCP_QUICKACK    equ 12
TCP_FASTOPEN    equ 23
SHUT_WR         equ 1
INADDR_ANY      equ 0
PORT            equ 0x901F
DRAIN_BUF_SIZE  equ 1472
section .data
http_response:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: text/plain", 13, 10
    db "Content-Length: 2", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
    db "OK"
http_response_len equ $ - http_response
sockaddr:
    dw AF_INET
    dw PORT
    dd INADDR_ANY
    dq 0
optval  dd 1
msg_start:
    db "[*] http_server :8080 | zero-alloc | ultra-fast", 10
    db "    opts: NODELAY QUICKACK DEFER_ACCEPT REUSEPORT FASTOPEN", 10
msg_start_len equ $ - msg_start
msg_fatal:
    db "[-] fatal: startup failed", 10
msg_fatal_len equ $ - msg_fatal
section .text
global _start
_start:
    mov     rax, SYS_WRITE
    mov     rdi, 1
    mov     rsi, msg_start
    mov     rdx, msg_start_len
    syscall
    mov     r12, optval
    mov     rax, SYS_SOCKET
    mov     rdi, AF_INET
    mov     rsi, SOCK_STREAM
    xor     rdx, rdx
    syscall
    test    rax, rax
    js      .fatal
    mov     r15, rax
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r15
    mov     rsi, SOL_SOCKET
    mov     rdx, SO_REUSEADDR
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r15
    mov     rsi, SOL_SOCKET
    mov     rdx, SO_REUSEPORT
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r15
    mov     rsi, IPPROTO_TCP
    mov     rdx, TCP_DEFER_ACCEPT
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r15
    mov     rsi, IPPROTO_TCP
    mov     rdx, TCP_FASTOPEN
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_BIND
    mov     rdi, r15
    mov     rsi, sockaddr
    mov     rdx, 16
    syscall
    test    rax, rax
    jnz     .fatal
    mov     rax, SYS_LISTEN
    mov     rdi, r15
    mov     rsi, 4096
    syscall
    test    rax, rax
    jnz     .fatal
    sub     rsp, DRAIN_BUF_SIZE
    mov     r13, rsp
.accept_loop:
    mov     rax, SYS_ACCEPT
    mov     rdi, r15
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    test    rax, rax
    js      .accept_loop
    mov     r14, rax
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r14
    mov     rsi, IPPROTO_TCP
    mov     rdx, TCP_NODELAY
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_SETSOCKOPT
    mov     rdi, r14
    mov     rsi, IPPROTO_TCP
    mov     rdx, TCP_QUICKACK
    mov     r10, r12
    mov     r8,  4
    syscall
    mov     rax, SYS_READ
    mov     rdi, r14
    mov     rsi, r13
    mov     rdx, DRAIN_BUF_SIZE
    syscall
    mov     rax, SYS_WRITE
    mov     rdi, r14
    mov     rsi, http_response
    mov     rdx, http_response_len
    syscall
    mov     rax, SYS_SHUTDOWN
    mov     rdi, r14
    mov     rsi, SHUT_WR
    syscall
    mov     rax, SYS_CLOSE
    mov     rdi, r14
    syscall
    jmp     .accept_loop
.fatal:
    mov     rax, SYS_WRITE
    mov     rdi, 2
    mov     rsi, msg_fatal
    mov     rdx, msg_fatal_len
    syscall
    test    r15, r15
    jz      .exit
    mov     rax, SYS_CLOSE
    mov     rdi, r15
    syscall
.exit:
    mov     rax, SYS_EXIT
    mov     rdi, 1
    syscall
