TARGET_X86  = build/http_server_x86_64
TARGET_ARM  = build/http_server_arm64
SRC_X86     = arch/x86_64/http_server.asm
SRC_ARM     = arch/arm64/http_server.s
OBJ_X86     = build/http_server_x86_64.o
OBJ_ARM     = build/http_server_arm64.o

.PHONY: all x86_64 arm64 clean

all: x86_64 arm64

x86_64: $(SRC_X86)
	@mkdir -p build
	nasm -f elf64 $(SRC_X86) -o $(OBJ_X86)
	ld $(OBJ_X86) -o $(TARGET_X86)
	@echo "✅  x86_64 → $(TARGET_X86) ($$(wc -c < $(TARGET_X86)) bytes)"

arm64: $(SRC_ARM)
	@mkdir -p build
	aarch64-linux-gnu-as $(SRC_ARM) -o $(OBJ_ARM)
	aarch64-linux-gnu-ld --static $(OBJ_ARM) -o $(TARGET_ARM)
	@echo "✅  arm64  → $(TARGET_ARM) ($$(wc -c < $(TARGET_ARM)) bytes)"

clean:
	rm -rf build/
