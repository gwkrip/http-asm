# http-asm
Ultra-fast HTTP server in pure x86-64 Linux Assembly. Zero allocation, zero dependencies — direct syscalls, state in registers, 7 syscalls/request with TCP_NODELAY + DEFER_ACCEPT + QUICKACK.
