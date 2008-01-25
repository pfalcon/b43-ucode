;
;  Broadcom BCM43xx Microcode
;   For Wireless-Core Revision 5
;
;  Copyright (C) 2006 Michael Buesch <mb@bu3sch.de>
;
;  Stacked-function-call helpers idea by
;  Johannes Berg <johannes@sipsolutions.net>
;
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; see the file COPYING.  If not, write to
;  the Free Software Foundation, Inc., 51 Franklin Steet, Fifth Floor,
;  Boston, MA 02110-1301, USA.

#define VERSION		1

#include "../common/spr.inc"
#include "../common/shm.inc"
#include "../common/cond.inc"


#define STACKPTR	off5

#define CALL(fn)			\
	mov	fn, r63			\
	call	lr0, __call_helper
#define RET				\
	call	lr0, __ret_helper

#define PANIC(reason)			\
	mov	reason, r3		\
	call	lr0, __panic
#define PANIC_DIE	0

#define DEBUGIRQ(reason)			\
	mov	reason, r63			\
	mov	IRQHI_DEBUG, SPR_MAC_IRQHI
#define DEBUG_PANIC	0

%arch	5
%start	entry_point


entry_point:	; ------ ENTRY POINT ------
	; Clear the SHM
	mov	0x7FF, off0
 loop:
	mov	0, [0, off0]
	sub	off0, 1, off0
	jne	off0, 0, loop-

	; Initialize meta information
	mov	0x129, [SHM_UCODEREV]	; We emulate a v4 firmware
	mov	0, [SHM_UCODEPATCH]
	; The "all ones" date is an indication to the driver that we
	; are using custom firmware. Note that this date is impossible. ;)
	mov	0xFFFF, [SHM_UCODEDATE]
	; We encode our versioning info in the "time" field.
	mov	VERSION, [SHM_UCODETIME]

	mov	SHM_UCODESTAT_INIT, [SHM_UCODESTAT]

	; Initialize the stack
	mov	0x7FF, STACKPTR

; -- The main event loop --
 _sleep:
 	mov	0, SPR_MAC_IRQHI
	mov	IRQLO_MAC_SUSPENDED, SPR_MAC_IRQLO
 loop:
	jnext	COND_MACEN, r0, r0, loop-

 _evloop_begin:

	; TODO

	jnext	COND_MACEN, r0, r0, _sleep
	jmp	_evloop_begin

; --- Stacked-function-call helpers ---
; Expects the callee address in r63
__call_helper:
	mov	SPR_PC0, [0, STACKPTR]
	mov	r63, SPR_PC0
	sub	STACKPTR, 1, STACKPTR
	mov	SPR_PC0, 0		; commit
	ret	lr0, lr0		; Jump to our function
__ret_helper:
	add	STACKPTR, 1, STACKPTR
	mov	[0, STACKPTR], SPR_PC0
	mov	SPR_PC0, 0		; commit
	ret	lr0, lr0

; Panic routine
__panic:
	; The Panic reason is in r3. We can read that from the kernel.
	DEBUGIRQ(DEBUG_PANIC)
 _panic_busyloop:
 	jmp	_panic_busyloop
