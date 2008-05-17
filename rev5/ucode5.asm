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
#include "../common/stack.inc"


#define PANIC(reason)		\
	mov reason, r3;		\
	call lr0, __panic;
#define PANIC_DIE	0

#define DEBUGIRQ(reason)		\
	mov reason, r63;		\
	mov IRQHI_DEBUG, SPR_MAC_IRQHI;
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
	mov 352, [SHM_UCODEREV]	/* We emulate a v4 firmware */
	mov 0, [SHM_UCODEPATCH]
	/* The "all ones" date is an indication to the driver that we
	 * are using custom firmware. Note that this date is impossible. ;) */
	mov 0xFFFF, [SHM_UCODEDATE]
	/* We encode our versioning info in the "time" field. */
	mov VERSION, [SHM_UCODETIME]

	mov 0x7FF, R_STACK_POINTER

	/* Initialize the hardware */
	mov 0, SPR_GPIO_Out			/* Disable any GPIO pin */
	mov 0, SPR_PSM_0x4e			/* FIXME needed? */
	mov 0, SPR_PSM_0x0c			/* FIXME what is this? */
	mov 32786, SPR_SCC_Divisor		/* Init slow clock control */
	mov 0x0002, SPR_SCC_Control		/* Init slow clock control */
	or SPR_PHY_HDR_Parameter, 2, SPR_PHY_HDR_Parameter /* PHY clock on */
	mov 0, Ra				/* Read PHY version register */
	call lr0, phy_read
	orx 7, 0, Ra, 0, [SHM_PHYVER]
	srx 3, 8, Ra, 0, [SHM_PHYTYPE]
	mov 0x39, [0xC0]			/* FIXME this sets probe resp context block */
	mov 0x50, [0xC2]			/* FIXME what is this? */
	mov 0xFC00, [SHM_PRPHYCTL]		/* Probe response PHY TX control word */
	mov 0xFF00, [SHM_ACKCTSPHYCTL]		/* ACK/CTS PHY TX control word */
	mov 2, SPR_PHY_HDR_Parameter
	mov R_MIN_CONTWND, R_CUR_CONTWND
	and SPR_TSF_Random, R_CUR_CONTWND, SPR_IFS_BKOFFDELAY
	mov 0x4000, SPR_TSF_GPT0_STAT		/* GP Timer 0: 8MHz */
	mov lo16(280000), SPR_TSF_GPT0_CNTLO	/* GP Timer 0: Counter = 280,000 */
	mov hi16(280000), SPR_TSF_GPT0_CNTHI

/* -- The MAC suspend loop -- */
 sleep:
	mov SHM_UCODESTAT_SUSP, [SHM_UCODESTAT]
	mov IRQLO_MAC_SUSPENDED, SPR_MAC_IRQLO
	orx 0, 15, 0, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GP Timer 0: clear Start */
 self:	jnext COND_MACEN, r0, r0, self-
	mov SHM_UCODESTAT_ACTIVE, [SHM_UCODESTAT]

	mov 0, SPR_BRC
	mov 0xFFFF, SPR_BRCL_0
	mov 0xFFFF, SPR_BRCL_1
	mov 0xFFFF, SPR_BRCL_2
	mov 0xFFFF, SPR_BRCL_3
	or SPR_RXE_0x08, 0x0004, SPR_RXE_0x08
 self:	jnzx 0, 2, SPR_RXE_0x08, 0, self-	/* Wait for 0x4 to clear */
	orx 0, 15, 1, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GP Timer 0: Start */
	mov 0, SPR_BRCL_0
	mov 0, SPR_BRCL_1
	mov 0, SPR_BRCL_2
	mov 0, SPR_BRCL_3
	/* TODO: setup TX status and PMQ discarding (MACCTL hi) */
	mov 0x7360, SPR_BRWK_0
	mov 0x0000, SPR_BRWK_1
	mov 0x730F, SPR_BRWK_2
	mov 0x0057, SPR_BRWK_3

/* -- Restart the event loop -- */
eventloop_restart:

	// TODO

	jnext COND_MACEN, r0, r0, sleep

eventloop_idle:
	jext COND_PSM(0), r0, r0, eventloop_restart	/* FIXME: What's PSM condition bit 0? */
	//TODO: if CCA -> restart
	//TODO: if BG noise measuring -> restart
	jnzx 0, SHM_HF_MI_TXBTCHECK, [SHM_HF_MI], 0, eventloop_restart
	mov 0xFFFF, SPR_MAC_MAX_NAP
	nap						/* .oO( ZzzzZZZzzz..... ) */
	jmp eventloop_restart

/* --- Function: Read from a PHY register ---
 * Link Register: lr0
 * The PHY Address is passed in Ra.
 * The Data is returned in Ra.
 */
phy_read:
 busy:	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	orx 0, 12, 1, Ra, SPR_Ext_IHR_Address
 busy:	jnzx 0, 12, SPR_Ext_IHR_Address, 0, busy-
	mov SPR_Ext_IHR_Data, Ra
	ret lr0, lr0

/* --- Function: Write to a PHY register ---
 * Link Register: lr0
 * The PHY Address is passed in Ra.
 * The Data to write is passed in Rb.
 */
phy_write:
 busy:	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	mov Rb, SPR_Ext_IHR_Data
	orx 0, 13, 1, Ra, SPR_Ext_IHR_Address
 busy:	jnzx 0, 13, SPR_Ext_IHR_Address, 0, busy-
	ret_after_jmp lr0, lr0

/* --- Function: Write to a PHY register. Don't flush ---
 * Link Register: lr0
 * The PHY address is passed in Ra.
 * The Data to write is passed in Rb.
 * This function will not busywait to flush the data write.
 * Use phy_write(), if you want flushing.
 */
phy_write_noflush:
 busy:	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	mov Rb, SPR_Ext_IHR_Data
	orx 0, 13, 1, Ra, SPR_Ext_IHR_Address
	ret lr0, lr0

/* --- Function: Read from a Radio register ---
 * Link Register: lr0
 * The Radio Address is passed in Ra
 * The Data is returned in Ra
 */
radio_read:
	PUSH(SPR_PC0)
	PUSH(Rb)
	mov Ra, Rb	/* Rb = radio address */
	mov 0, Ra
	jnzx 0, MACCTL_RADIOLOCK, SPR_MAC_CTLHI, 0, out+
	mov 0xB, Ra	/* PHY register 0xB */
	call lr0, phy_write
	mov 0xD, Ra	/* PHY register 0xD */
	call lr0, phy_read
 out:
	/* The radio register content (or zero, if the
	 * radio was locked) is in Ra */
	POP(Rb)
	POP(SPR_PC0)
	ret lr0, lr0

/* --- Function: Write to a Radio register ---
 * Link Register: lr0
 * The Radio Address is passed in Ra
 * The Data to write is passed in Rb
 * Ra and Rb are clobbered
 */
radio_write:
	PUSH(SPR_PC0)
	PUSH(Rc)
	PUSH(Rd)
	jnzx 0, MACCTL_RADIOLOCK, SPR_MAC_CTLHI, 0, out+
	mov Ra, Rc	/* Rc = Radio address */
	mov Rb, Rd	/* Rd = data */
	mov 0xB, Ra	/* PHY register 0xB */
	mov Rc, Rb
	call lr0, phy_write_noflush
	mov 0xD, Ra	/* PHY register 0xD */
	mov Rd, Rb
	call lr0, phy_write_noflush
 out:
	POP(Rd)
	POP(Rc)
	POP(SPR_PC0)
	ret lr0, lr0

/* --- Function: Lowlevel panic helper --- */
__panic:
	/* The Panic reason is in r3. We can read that from the kernel. */
	DEBUGIRQ(DEBUG_PANIC)
 self:	jmp self-



#include "../common/stack.asm"

// vim: syntax=b43 ts=8
