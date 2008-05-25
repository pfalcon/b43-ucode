BCMASM = b43-asm
PREFIX ?= /lib/firmware/b43-open

all: ucode5.fw

ucode5.fw: ucode5.asm initvals.asm ../common/stack.asm ../common/gpr.inc ../common/spr.inc ../common/shm.inc ../common/cond.inc ../common/stack.inc ../common/phy.inc ../common/debug.inc ../common/ieee80211.inc
	$(BCMASM) ucode5.asm ucode5.fw --ivalext .fw --psize

install: all
	-install -d -o 0 -g 0 -m 755 $(PREFIX)
	-install -o 0 -g 0 -m 644 ucode5.fw $(PREFIX)/
	-install -o 0 -g 0 -m 644 b0g0initvals5.fw $(PREFIX)/
	-install -o 0 -g 0 -m 644 b0g0bsinitvals5.fw $(PREFIX)/

clean:
	-rm -f *.fw *.orig *.rej *~

.PHONY: all install clean
