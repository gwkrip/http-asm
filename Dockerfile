FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends nasm binutils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY arch/x86_64/http_server.asm .

RUN nasm -f elf64 http_server.asm -o http_server.o && \
    ld --strip-all http_server.o -o http_server


FROM scratch

COPY --from=builder /build/http_server /http_server

EXPOSE 8080

ENTRYPOINT ["/http_server"]
