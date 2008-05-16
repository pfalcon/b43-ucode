/*
 *  BCM43xx device microcode
 *   For Wireless-Core Revision 5
 *
 *  Copyright (C) 2008 Michael Buesch <mb@bu3sch.de>
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License
 *   version 2, as published by the Free Software Foundation.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 */

#define VERSION		1

#include "../common/gpr.inc"
#include "../common/spr.inc"
#include "../common/shm.inc"
#include "../common/cond.inc"


#define PANIC(reason)		\
	mov reason, r3		;\
	call lr0, __panic
#define PANIC_DIE	0

#define DEBUGIRQ(reason)		\
	mov reason, r63			;\
	mov IRQHI_DEBUG, SPR_MAC_IRQHI
#define DEBUG_PANIC	0

#define ret_after_jmp	mov r0, r0 ; ret

#define lo16(val)	((val) & 0xFFFF)
#define hi16(val)	(((val) >> 16) & 0xFFFF)

%arch	5
%start	entry_point


entry_point:	/* ------ ENTRY POINT ------ */
	mov SHM_UCODESTAT_INIT, [SHM_UCODESTAT]
	/* SHM and registers are already cleared by the kernel
	 * Initialize meta information */
	mov 0x129, [SHM_UCODEREV]	/* We emulate a v4 firmware */
	mov 0, [SHM_UCODEPATCH]
	/* The "all ones" date is an indication to the driver that we
	 * are using custom firmware. Note that this date is impossible. ;) */
	mov 0xFFFF, [SHM_UCODEDATE]
	/* We encode our versioning info in the "time" field. */
	mov VERSION, [SHM_UCODETIME]

 loop:
	mov IRQLO_MAC_SUSPENDED, SPR_MAC_IRQLO
	jmp loop-
	/* Initialize the hardware */

	mov 0, SPR_GPIO_Out			/* Disable any GPIO pin */
	mov 0, SPR_PSM_0x4e			/* FIXME needed? */
	mov 0, SPR_PSM_0x0c			/* FIXME what is this? */
	mov 32786, SPR_SCC_Divisor		/* Init slow clock control */
	mov 0x0002, SPR_SCC_Control		/* Init slow clock control */
	or SPR_PHY_HDR_Parameter, 2, SPR_PHY_HDR_Parameter
	mov 0, Ra				/* Read PHY version register */
	call lr0, phy_read
	orx 7, 0, Ra, 0, [SHM_PHYVER]
	srx 3, 8, Ra, 0, [SHM_PHYTYPE]
	mov 0x39, [0xC0]			/* FIXME is this needed? */
	mov 0x50, [0xC2]			/* FIXME is this needed? */
/*TODO init TX control fields*/
	mov 2, SPR_PHY_HDR_Parameter
	mov R_MIN_CONTWND, R_CUR_CONTWND
	and SPR_TSF_Random, R_CUR_CONTWND, SPR_IFS_BKOFFDELAY
	mov 0x4000, SPR_TSF_GPT0_STAT		/* GP Timer 0: 8MHz */
	mov lo16(280000), SPR_TSF_GPT0_CNTLO	/* GP Timer 0: Counter = 280,000 */
	mov hi16(280000), SPR_TSF_GPT0_CNTHI

	mov SHM_UCODESTAT_SUSP, [SHM_UCODESTAT]

/* -- The main event loop -- */
 _sleep:
	mov IRQLO_MAC_SUSPENDED, SPR_MAC_IRQLO
	orx 0, 15, 0, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GP Timer 0: Start */
 loop:
	jnext COND_MACEN, r0, r0, loop-

 _evloop_begin:

	// TODO

	jnext COND_MACEN, r0, r0, _sleep
	jmp _evloop_begin

/* --- Function: Read from a PHY register ---
 * Link Register: lr0
 * The PHY Address is passed in Ra.
 * The Data is returned in Ra.
 */
phy_read:
 busy:
	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	orx 0, 12, 1, Ra, SPR_Ext_IHR_Address
 busy:
	jnzx 0, 12, SPR_Ext_IHR_Address, 0, busy-
	mov SPR_Ext_IHR_Data, Ra
	ret lr0, lr0

/* --- Function: Write to a PHY register ---
 * Link Register: lr0
 * The PHY Address is passed in Ra
 * The Data to write is passed in Rb
 */
phy_write:
 busy:
	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	mov Rb, SPR_Ext_IHR_Data
	orx 0, 13, 1, Ra, SPR_Ext_IHR_Address
 busy:
	jnzx 0, 13, SPR_Ext_IHR_Address, 9, busy-
	ret_after_jmp lr0, lr0

/* --- Function: Lowlevel panic helper --- */
__panic:
	/* The Panic reason is in r3. We can read that from the kernel. */
	DEBUGIRQ(DEBUG_PANIC)
 loop:
 	jmp loop-

// vim: syntax=b43 ts=8
