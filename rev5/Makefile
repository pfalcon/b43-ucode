BCMASM = b43-asm
PREFIX ?= /lib/firmware/b43-open

all: firmware

ucode5.ucode: ucode5.asm
	$(BCMASM) ucode5.asm ucode5

firmware: ucode5.ucode ../common/spr.inc ../common/shm.inc ../common/cond.inc

install:
	-install -d -o 0 -g 0 -m 755 $(PREFIX)
	-install -o 0 -g 0 -m 644 ucode5.ucode $(PREFIX)/ucode5.fw

clean:
	-rm -f *.ucode *.fw *.orig *.rej *~

