TARGET  = http_server
SRC     = http_server.asm
OBJ     = http_server.o

.PHONY: all build run test test-large bench bench-ab syscheck clean

all: build

build: $(SRC)
	nasm -f elf64 $(SRC) -o $(OBJ)
	ld $(OBJ) -o $(TARGET)
	@echo ""
	@echo "✅  Build sukses → ./$(TARGET)"
	@echo "    Size: $$(wc -c < $(TARGET)) bytes"
	@echo ""

run: build
	@echo "🚀  Server jalan di :8080 (Ctrl+C stop)"
	./$(TARGET)

test:
	@echo "=== Testing all HTTP methods ==="
	@echo "── GET ──"
	@curl -sv -X GET     http://localhost:8080/ 2>&1 | grep -E "< HTTP|< Content|^OK"
	@echo ""
	@echo "── POST ──"
	@curl -sv -X POST    http://localhost:8080/ -d "x=1" 2>&1 | grep -E "< HTTP|< Content|^OK"
	@echo ""
	@echo "── PUT ──"
	@curl -sv -X PUT     http://localhost:8080/item 2>&1 | grep -E "< HTTP|< Content|^OK"
	@echo ""
	@echo "── DELETE ──"
	@curl -sv -X DELETE  http://localhost:8080/item 2>&1 | grep -E "< HTTP|< Content|^OK"
	@echo ""
	@echo "── PATCH ──"
	@curl -sv -X PATCH   http://localhost:8080/item 2>&1 | grep -E "< HTTP|< Content|^OK"
	@echo ""
	@echo "── HEAD ──"
	@curl -sv -X HEAD    http://localhost:8080/ -I 2>&1 | grep -E "< HTTP|< Content"
	@echo ""
	@echo "── OPTIONS ──"
	@curl -sv -X OPTIONS http://localhost:8080/ 2>&1 | grep -E "< HTTP|< Content|^OK"

test-large:
	@echo "=== Large body POST test ==="
	@python3 -c "print('x=' + 'A'*2000)" | curl -sv -X POST http://localhost:8080/ -d @- 2>&1 | grep -E "< HTTP|< Content|^OK"

bench:
	wrk -t4 -c100 -d10s http://localhost:8080/

bench-ab:
	ab -n 10000 -c 100 http://localhost:8080/

syscheck:
	@echo "=== Kernel TCP Optimization Support ==="
	@echo -n "TCP_FASTOPEN: "
	@cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo "not available"
	@echo -n "TCP max backlog: "
	@cat /proc/sys/net/core/somaxconn
	@echo -n "TCP SYN backlog: "
	@cat /proc/sys/net/ipv4/tcp_max_syn_backlog
	@echo ""
	@echo "  sudo sysctl -w net.ipv4.tcp_fastopen=3"
	@echo "  sudo sysctl -w net.core.somaxconn=65535"
	@echo "  sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65535"

clean:
	rm -f $(OBJ) $(TARGET)
