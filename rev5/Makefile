BCMASM = b43-asm

all: firmware

ucode5.ucode: ucode5.asm
	$(BCMASM) ucode5.asm ucode5

firmware: ucode5.ucode ../common/spr.inc ../common/shm.inc ../common/cond.inc

clean:
	-rm -f *.ucode *.fw *.orig *.rej *~

