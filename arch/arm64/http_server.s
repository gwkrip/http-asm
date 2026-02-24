.arch armv8-a

SC_R  = 63
SC_W  = 64
SC_CL = 57
SC_SK = 198
SC_AC = 202
SC_SH = 210
SC_B  = 200
SC_L  = 201
SC_SO = 208
SC_EX = 93
AF    = 2
SKT   = 1
TCP   = 6
SOL   = 1
RA    = 2
RP    = 15
ND    = 1
DA    = 9
QA    = 12
FO    = 23
SHW   = 1
PORT  = 0x901F
DBSZ  = 1472

.section .data
hr:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/plain\r\n"
    .ascii "Content-Length: 2\r\n"
    .ascii "Connection: close\r\n"
    .ascii "\r\n"
    .ascii "OK"
hrl = . - hr
sa:
    .2byte AF
    .2byte PORT
    .4byte 0
    .8byte 0
ov:
    .4byte 1
ms:
    .ascii "[*] http_server :8080 | zero-alloc | ultra-fast\n"
    .ascii "    opts: NODELAY QUICKACK DEFER_ACCEPT REUSEPORT FASTOPEN\n"
msl = . - ms
mf:
    .ascii "[-] fatal: startup failed\n"
mfl = . - mf
mbf:
    .ascii "[-] fatal: bind failed (port in use?)\n"
mbfl = . - mbf
mlf:
    .ascii "[-] fatal: listen failed\n"
mlfl = . - mlf

.section .bss
.align 4
db_:
    .space DBSZ

.section .text
.global _start
_start:
    mov  x8,  SC_W
    mov  x0,  1
    adrp x1,  ms
    add  x1,  x1, :lo12:ms
    mov  x2,  msl
    svc  #0
    mov  x19, xzr
    adrp x20, ov
    add  x20, x20, :lo12:ov
    mov  x8,  SC_SK
    mov  x0,  AF
    mov  x1,  SKT
    mov  x2,  xzr
    svc  #0
    tbnz x0,  63, .ft
    mov  x19, x0
    mov  x8,  SC_SO
    mov  x0,  x19
    mov  x1,  SOL
    mov  x2,  RA
    mov  x3,  x20
    mov  x4,  4
    svc  #0
    mov  x8,  SC_SO
    mov  x0,  x19
    mov  x1,  SOL
    mov  x2,  RP
    mov  x3,  x20
    mov  x4,  4
    svc  #0
    mov  x8,  SC_SO
    mov  x0,  x19
    mov  x1,  TCP
    mov  x2,  DA
    mov  x3,  x20
    mov  x4,  4
    svc  #0
    mov  x8,  SC_SO
    mov  x0,  x19
    mov  x1,  TCP
    mov  x2,  FO
    mov  x3,  x20
    mov  x4,  4
    svc  #0
    mov  x8,  SC_B
    mov  x0,  x19
    adrp x1,  sa
    add  x1,  x1, :lo12:sa
    mov  x2,  16
    svc  #0
    cbnz x0,  .bf
    mov  x8,  SC_L
    mov  x0,  x19
    mov  x1,  4096
    svc  #0
    cbnz x0,  .lf
.al:
    mov  x8,  SC_AC
    mov  x0,  x19
    mov  x1,  xzr
    mov  x2,  xzr
    svc  #0
    tbnz x0,  63, .al
    mov  x21, x0
    mov  x8,  SC_SO
    mov  x0,  x21
    mov  x1,  TCP
    mov  x2,  ND
    mov  x3,  x20
    mov  x4,  4
    svc  #0
    mov  x8,  SC_SO
    mov  x0,  x21
    mov  x1,  TCP
    mov  x2,  QA
    mov  x3,  x20
    mov  x4,  4
    svc  #0
.dl:
    mov  x8,  SC_R
    mov  x0,  x21
    adrp x1,  db_
    add  x1,  x1, :lo12:db_
    mov  x2,  DBSZ
    svc  #0
    cbz  x0,  .sr
    tbnz x0,  63, .sr
    cmp  x0,  DBSZ
    b.eq .dl
.sr:
    mov  x8,  SC_W
    mov  x0,  x21
    adrp x1,  hr
    add  x1,  x1, :lo12:hr
    mov  x2,  hrl
    svc  #0
    mov  x8,  SC_SH
    mov  x0,  x21
    mov  x1,  SHW
    svc  #0
    mov  x8,  SC_CL
    mov  x0,  x21
    svc  #0
    b    .al
.bf:
    mov  x8,  SC_W
    mov  x0,  2
    adrp x1,  mbf
    add  x1,  x1, :lo12:mbf
    mov  x2,  mbfl
    svc  #0
    b    .cl
.lf:
    mov  x8,  SC_W
    mov  x0,  2
    adrp x1,  mlf
    add  x1,  x1, :lo12:mlf
    mov  x2,  mlfl
    svc  #0
    b    .cl
.ft:
    mov  x8,  SC_W
    mov  x0,  2
    adrp x1,  mf
    add  x1,  x1, :lo12:mf
    mov  x2,  mfl
    svc  #0
.cl:
    cbz  x19, .ex
    mov  x8,  SC_CL
    mov  x0,  x19
    svc  #0
.ex:
    mov  x8,  SC_EX
    mov  x0,  1
    svc  #0
