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

#define VERSION		0

#include "../common/debug.inc"
#include "../common/gpr.inc"
#include "../common/spr.inc"
#include "../common/shm.inc"
#include "../common/phy.inc"
#include "../common/cond.inc"
#include "../common/stack.inc"


/* Frame Check Sequence length; in bytes */
#define FCS_LEN			4
/* Smallest possible frame length; in bytes. */
#define MIN_IEEE80211_FRAME_LEN	(((6 + 2) + 2) + FCS_LEN)
/* Maximum possible frame length; in bytes. */
#define MAX_IEEE80211_FRAME_LEN	(2352 + FCS_LEN)
/* The PLCP header length; in bytes. */
#define PLCP_HDR_LEN		6


/* RET can't be used right after a jump instruction. Use this, if
 * you need to return right after a jump.
 * This will add a no-op before the ret. */
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

	mov SHM_STACK_START, R_STACK_POINTER

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
 self:	jnext COND_MACEN, self-

	mov SHM_UCODESTAT_ACTIVE, [SHM_UCODESTAT]
	mov 0, SPR_BRC
	mov 0xFFFF, SPR_BRCL_0
	mov 0xFFFF, SPR_BRCL_1
	mov 0xFFFF, SPR_BRCL_2
	mov 0xFFFF, SPR_BRCL_3
	or SPR_RXE_FIFOCTL1, 0x0004, SPR_RXE_FIFOCTL1
 self:	jnzx 0, 2, SPR_RXE_FIFOCTL1, 0, self-	/* Wait for 0x4 to clear */
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
	and SPR_PSM_COND, (~0x1), SPR_PSM_COND
	jnext EOI(COND_RADAR), no_radar_workaround+
	jzx 0, SHM_HF_LO_RADARW, [SHM_HF_LO], 0, no_radar_workaround+
	//TODO write SHM radar value to APHY radar thres1
 no_radar_workaround:
	extcond_eoi_only(COND_PHY0)
	extcond_eoi_only(COND_PHY1)
	jzx 0, 3, SPR_IFS_STAT, 0, no_txstat+
	//TODO process TXstat
 no_txstat:
	call lr0, update_gphy_classify_ctl	/* Classify ctrl from SHM to PHY */
	mov lo16(280000), SPR_TSF_GPT0_VALLO	/* GP Timer 0: Value = 280,000 */
	mov hi16(280000), SPR_TSF_GPT0_VALHI
	orx 0, 14, 0x3, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GPT0: Start and ON */
	jnext COND_MACEN, sleep			/* Driver disabled the MAC? Go to sleep. */

	jnext COND_TX_FLUSH, no_txflush+
	MARKER(0) /* TODO: handle TX flush request */
 no_txflush:

	/* Check if there's some real work to be done. */
	jext EOI(COND_TX_NOW), transmit_frame
	//TODO Some CTS related stuff
	jext EOI(COND_TX_UNDERFLOW), handle_tx_underflow
	jext COND_TX_2, tx_postprocess
	jext COND_TX_PHYERR, phy_tx_error
	//TODO more stuff needed
	jext EOI(COND_RX_PLCP), received_valid_plcp
	jext COND_RX_COMPLETE, rx_complete_handler

	// TODO

eventloop_idle:
	mov 0, R_WATCHDOG
 #if DEBUG
	mov MAGIC_STACK_END, Ra
	je [SHM_STACK_END], Ra, no_stack_corruption+
	PANIC(PANIC_DIE)
 no_stack_corruption:
 #endif
	jext COND_PSM(0), eventloop_restart	/* FIXME: What's PSM condition bit 0? */
	//TODO: if CCA -> restart
	//TODO: if BG noise measuring -> restart
	jnzx 0, SHM_HF_MI_TXBTCHECK, [SHM_HF_MI], 0, eventloop_restart
	mov 0xFFFF, SPR_MAC_MAX_NAP
	nap						/* .oO( ZzzzZZZzzz..... ) */
	jmp eventloop_restart

/* --- Function: Set GPHY classify control to OFDM-only
 * Link Register: lr0
 */
gphy_classify_ctl_ofdm:
	PUSH(SPR_PC0)
	and [SHM_GCLASSCTL], (~(1 << GPHY_CLASSCTL_CCK)), Rb
	jmp _write_gclassctl

/* --- Function: Update the GPHY classify control value from SHM.
 * Link Register: lr0
 */
update_gphy_classify_ctl:
	PUSH(SPR_PC0)
	mov [SHM_GCLASSCTL], Rb
 _write_gclassctl: /* jump from gphy_classify_ctl_ofdm() */
	jne [SHM_PHYTYPE], PHYTYPE_G, out+
	mov GPHY_CLASSCTL, Ra
	call lr0, phy_write
 out:
	POP(SPR_PC0)
	ret lr0, lr0

/* --- Handler: Transmit another frame --- */
transmit_frame:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: TX data underflow --- */
handle_tx_underflow:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: Do some post-TX processing --- */
tx_postprocess:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: The PHY threw an error --- */
phy_tx_error:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: We received a PLCP */
received_valid_plcp:
 wait:	jext EOI(COND_RX_FCS_GOOD), wait-		/* Clear the FCS-good cond from previous frames */
	jnzx 0, 2, SPR_RXE_FIFOCTL1, 0, eventloop_idle	/* No packet available */
 tsf_again:
	mov SPR_TSF_WORD0, [SHM_RX_TSF0]		/* Read the TSF timestamp for the received frame */
	mov SPR_TSF_WORD1, [SHM_RX_TSF1]
	mov SPR_TSF_WORD2, [SHM_RX_TSF2]
	mov SPR_TSF_WORD3, [SHM_RX_TSF3]
	jl SPR_TSF_WORD0, [SHM_RX_TSF0], tsf_again-	/* word0 overflow */
	jzx 0, 0, SPR_TXE0_CTL, 0, txengine_ok+
	mov 0, SPR_TXE0_CTL				/* Disable the TX engine */
	and SPR_BRC, (~3), SPR_BRC
 txengine_ok:
	or SPR_BRC, 0x140, SPR_BRC
	orx 0, 9, 1, SPR_BRC, SPR_BRC			/* SPR_BRC |= 0x200 */
	jext COND_RX_FIFOFULL, rx_fifo_overflow
	jnzx 0, 15, SPR_RXE_0x1a, 0, rx_not_ready	/* We're not ready, yet. */
 rx_headerwait:						/* Wait for the header to arrive */
	jext COND_RX_COMPLETE, rx_complete+
	jl SPR_RXE_FRAMELEN, (PLCP_HDR_LEN + 32), rx_headerwait-
 rx_complete:
	jl SPR_RXE_FRAMELEN, (MIN_IEEE80211_FRAME_LEN + PLCP_HDR_LEN), drop_received_frame

	mov 0x8300, SPR_WEP_CTL				/* Disable crypto */
	or SPR_RXE_FIFOCTL1, 0x2, SPR_RXE_FIFOCTL1
	and SPR_BRC, (~0x40), SPR_BRC

	/* Wait for the frame receive to complete. */
 wait:	jnext COND_RX_COMPLETE, wait-
 wait:	jzx 0, 14, SPR_RXE_0x1a, 0, wait-
	/* If the received frame is too big, we drop it. */
	mov (MAX_IEEE80211_FRAME_LEN + PLCP_HDR_LEN), Ra
	jg SPR_RXE_FRAMELEN, Ra, drop_received_frame

	/* RX header setup */
	mov SPR_RXE_FRAMELEN, [SHM_RXHDR_FRAMELEN]
	mov SPR_RXE_PHYRXSTAT0, [SHM_RXHDR_PHYSTAT0]
	mov SPR_RXE_PHYRXSTAT1, [SHM_RXHDR_PHYSTAT1]
	mov SPR_RXE_PHYRXSTAT2, [SHM_RXHDR_PHYSTAT2]
	mov SPR_RXE_PHYRXSTAT3, [SHM_RXHDR_PHYSTAT3]
	mov [SHM_RX_TSF0], [SHM_RXHDR_TIME]
	mov 0x008, Ra
	call lr0, phy_read
	sl Ra, 2, Ra
	or Ra, [SHM_PHYTYPE], [SHM_RXHDR_CHAN]

	call lr0, put_rx_frame_into_fifo
	jne Ra, 0, rx_fifo_overflow

	and SPR_RXE_FIFOCTL1, (~2), SPR_RXE_FIFOCTL1
//MARKER(11)

	jmp eventloop_idle

rx_not_ready:
	mov 0x4, SPR_RXE_FIFOCTL1
	mov SPR_RXE_FIFOCTL1, 0
	jmp eventloop_idle

drop_received_frame:
	or SPR_RXE_FIFOCTL1, 0x2, SPR_RXE_FIFOCTL1
	jmp eventloop_idle

/* --- Handler: For RX-FIFO-full conditions */
rx_fifo_overflow:
	/* TODO: If CONDREG_4 bit6 is set, we must push the frame to the host nevertheless. Why? */
	extcond_eoi_only(COND_RX_FIFOFULL)
	orx 0, 9, 1, SPR_BRC, SPR_BRC		/* Set 0x200 */

	/* fallthrough... */

/* --- Handler: Discard the received frame */
discard_rx_frame:
	or SPR_RXE_FIFOCTL1, 0x14, SPR_RXE_FIFOCTL1
	mov SPR_RXE_FIFOCTL1, 0				/* commit */
	/* TODO: Check if there's something to transmit */
	jmp eventloop_restart

/* --- Handler: RX of a frame is complete. Reset RXE. */
rx_complete_handler:
//	jext COND_4_C6, TODO Push frame to host
	extcond_eoi_only(COND_RX_COMPLETE)
	mov 0x4, SPR_RXE_FIFOCTL1
	mov SPR_RXE_FIFOCTL1, 0			/* commit */
	jmp eventloop_idle

/* --- Function: Put the received frame into the FIFO ---
 * This will also take the RX-header from SHM and put it in
 * front of the packet.
 * Link Register: lr0
 * The result is returned in Ra:
 *   Ra == 0 -> OK
 *   Ra == 1 -> Fifo overflow
 */
put_rx_frame_into_fifo:
	/* Start FIFO operation now. */
//	orx 1, 0, 1, SPR_RXE_FIFOCTL1, SPR_RXE_FIFOCTL1
//	or SPR_RXE_FIFOCTL1, (1 << SPR_RXE_FIFOCTL1_STARTCOPY), SPR_RXE_FIFOCTL1
	xor SPR_RXE_FIFOCTL1, (1 << SPR_RXE_FIFOCTL1_STARTCOPY), SPR_RXE_FIFOCTL1
/* FIXME: we sometimes loop forever here. */
 wait_fifo_start:					/* Wait until FIFO starts operating */
	jext COND_RX_FIFOFULL, overflow+
	jnext COND_RX_FIFOBUSY, wait_fifo_start-
 wait_fifo_finish:					/* Wait for FIFO to finish operation */
	jext COND_RX_FIFOFULL, overflow+
	jext COND_RX_FIFOBUSY, wait_fifo_finish-
	mov r0, r0					/* Flush the pipelines */
	je 0, 0, next+					/* Flush the pipelines */
 next:
	jext COND_RX_FIFOFULL, overflow+
	mov 0, Ra					/* return code 0 */
 out:
	ret lr0, lr0
 overflow:
	mov 1, Ra
	jmp out-

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
	POP(SPR_PC0)
	ret lr0, lr0

/* --- Function: Write to a Radio register ---
 * Link Register: lr0
 * The Radio Address is passed in Ra
 * The Data to write is passed in Rb
 */
radio_write:
	PUSH(SPR_PC0)
	jnzx 0, MACCTL_RADIOLOCK, SPR_MAC_CTLHI, 0, out+
	mov Ra, Rc	/* Rc = Radio address */
	mov Rb, Rd	/* Rd = data */
	mov 0xB, Ra	/* PHY register 0xB */
	mov Rc, Rb
	/* Assumption: phy_write_noflush doesn't clobber Rd */
	call lr0, phy_write_noflush
	mov 0xD, Ra	/* PHY register 0xD */
	mov Rd, Rb
	call lr0, phy_write_noflush
 out:
	POP(SPR_PC0)
	ret lr0, lr0

/* --- Function: Lowlevel panic helper --- 
 * Link Register: Doesn't matter. This won't return anyway.
 * The Panic reason is passed in R_PANIC_REASON
 */
__panic:
	/* We can read R_PANIC_REASON from the kernel. */
	DEBUGIRQ_THROW(DEBUGIRQ_PANIC)
 self:	jmp self-

/* --- Function: Trigger a debug IRQ ---
 * Link Register: lr0
 * The IRQ reason is passed in R_DEBUGIRQ_REASON
 * This busywaits for the ACK from the kernel.
 */
#if DEBUG
debug_irq:
	mov IRQHI_DEBUG, SPR_MAC_IRQHI;		/* Trigger the IRQ. */
wait:	jne R_DEBUGIRQ_REASON, DEBUGIRQ_ACK, wait- /* Wait for kernel to respond. */
	ret_after_jmp lr0, lr0
#endif /* DEBUG */

#include "../common/stack.asm"
#include "initvals.asm"

// vim: syntax=b43 ts=8
