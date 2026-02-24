<div align="center">

# ⚡ httpasm

**HTTP server yang ditulis dalam pure x86-64 Linux Assembly.**  
Zero allocation. Zero dependencies. Zero overhead.

[![Release](https://img.shields.io/github/v/release/gwkrip/http-asm?style=flat-square&color=00d26a)](https://github.com/gwkrip/http-asm/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/gwkrip/http-asm/release.yml?style=flat-square)](https://github.com/gwkrip/http-asm/actions)
[![License](https://img.shields.io/github/license/gwkrip/http-asm?style=flat-square&color=blue)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-linux%20x86--64-lightgrey?style=flat-square)](https://github.com/gwkrip/http-asm)
[![Assembly](https://img.shields.io/badge/language-NASM-critical?style=flat-square)](https://www.nasm.us)

</div>

---

## Apa ini?

`httpasm` adalah HTTP server yang merespons **semua method** (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS) dengan `200 OK` dan body `OK` — ditulis sepenuhnya dalam NASM x86-64 assembly untuk Linux.

Tidak ada C runtime. Tidak ada libc. Tidak ada malloc. Tidak ada BSS.  
Hanya syscall langsung ke kernel, state di register, dan response yang sudah baked ke binary image.

Dibuat sebagai studi kasus: **seberapa rendah latensi yang bisa dicapai dengan kontrol penuh di level assembly?**

---

## Properti

| Property | Nilai |
|---|---|
| **Language** | NASM x86-64 Assembly |
| **Dependencies** | Tidak ada (zero) |
| **Binary size** | < 1 KB |
| **Runtime allocation** | Zero — tidak ada `malloc`, `mmap`, atau BSS |
| **Stack usage** | 1472 byte, dialokasi **sekali** saat startup |
| **State storage** | Register `r12`–`r15` (bukan RAM) |
| **Syscalls per request** | 7 |
| **Platform** | Linux x86-64 (ELF64) |
| **Port** | 8080 |

---

## Optimasi TCP

Server mengaktifkan 5 TCP option untuk meminimalkan latensi end-to-end:

| Option | Efek |
|---|---|
| `TCP_NODELAY` | Matikan Nagle's Algorithm — eliminasi 40–200ms buffer delay |
| `TCP_DEFER_ACCEPT` | `accept()` baru dipanggil setelah data tiba — eliminasi blocking `read()` |
| `TCP_QUICKACK` | ACK dikirim segera, tanpa Delayed ACK 40ms |
| `TCP_FASTOPEN` | Hemat 1 RTT untuk koneksi berulang (TFO cookie) |
| `SO_REUSEPORT` | Multi-proses bisa share port yang sama untuk horizontal scaling |

---

## Alur Per Request

```
Client                    httpasm (kernel)
  │                            │
  │──── SYN ──────────────────►│
  │◄─── SYN+ACK ───────────────│
  │──── ACK + HTTP Request ───►│  ← TCP_DEFER_ACCEPT: accept() baru bangun di sini
  │                            │
  │                      accept()        r14 = client_fd
  │                      setsockopt()    TCP_NODELAY  (matikan Nagle)
  │                      setsockopt()    TCP_QUICKACK (ACK cepat)
  │                      read()          drain request ke stack buffer (non-blocking)
  │                      write()         kirim "HTTP/1.1 200 OK\r\n...OK"
  │                      shutdown()      kirim FIN (graceful, bukan RST)
  │                      close()         bebaskan fd
  │                            │
  │◄─── HTTP 200 OK ───────────│
```

---

## Memori Layout

```
╔══════════════════════════════════════════════╗
║  .text   →  kode instruksi (read + execute)  ║
║  .data   →  response + sockaddr (read-only)  ║
║  .bss    →  TIDAK ADA                        ║
║  heap    →  TIDAK ADA                        ║
║  stack   →  1472 byte (alokasi sekali)       ║
╠══════════════════════════════════════════════╣
║  r12  =  &optval          (konstan)          ║
║  r13  =  drain_buf ptr    (konstan)          ║
║  r14  =  client_fd        (per-accept)       ║
║  r15  =  server_fd        (konstan)          ║
╚══════════════════════════════════════════════╝
```

Semua state server hidup di **register CPU**, bukan di RAM. Tidak ada akses memori global di hotpath.

---

## Quickstart

### Requirements

- Linux x86-64
- [`nasm`](https://www.nasm.us/) ≥ 2.14
- `ld` / `binutils`

```bash
# Ubuntu / Debian
sudo apt install nasm binutils

# Arch
sudo pacman -S nasm binutils

# Fedora
sudo dnf install nasm binutils
```

### Build

```bash
git clone https://github.com/gwkrip/http-asm
cd httpasm

# Manual
nasm -f elf64 http_server.asm -o http_server.o
ld --strip-all http_server.o -o http_server

# Atau pakai Makefile
make build
```

### Run

```bash
./http_server
# [*] http_server :8080 | zero-alloc | ultra-fast
```

### Test semua HTTP method

```bash
curl -X GET     http://localhost:8080/           # → OK
curl -X POST    http://localhost:8080/ -d "x=1"  # → OK
curl -X PUT     http://localhost:8080/item/1     # → OK
curl -X DELETE  http://localhost:8080/item/1     # → OK
curl -X PATCH   http://localhost:8080/item/1     # → OK
curl -X HEAD    http://localhost:8080/ -I        # → 200 OK
curl -X OPTIONS http://localhost:8080/           # → OK
```

---

## Benchmark

```bash
# Dengan wrk
wrk -t4 -c100 -d10s http://localhost:8080/

# Dengan Apache Bench
ab -n 10000 -c 100 http://localhost:8080/
```

Untuk hasil optimal, aktifkan TCP Fast Open di kernel terlebih dahulu:

```bash
sudo sysctl -w net.ipv4.tcp_fastopen=3
sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65535
```

---

## Release

Binary siap pakai tersedia di [Releases](https://github.com/gwkrip/http-asm/releases).

```bash
# Download binary terbaru
curl -LO https://github.com/gwkrip/http-asm/releases/latest/download/http_server

# Verifikasi checksum
curl -LO https://github.com/gwkrip/http-asm/releases/latest/download/SHA256SUMS
sha256sum --check SHA256SUMS

# Jalankan
chmod +x http_server && ./http_server
```

### Cara membuat release baru

```bash
git tag v1.0.0
git push origin v1.0.0
# GitHub Actions otomatis build, test, dan publish release
```

---

## Struktur Repo

```
httpasm/
├── http_server.asm          # Source code utama (NASM)
├── Makefile                 # Build, run, test, benchmark
├── README.md
└── .github/
    └── workflows/
        └── release.yml      # CI/CD: build → smoke test → release
```

---

## Cara Kerja (Detail Teknis)

### Zero Allocation

| Komponen | Penjelasan |
|---|---|
| **`.bss` dihapus** | Tidak ada global mutable memory. Kernel tidak perlu `mmap` anonymous segment. |
| **Stack buffer** | `sub rsp, 1472` dijalankan **sekali** saat startup. Tidak ada `malloc`/`free`. |
| **Buffer reuse** | Tiap request menulis ke lokasi stack yang **sama**. Tidak ada clear/memset. |
| **Register state** | `sock_fd`, `client_fd`, `optval ptr`, `buf ptr` semua di register. Nol memory load/store di hotpath. |

### Mengapa `TCP_DEFER_ACCEPT` penting?

Tanpa `TCP_DEFER_ACCEPT`, urutan event adalah:

```
SYN → SYN+ACK → ACK          # handshake selesai
accept() bangun               # ← proses bangun di sini
read()                        # ← BLOCKING, request belum tentu ada
... tunggu 1 RTT ...
HTTP request tiba
read() return
```

Dengan `TCP_DEFER_ACCEPT`:

```
SYN → SYN+ACK → ACK + Data   # handshake + request dalam satu paket
accept() bangun               # ← proses bangun SETELAH data ada
read()                        # ← LANGSUNG return, tidak blocking
```

Eliminasi 1 RTT dari critical path.

### Mengapa `shutdown()` sebelum `close()`?

`close()` dengan data yang belum dibaca di receive buffer menyebabkan kernel mengirim **RST** (reset), bukan **FIN**. Client yang mendapat RST bisa abort koneksi sebelum sempat membaca response yang sudah dikirim.

`shutdown(SHUT_WR)` mengirim FIN secara eksplisit terlebih dahulu → client tahu server sudah selesai mengirim data → `close()` aman dilakukan.

---

## License

[MIT](LICENSE)
