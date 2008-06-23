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
#include "../common/ieee80211.inc"


/* Policy decisions:
 *
 *	HANDLERS:
 * Handlers are pieces of code that are jumped to from the main
 * eventloop context. They are _not_ called and also _not_ jumped to
 * from a function. Handlers don't need to save registers, except
 * if it needs caller-save registers before and after a subfunction call.
 * Handlers are prefixed with h_
 *
 *	FUNCTIONS:
 * Functions are called. Usually with link register 0.
 * If a function makes a subfunction call, it must save the link register.
 * It must also make sure to adhere to the GPR caller/callee save rules.
 */


/* RET can't be used right after a jump instruction. Use this, if
 * you need to return right after a jump.
 * This will add a no-op before the ret. */
#define ret_after_jmp	mov r0, r0 ; ret

/* Flush a Special Purpose Register write and any cache and pipeline. */
#define flush_spr_write_cache(reg)		\
	mov reg, 0;				\
	jl 0, 1, __next_insn+;			\
   __next_insn:;

/* Flush any cache and pipeline */
#define flush_cache	flush_spr_write_cache(r0)

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

	mov SHM_STACK_START, BASER_STACKPTR

	/* Initialize the hardware */
	mov 0, SPR_GPIO_OUT			/* Disable any GPIO pin */
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
	mov (1 << GPT_STAT_8MHZ), SPR_TSF_GPT0_STAT	/* GP Timer 0: 8MHz */
	mov lo16(280000), SPR_TSF_GPT0_CNTLO		/* GP Timer 0: Counter = 280,000 */
	mov hi16(280000), SPR_TSF_GPT0_CNTHI

/* -- The MAC suspend loop -- */
mac_suspend_now:
	mov SHM_UCODESTAT_SUSP, [SHM_UCODESTAT]
	mov IRQLO_MAC_SUSPENDED, SPR_MAC_IRQLO
	orx 0, GPT_STAT_EN, 0, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GP Timer 0: disable */
 self:	jnext COND_MACEN, self-

	mov SHM_UCODESTAT_ACTIVE, [SHM_UCODESTAT]
	mov 0, SPR_BRC
	mov 0xFFFF, SPR_BRCL0
	mov 0xFFFF, SPR_BRCL1
	mov 0xFFFF, SPR_BRCL2
	mov 0xFFFF, SPR_BRCL3
	or SPR_RXE_FIFOCTL1, 0x0004, SPR_RXE_FIFOCTL1
 self:	jnzx 0, 2, SPR_RXE_FIFOCTL1, 0, self-	/* Wait for 0x4 to clear */
	orx 0, GPT_STAT_EN, 1, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GP Timer 0: Start */
	mov 0, SPR_BRCL0
	mov 0, SPR_BRCL1
	mov 0, SPR_BRCL2
	mov 0, SPR_BRCL3
	/* TODO: setup TX status and PMQ discarding (MACCTL hi) */
	mov 0x7360, SPR_BRWK0
	mov 0x0000, SPR_BRWK1
	mov 0x730F, SPR_BRWK2
	mov 0x0057, SPR_BRWK3

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
//FIXME	call lr0, update_gphy_classify_ctl	/* Classify ctrl from SHM to PHY */
	mov lo16(280000), SPR_TSF_GPT0_VALLO	/* GP Timer 0: Value = 280,000 */
	mov hi16(280000), SPR_TSF_GPT0_VALHI
	orx 1, 14, 0x3, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT /* GPT0: Start and 8MHz */
	jnext COND_MACEN, h_might_suspend_mac	/* Driver disabled MAC. Check if we can sleep. */

	jnext COND_TX_FLUSH, no_txflush+
	MARKER(0) /* TODO: handle TX flush request */
 no_txflush:

	/* Check if there's some real work to be done. */
check_events:
	jext EOI(COND_TX_NOW), h_transmit_frame
	jext EOI(COND_TX_POWER), h_tx_power_updates
	jext EOI(COND_TX_UNDERFLOW), h_tx_underflow
	jext COND_TX_DONE, h_tx_done
	jext COND_TX_PHYERR, h_phy_tx_error
	jnzx 3, 1, SPR_BRWK0, 0, h_ifs_updates
 ifs_updates_not_needed:
	jext EOI(COND_RX_WME8), h_tx_timers_setup
	jext EOI(COND_RX_PLCP), h_received_valid_plcp
	jext COND_RX_COMPLETE, h_rx_complete_handler
	jext COND_TX_PMQ, h_pmq_updates
	jext EOI(COND_RX_BADPLCP), h_received_bad_plcp
	jnext COND_RX_FIFOFULL, no_overflow+
	jnext COND_4_C6, h_rx_fifo_overflow
 no_overflow:
	jnzx 0, RXE_0x1a_OVERFLOW, SPR_RXE_0x1a, 0, h_rx_fifo_overflow

	jext EOI(COND_TX_NAV), h_nav_update
	jnext COND_4_C7, h_channel_setup
	extcond_eoi_only(COND_PHY6)

	/* OK, all done. Go idle for a while... */

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

/* --- Handler: Check if we can suspend now. --- */
h_might_suspend_mac:
	jnand SPR_BRC, 0xE2, check_events	/* Cannot sleep now. There's work to do. */
	jext COND_TX_PHYERR, check_events	/* First need to handle the PHY error */
	call lr0, tx_engine_stop
	jext EOI(COND_TX_NOW), h_transmit_frame	/* Transmit pending. Cannot sleep. */
	jmp mac_suspend_now

/* --- Function: Stop the TX engine. ---
 * This stops the TXE, but also checks first if there's TX work
 * to do. In case there's work to do it will interrupt and return early!
 * So check (and possibly EOI) the TX_NOW condition after calling this.
 * Link Register: lr0
 */
tx_engine_stop:
	mov (1 << TXE_CTL_FCS), SPR_TXE0_CTL
	flush_spr_write_cache(SPR_TXE0_CTL)
	jext COND_TX_NOW, out+
	and SPR_BRC, (~0x27), SPR_BRC
	mov 0, SPR_TXE0_SELECT
	orx 0, 15, 0, SPR_TXE0_TIMEOUT, SPR_TXE0_TIMEOUT /* clear bit 15 */
	and SPR_BRC, (~BIT(BRC_TXMOREFRAGS)), SPR_BRC /* no more frags */
	jzx 0, FLG0_EOI_TXECOND, R_FLAGS0, 0, no_clear_conditions+
 wait:	jnext EOI(COND_TX_POWER), wait- /* Wait to trigger once */
	extcond_eoi_only(COND_TX_UNDERFLOW)
 no_clear_conditions:
	jnzx 0, 9, SPR_WEP_CTL, 0, no_reset_crypto+ /* test 0x200 */
	mov 0x200, SPR_WEP_CTL
 no_reset_crypto:
	and R_FLAGS0, (~(1 << FLG0_EOI_TXECOND)), R_FLAGS0 /* FIXME: also clear another flag */
 out:
	ret lr0, lr0

/* --- Function: Set GPHY classify control to OFDM-only
 * Link Register: lr0
 */
gphy_classify_ctl_ofdm:
	PUSH_LR0
	and [SHM_GCLASSCTL], (~(1 << GPHY_CLASSCTL_CCK)), Rb
	jmp _write_gclassctl

/* --- Function: Update the GPHY classify control value from SHM.
 * Link Register: lr0
 */
update_gphy_classify_ctl:
	PUSH_LR0
	mov [SHM_GCLASSCTL], Rb
 _write_gclassctl: /* jump from gphy_classify_ctl_ofdm() */
	jne [SHM_PHYTYPE], PHYTYPE_G, out+
	mov GPHY_CLASSCTL, Ra
	call lr0, phy_write
 out:
	POP_LR0
	ret lr0, lr0

/* --- Handler: Do some channel setup --- */
h_channel_setup:
	call lr0, create_bg_noise_sample
	call lr0, cca_indication_check
	jext COND_4_C4, skip_beacon_updates+
	jext COND_TX_TBTTEXPIRE, h_beacon_tbtt_updates
	/* Tell the Bluetooth device that it can transmit now. */
	mov 0, Ra
	call lr0, bluetooth_notify
	js (MACCMD_BEAC0 | MACCMD_BEAC1), SPR_MAC_CMD, h_flag_bcn_tmpl_update
 skip_beacon_updates:
	jext EOI(COND_RX_ATIMWINEND), h_atim_win_end
	jzx 0, TXE_CTL_ENABLED, SPR_TXE0_CTL, 0, h_tx_engine_may_start
	//TODO
	jmp eventloop_restart

/* --- Handler: A transmission may start now. First stage of TX engine setup. */
h_tx_engine_may_start:
 wait:	jext EOI(COND_PHY6), wait-		/* Wait for the condition to clear */
	jnand SPR_BRC, (BIT(BRC_TXMOREFRAGS) | 0xF), eventloop_idle	/* No transmission pending */

	call lr0, bluetooth_is_transmitting	/* Check if BT is transmitting */
	jne Ra, 0, out_disable+			/* Bail out and disable TX */

	srx 6, 3, SPR_IFS_0x0c, 0, Ra
	jle Ra, 3, eventloop_idle		/* Not yet */
	jnzx 0, TXE_STATUS_BUSY, SPR_TXE0_STATUS, 0, eventloop_idle /* Not yet, TXE is busy. */

	jzx 0, SHM_HF_LO_EDCF, [SHM_HF_LO], 0, no_edcf+
	jnzx 0, 15, SPR_IFS_0x0c, 0, no_edcf+
	/* prepare EDCF */
jmp no_edcf+//FIXME
	and SPR_TXE0_FIFO_RDY, (BIT(FIFO_BK) | (BIT(FIFO_BE) | (BIT(FIFO_VI) | BIT(FIFO_VO)))), Ra
	je Ra, 0, eventloop_idle		/* Currently no FIFO ready :( */
	je Ra, [SHM_SAVED_FIFO_RDY_QOS], eventloop_idle /* FIFO status unchanged */
	call lr0, update_qos_avail
	//TODO
	jmp load_txhdr+
 no_edcf:
	/* EDCF disabled. Use Best-Effort FIFO */
	jzx 0, FIFO_BE, SPR_TXE0_FIFO_RDY, 0, eventloop_idle /* FIFO not ready */
	mov (FIFO_BE << CUR_TXFIFO_SHIFT), Ra
	je [SHM_CUR_TXFIFO], Ra, eventloop_idle /* OK, already using it */
	call lr0, tx_engine_stop
	jext EOI(COND_TX_NOW), h_transmit_frame
	mov (FIFO_BE << CUR_TXFIFO_SHIFT), [SHM_CUR_TXFIFO] /* We're using this FIFO */

 load_txhdr:
	/* OK, we decided on which FIFO to use. Now load the header data and pointer */
	call lr0, load_txhdr_to_shm

	/* This will start the TX engine and make the TX-now condition trigger. */
	or SPR_TXE0_CTL, (1 << TXE_CTL_ENABLED), SPR_TXE0_CTL

	jmp eventloop_restart

 out_disable:
	and SPR_TXE0_CTL, (~(1 << TXE_CTL_ENABLED)), SPR_TXE0_CTL
	jmp eventloop_idle

/* --- Handler: Do some beacon and TBTT related updates --- */
h_beacon_tbtt_updates:
//	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: Tell the kernel driver that it's safe to update the beacon --- */
h_flag_bcn_tmpl_update:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: Signal ATIM window end --- */
h_atim_win_end:
	MARKER(0)
	//TODO
	jmp eventloop_restart

/* --- Handler: PMQ updates? --- */
h_pmq_updates:
	//TODO
	MARKER(0)
	jmp eventloop_restart

/* --- Handler: Transmit the next frame on the current FIFO ---
 * TX header and pointer to it is already loaded.
 */
h_transmit_frame:
	/* First apply the 4318 TSSI workaround */
	jzx 0, SHM_HF_MI_4318TSSI, [SHM_HF_MI], 0, no_4318tssi_workaround+
	mov GPHY_ANAOVER, Ra
	mov 8, Rb
	call lr0, phy_write
 no_4318tssi_workaround:

	/* Tell the Bluetooth device that we're going to transmit, soon. */
	mov 1, Ra
	call lr0, bluetooth_notify

	/* Update WME parameters */
	jzx 0, SHM_HF_LO_EDCF, [SHM_HF_LO], 0, no_wme+
	//TODO
 no_wme:

	/* Apply the TSSI-reset workaround */
	jzx 0, SHM_HF_LO_TSSIRPSMW, [SHM_HF_LO], 0, no_tssireset_workaround+
	mov R2050_TXCTL0, Ra
	mov 0x11, Rb
	call lr0, radio_write
 no_tssireset_workaround:

	mov 0, SPR_TXE0_WM0
	mov 0, SPR_TXE0_WM1
	and SPR_BRC, (~0x180), SPR_BRC

	/* Disable hardwarecrypto */
	mov 0x8300, SPR_WEP_CTL
	/* Stop RX */
	mov (1 << RXE_FIFOCTL1_SUSPEND), SPR_RXE_FIFOCTL1

	or SPR_BRC, 0x20, SPR_BRC
	or SPR_IFS_CTL, 0x10, SPR_IFS_CTL
	and SPR_BRWK0, (~0x6), SPR_BRWK0

	jext COND_NEED_RESPONSEFR, h_transmit_responseframe
	jext COND_NEED_BEACON, h_transmit_beaconframe

	/* We transmit a normal data frame from the current FIFO */

	/* fallthrough... */

/* --- Handler: Trigger the transmission. ---
 * This will start the TX engine and push the data to the PHY. */
h_trigger_transmission:
	/* Set the generate-FCS bit */
	srx 0, TXHDR_MACLO_DFCS, [TXHDR_MACLO, OFFR_TXHDR], 0, Ra
	xor Ra, 1, Ra /* flip */
	orx 0, TXE_CTL_FCS, Ra, SPR_TXE0_CTL, SPR_TXE0_CTL

	call lr0, load_txhdr_to_shm
	/* The TXE-FIFO will point to the RTS frame now */

	/* FIXME: Send SELFCTS or RTS if needed */

	/* Discard the RTS or CTS-to-self frame */
	mov [SHM_CUR_TXFIFO], SPR_TXE0_SELECT
	mov 24, SPR_TXE0_TX_COUNT
	or (TXE_SELECT_DST_DISCARD | BIT(TXE_SELECT_USE_TXCNT)), [SHM_CUR_TXFIFO], SPR_TXE0_SELECT

	mov 0x100, SPR_WEP_CTL
	mov [TXHDR_PHYCTL, OFFR_TXHDR], SPR_TXE0_PHY_CTL

	/* Transmit the frame */
	mov [SHM_CUR_TXFIFO], SPR_TXE0_SELECT
	or (TXE_SELECT_DST_PHY | 0x20), [SHM_CUR_TXFIFO], SPR_TXE0_SELECT

	/* Wait for the packet to hit the PHY */
	add SPR_TSF_WORD0, 16, Ra	/* OFDM PHY delay is 16 microseconds */
	je [SHM_PHYTYPE], PHYTYPE_A, is_ofdm+
	jnzx 1, 0, [TXHDR_PHYCTL, OFFR_TXHDR], 0, is_ofdm+
	add SPR_TSF_WORD0, 40, Ra	/* CCK PHY delay is 40 microseconds */
 is_ofdm:
 wait:	jext COND_TX_DONE, eventloop_restart /* Oops, PHY already finished transmission. */
	jne SPR_TSF_WORD0, Ra, wait-

	//TODO measure the TSSI

	/* Revert the 4318 TSSI workaround */
	jzx 0, SHM_HF_MI_4318TSSI, [SHM_HF_MI], 0, no_4318tssi_workaround+
	mov GPHY_ANAOVER, Ra
	mov 0, Rb
	call lr0, phy_write
 no_4318tssi_workaround:

	/* Wait for some packet count. Not sure what this does... */
	jnzx 0, 11, SPR_IFS_STAT, 0, eventloop_idle
	jg SPR_NAV_0x04, 160, eventloop_idle
	mov 0xFFFF, SPR_NAV_0x04
 pkt_cnt_loop:
	mov APHY_PACKCNT, Ra
	call lr0, phy_read
	and Ra, 0x1F, Ra
	je Ra, 22, pkt_cnt_loop-
	mov 0, SPR_NAV_0x04

	jmp eventloop_idle

/* --- Handler: Transmit a beacon frame. --- */
h_transmit_beaconframe:
	//TODO
	jmp h_trigger_transmission

/* --- Handler: Transmit a rxframe-response frame. These are ACK or CTS --- */
h_transmit_responseframe:
	//TODO
	jmp h_trigger_transmission

/* --- Handler: Do some TX power radio register updates FIXME --- */
h_tx_power_updates:
	and SPR_BRC, (~0x20), SPR_BRC
	mov 0x8700, SPR_WEP_CTL

	/* Revert the TSSI-reset workaround */
	jzx 0, SHM_HF_LO_TSSIRPSMW, [SHM_HF_LO], 0, no_tssireset_workaround+
	mov R2050_TXCTL0, Ra
	mov 0x31, Rb
	call lr0, radio_write
 no_tssireset_workaround:

	jnzx 0, FCTL_MOREFRAGS, [TXHDR_FCTL, OFFR_TXHDR], 0, morefrags+
	/* This is the last fragment. Tell the hardware. */
	and SPR_BRC, (~BIT(BRC_TXMOREFRAGS)), SPR_BRC
 morefrags:

	jext EOI(COND_TX_UNDERFLOW), h_tx_underflow
	jext EOI(COND_TX_PHYERR), h_phy_tx_error

	/* Want to transmit a beacon, ACK or CTS? Hurry up. */
	jext COND_NEED_BEACON, xmit_next+
	jext COND_NEED_RESPONSEFR, xmit_next+

	jext COND_4_C7, eventloop_restart /* Some error condition */

	// TODO: If this was just the self-CTS, we need to send the real frame now.
	// Prepare the TXE for the real frame


	/* The RX FIFO or crypto engine is busy? First wait for it to finish. */
 rx_wait:
	jext EOI(COND_RX_FIFOFULL), rx_overflow+
	jext COND_RX_FIFOBUSY, rx_wait-
	jext COND_RX_CRYPTBUSY, rx_wait-
 continue_after_rxoverflow:

	jext COND_INTERMEDIATE, intermediate+
	orx 0, TXE_FIFO_CMD_TXDONE, 1, SPR_TXE0_FIFO_CMD, SPR_TXE0_FIFO_CMD

	/* Send the TX status to the kernel driver. */
	jzx 0, MACCTL_DISCTXSTAT, SPR_MAC_CTLHI, 0, no_txstat+
	mov 0, SPR_TX_STATUS3 // FIXME PHY TX status
	mov 0, SPR_TX_STATUS2 // FIXME seq number
	mov [TXHDR_COOKIE, OFFR_TXHDR], SPR_TX_STATUS1
	or 0, 1, SPR_TX_STATUS0 //FIXME MAC status
 no_txstat:

	orx 0, 11, 0, SPR_BRC, SPR_BRC /* clear 0x800 */
	mov 0xFFFF, [SHM_CUR_TXFIFO] /* invalid */

	jmp eventloop_restart
 xmit_next:
	and SPR_BRC, (~0x3), SPR_BRC
	jmp eventloop_restart
 rx_overflow:
	/* Whoopsy, TX took too long and we overflew the RX fifo */
	//TODO
	jmp continue_after_rxoverflow-
 intermediate:
	MARKER(0)
	//TODO
	jmp eventloop_restart

/* --- Handler: TX data underflow --- */
h_tx_underflow:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: The PHY completely transmitted the current transmission --- */
h_tx_done:
	//TODO
	jext EOI(COND_TX_DONE), eventloop_idle
	//XXX This will probably never trigger
	MARKER(0)
	jmp eventloop_idle

/* --- Handler: Do some NAV and slot updates --- */
h_nav_update:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: Do some Inter Frame Space related updates --- */
h_ifs_updates:
	jext COND_RX_IFS2, do_ifs_updates+
	jnext COND_RX_IFS1, ifs_updates_not_needed	/* Return to eventloop */
 do_ifs_updates:
	and SPR_BRWK0, (~0x6), SPR_BRWK0
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: The PHY threw an error --- */
h_phy_tx_error:
	MARKER(0)
	//TODO
	jmp eventloop_idle

/* --- Handler: Setup and start the TX related timers --- */
h_tx_timers_setup:
	jzx 0, 8, SPR_BRPO0, 0, transmit_timers_prepare	/* Check 0x100 */
	and SPR_BRPO0, (~0x100), SPR_BRPO0
	orx 0, GPT_STAT_EN, 1, SPR_TSF_GPT0_STAT, SPR_TSF_GPT0_STAT  /* Enable GPT0 */
	jmp eventloop_idle

transmit_timers_prepare:
	jnzx 0, 11, SPR_IFS_STAT, 0, no_brpo0+		/* Check 0x800 */
	or SPR_BRPO0, 0x100, SPR_BRPO0
	//TODO setup 2050 radio txctl
 no_brpo0:
	mov (1 << GPT_STAT_8MHZ), SPR_TSF_GPT2_STAT
	jmp eventloop_restart

/* --- Handler: We received a PLCP */
h_received_valid_plcp:
 wait:	jext EOI(COND_RX_FCS_GOOD), wait-		/* Clear the FCS-good cond from previous frames */
	jnzx 0, 2, SPR_RXE_FIFOCTL1, 0, eventloop_idle	/* No packet available */
 tsf_again:
	mov SPR_TSF_WORD0, [SHM_RX_TSF0]		/* Read the TSF timestamp for the received frame */
	mov SPR_TSF_WORD1, [SHM_RX_TSF1]
	mov SPR_TSF_WORD2, [SHM_RX_TSF2]
	mov SPR_TSF_WORD3, [SHM_RX_TSF3]
	jl SPR_TSF_WORD0, [SHM_RX_TSF0], tsf_again-	/* word0 overflow */
	jzx 0, TXE_CTL_ENABLED, SPR_TXE0_CTL, 0, txengine_ok+
	mov 0, SPR_TXE0_CTL				/* Disable the TX engine */
	and SPR_BRC, (~0x7), SPR_BRC
 txengine_ok:
	or SPR_BRC, 0x140, SPR_BRC
	orx 0, 9, 1, SPR_BRC, SPR_BRC			/* SPR_BRC |= 0x200 */
	jext COND_RX_FIFOFULL, h_rx_fifo_overflow
	jnzx 0, RXE_0x1a_OVERFLOW, SPR_RXE_0x1a, 0, h_rx_fifo_overflow
	/* Wait for the IEEE 802.11 header to arrive in SHM. */
 rx_headerwait:
	jext COND_RX_COMPLETE, rx_complete+
	jl SPR_RXE_FRAMELEN, SHM_RXFRAME_HDR_LEN, rx_headerwait-
 rx_complete:
	jl SPR_RXE_FRAMELEN, (MIN_IEEE80211_FRAME_LEN + PLCP_HDR_LEN), drop_received_frame

	/* Start with no MAC status bit set. We will OR the bits as needed. */
	mov 0, [SHM_RXHDR_MACSTAT0]
	mov 0, [SHM_RXHDR_MACSTAT1]

	/* Header sanity checks */
	jnzx 0, MACCTL_KEEP_BAD, SPR_MAC_CTLHI, 0, no_hdr_sanity_chk+
	/* Version != 0 -> Drop */
	jnzx FCTL_VERS_M, FCTL_VERS_S, [(SHM_RXFRAME_HDR + FCTL_WOFFSET)], 0, drop_received_frame
 no_hdr_sanity_chk:

	/* Put the frametype into Ri */
	srx FCTL_FTYPE_M, FCTL_FTYPE_S, [(SHM_RXFRAME_HDR + FCTL_WOFFSET)], 0, Ri
	/* Put the framesubtype into Rj */
	srx FCTL_STYPE_M, FCTL_STYPE_S, [(SHM_RXFRAME_HDR + FCTL_WOFFSET)], 0, Rj

	and R_FLAGS0, (~(1 << FLG0_RXFRAME_WDS)), R_FLAGS0
	jzx 0, FCTL_TODS, [(SHM_RXFRAME_HDR + FCTL_WOFFSET)], 0, no_wds+
	jzx 0, FCTL_FROMDS, [(SHM_RXFRAME_HDR + FCTL_WOFFSET)], 0, no_wds+
	/* This is a WDS frame */
	or R_FLAGS0, (1 << FLG0_RXFRAME_WDS), R_FLAGS0
 no_wds:

	/* Set the "is-QoS-frame" indicator bit */
	srx 0, STYPE_QOS_BIT, Rj, 0, Ra			/* FCTL stype QoS bit lookup */
	je Ri, FTYPE_DATA, is_data+			/* Is this a data frame? */
	mov 0, Ra					/* No. So can't be QoS data, too */
 is_data:
	orx 0, FLG0_RXFRAME_WDS, Ra, R_FLAGS0, R_FLAGS0	/* Set or clear flag */

	/* Setup the RX FIFO data padding to align the IP header. */
	/* Ra is still set to the QoS indicator */
	srx 0, FLG0_RXFRAME_WDS, R_FLAGS0, 0, Rb
	xor Ra, Rb, Ra					/* Need padding if (QoS ^ WDS) */
	/* Tell the FIFO engine whether we want padding or not. */
	orx 0, RXE_FIFOCTL1_HAVEPAD, Ra, SPR_RXE_FIFOCTL1, SPR_RXE_FIFOCTL1
	/* Also set the MAC status bit to tell the driver about the padding. */
	orx 0, MACSTAT0_PADDING, Ra, [SHM_RXHDR_MACSTAT0], [SHM_RXHDR_MACSTAT0]

	/* Update the Network Allocation Vector */
	jext COND_RX_RAMATCH, no_dur_write+
	jnzx 0, DURID_CFP, [(SHM_RXFRAME_HDR + DURID_WOFFSET)], 0, no_dur_write+
	mov [(SHM_RXFRAME_HDR + DURID_WOFFSET)], SPR_NAV_ALLOCATION
	orx 4, 11, 0x2, SPR_NAV_CTL, SPR_NAV_CTL
 no_dur_write:

	/* TODO: Init hardware crypto engine, if the packet is protected. */
	mov 0x8300, SPR_WEP_CTL				/* Disable crypto */
	or SPR_RXE_FIFOCTL1, 0x2, SPR_RXE_FIFOCTL1
	and SPR_BRC, (~0x40), SPR_BRC

	/* Wait for the frame receive to complete. */
 wait:	jnext COND_RX_COMPLETE, wait-
 wait:	jzx 0, 14, SPR_RXE_0x1a, 0, wait-
	/* If the received frame is too big, we drop it. */
	mov (MAX_IEEE80211_FRAME_LEN + PLCP_HDR_LEN), Ra
	jg SPR_RXE_FRAMELEN, Ra, drop_received_frame

	/* Check if we are the receiver */
	jnzx 0, MACCTL_PROMISC, SPR_MAC_CTLHI, 0, frame_is_for_us+
	jnzx 0, ADDR_MCAST_BIT, [(SHM_RXFRAME_HDR + ADDR1_WOFFSET)], 0, frame_is_for_us+
	jnext COND_RX_RAMATCH, drop_received_frame
 frame_is_for_us:

	/* RX header setup */
	mov SPR_RXE_FRAMELEN, [SHM_RXHDR_FRAMELEN]
	mov SPR_RXE_PHYRXSTAT0, [SHM_RXHDR_PHYSTAT0]
	mov SPR_RXE_PHYRXSTAT1, [SHM_RXHDR_PHYSTAT1]
	mov SPR_RXE_PHYRXSTAT2, [SHM_RXHDR_PHYSTAT2]
	mov SPR_RXE_PHYRXSTAT3, [SHM_RXHDR_PHYSTAT3]
	mov [SHM_RX_TSF0], [SHM_RXHDR_TIME]
	mov BPHY_CHANINFO, Ra
	call lr0, phy_read
	sl Ra, 3, Ra
	or Ra, [SHM_PHYTYPE], [SHM_RXHDR_CHAN]

	/* Check the FCS */
	jext COND_RX_FCS_GOOD, fcs_ok+
	or [SHM_RXHDR_MACSTAT0], (1 << MACSTAT0_FCSERR), [SHM_RXHDR_MACSTAT0]
 fcs_ok:
	jnzx 0, MACCTL_KEEP_BAD, SPR_MAC_CTLHI, 0, no_drop_bad+
	jnext COND_RX_FCS_GOOD, drop_received_frame
 no_drop_bad:

	call lr0, put_rx_frame_into_fifo
	jne Ra, 0, h_rx_fifo_overflow

	and SPR_RXE_FIFOCTL1, (~2), SPR_RXE_FIFOCTL1

	jmp eventloop_idle

/* Wait for the RX to complete and then drop the frame. */
drop_received_frame:
 wait:	jnext EOI(COND_RX_COMPLETE), wait-
	jmp h_discard_rx_frame

/* --- Handler: We received a PLCP (corrupt checksum) */
h_received_bad_plcp:
 wait:
	jnzx 0, 11, SPR_RXE_0x1a, 0, eventloop_idle	/* Wasn't a PLCP */
	jnzx 0, 12, SPR_RXE_0x1a, 0, wait-		/* Wait for the RX to complete */
	//TODO: If we want to keep bad plcp frames, push it to host
	jext COND_RX_FIFOFULL, h_rx_fifo_overflow
	jnzx 0, RXE_0x1a_OVERFLOW, SPR_RXE_0x1a, 0, h_rx_fifo_overflow
	extcond_eoi_only(COND_RX_FIFOFULL)
	jmp h_discard_rx_frame

/* --- Handler: For RX-FIFO-full conditions */
h_rx_fifo_overflow:
	/* TODO: If CONDREG_4 bit6 is set, we must push the frame to the host nevertheless. Why? */
	extcond_eoi_only(COND_RX_FIFOFULL)
	orx 0, 9, 1, SPR_BRC, SPR_BRC		/* Set 0x200 */

	/* fallthrough... */

/* --- Handler: Discard the received frame */
h_discard_rx_frame:
	or SPR_RXE_FIFOCTL1, 0x14, SPR_RXE_FIFOCTL1
	mov SPR_RXE_FIFOCTL1, 0				/* commit */
	/* TODO: Check if there's something to transmit */
	jmp eventloop_restart

/* --- Handler: RX of a frame is complete. Reset RXE. */
h_rx_complete_handler:
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
 *   Ra == 1 -> FIFO overflow
 */
put_rx_frame_into_fifo:
	mov SHM_RXHDR, SPR_RXE_RXHDR_OFFSET
	mov SHM_RXHDR_SIZE, SPR_RXE_RXHDR_LEN
	/* Start FIFO operation now. */
	or SPR_RXE_FIFOCTL1, (1 << RXE_FIFOCTL1_STARTCOPY), SPR_RXE_FIFOCTL1
 wait_fifo_start:					/* Wait until FIFO starts operating */
	jext COND_RX_FIFOFULL, overflow+
	jnext COND_RX_FIFOBUSY, wait_fifo_start-
 wait_fifo_finish:					/* Wait for FIFO to finish operation */
	jext COND_RX_FIFOFULL, overflow+
	jext COND_RX_FIFOBUSY, wait_fifo_finish-
	flush_cache					/* Flush the pipelines */
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
	jnzx 0, MACCTL_GMODE, SPR_MAC_CTLHI, 0, is_gmode+
	/* In non-GMode we must clear the OFDM (A-PHY) routing bit. */
	orx 0, 10, 0, Ra, Ra
 is_gmode:
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
	jnzx 0, MACCTL_GMODE, SPR_MAC_CTLHI, 0, is_gmode+
	/* In non-GMode we must clear the OFDM (A-PHY) routing bit. */
	orx 0, 10, 0, Ra, Ra
 is_gmode:
 busy:	jnzx 0, 14, SPR_Ext_IHR_Address, 0, busy-
	mov Rb, SPR_Ext_IHR_Data
	orx 0, 13, 1, Ra, SPR_Ext_IHR_Address
 busy:	jnzx 0, 13, SPR_Ext_IHR_Address, 0, busy-
	ret_after_jmp lr0, lr0

/* --- Function: Write to a PHY register. Don't flush ---
 * Link Register: lr0
 * The PHY address is passed in Ra.
 * Note that the OFDM-routing bit is NOT adjusted!
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
	PUSH_LR0
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
	POP_LR0
	ret lr0, lr0

/* --- Function: Write to a Radio register ---
 * Link Register: lr0
 * The Radio Address is passed in Ra
 * The Data to write is passed in Rb
 */
radio_write:
	PUSH_LR0
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
	POP_LR0
	ret lr0, lr0

/* --- Function: Create another background noise sample and put it into SHM ---
 * Link Register: lr0
 * This function takes no parameters and returns nothing.
 */
create_bg_noise_sample:
	PUSH_LR0
	PUSH(Ri)
	PUSH(Rj)
	jzx 0, MACCMD_BGNOISE, SPR_MAC_CMD, 0, out+
	jnzx 0, BGN_INPROGRESS, [SHM_BGN_STATUS], 0, already_running+
	orx 0, BGN_INPROGRESS, 1, [SHM_BGN_STATUS], [SHM_BGN_STATUS] /* set */
	/* The noise sample generation just started. Save the time
	 * so we can later check how long this took. Save word 1. That
	 * means every increment is about 66 milliseconds. */
	mov SPR_TSF_WORD0, 0 /* First need to read word 0 */
	mov SPR_TSF_WORD1, [SHM_BGN_START_TSF1]
 already_running:
	/* Check how long the noise sample generation was already running. */
	add [SHM_BGN_START_TSF1], 2, Ra /* Ra = StartTime + about 131 mSec */
	mov SPR_TSF_WORD0, 0 /* First need to read word 0 */
	sub SPR_TSF_WORD1, Ra, Ra /* Ra = NOW - (StartTime + 131 mS) */
	mov 0, Ri
	jls Ra, 0, no_timeout+
	/* The noise sample calculation took more than 131 milliseconds.
	 * We check Ri later in the busyloops to shorten the calculations. */
	mov 1, Ri
 no_timeout:
 	/* Read channel info and put it into the lower 8bit of SHM_JSSIAUX */
	mov BPHY_CHANINFO, Ra
	call lr0, phy_read
	and Ra, 0xFF, [SHM_JSSIAUX]
	/* Get packet count and put it into the upper 8bit of SHM_JSSIAUX */
	mov APHY_PACKCNT, Ra
	call lr0, phy_read
	orx 7, 8, Ra, [SHM_JSSIAUX], [SHM_JSSIAUX]
	// TODO: Setup A-PHY registers, if we are on an A-PHY

	mov 0, Rj /* Measurement counter */
 bgn_measure_loop:
	/* Wait for the channel to calm down so we only measure the noise.
	 * We wait for 2 microseconds. */
	add SPR_TSF_WORD0, 2, Ra
 wait_calmdown:
	jzx 0, 11, SPR_IFS_STAT, 0, ifs_0x800_not_set+
	/* If we still have some time left, cancel this round and
	 * redo the measurement later. */
	je Ri, 0, out_restore+
 ifs_0x800_not_set:
	/* Transmission pending. Redo measurement later. */
	jext COND_TX_NOW, out_restore+
	jne SPR_TSF_WORD0, Ra, wait_calmdown- //FIXME we should check for NOW = Ra or later here. Not trivial with wrapping.

	/* OK, channel is empty. Read the JSSI. It will represent the channel
	 * noise now. */
	mov BPHY_JSSI, Ra
	call lr0, phy_read
	srx 0, 1, Rj, 0, Rb /* bit 1 of the counter decides whether to put JSSI0 or JSSI1 */
	add Rb, SHM_JSSI0, SPR_BASE0
	/* bit 0 of the counter decides whether to put into low or high 8bits */
	jzx 0, 0, Rj, 0, low+
	orx 7, 8, Ra, [0, off0], [0, off0] /* Put into high byte */
	jmp no_low+
 low:
	orx 7, 0, Ra, [0, off0], [0, off0] /* Put into low byte */
 no_low:

	add Rj, 1, Rj /* Increment the counter */
	jne Rj, 4, bgn_measure_loop- /* Do it 4 times */

	/* OK, done. Got the 4 samples. If we took less than 131 mS of time
	 * for the whole thing, we wait an additional grace period to make
	 * sure the channel really was quiet while measuring. */
	je Ri, 1, bgn_measure_done+
	add SPR_TSF_WORD0, 24, Ra
 bgn_grace_period:
	jext COND_TX_NOW, out_restore+ /* Damn..., redo it later */
	jnzx 0, 11, SPR_IFS_STAT, 0, out_restore+ /* Retry later */
	jne SPR_TSF_WORD0, Ra, bgn_grace_period- //FIXME we should check for NOW = Ra or later here. Not trivial with wrapping.
 bgn_measure_done:

	/* Tell the kernel driver that 4 fresh noise samples are available */
	mov (1 << MACCMD_BGNOISE), SPR_MAC_CMD /* write clears bit */
	orx 0, BGN_INPROGRESS, 0, [SHM_BGN_STATUS], [SHM_BGN_STATUS] /* clear */
	mov IRQHI_NOISESAMPLE_OK, SPR_MAC_IRQHI /* send interrupt */

 out_restore:
	// TODO: Restore the A-PHY registers
 out:
	POP(Rj)
	POP(Ri)
	POP_LR0
	ret lr0, lr0

/* --- Function: PHY Clear Channel Assessment indication
 * As specified by IEEE 802.11-2007 12.3.5.10
 * The function is supposed to get called frequently. It will
 * trigger the CCA interrupt when the CCA indicates an idle channel.
 * Link Register: lr0
 */
cca_indication_check:
	jzx 0, MACCMD_CCA, SPR_MAC_CMD, 0, out+ /* CCA was not requested. */
	/* TODO: Check whether the channel was empty for some
	 * time and trigger the CCA interrupt */
	MARKER(0)
	mov (1 << MACCMD_CCA), SPR_MAC_CMD
 out:
	ret lr0, lr0

/* --- Function: Load current TX header into SHM
 * This will make OFFR_TXHDR point to the current TX header in SHM
 * and load the header data into the SHM.
 * After this has finished, the TXE-FIFO will point to the data right
 * after the TX header. That is the RTS frame PLCP. So you can continue
 * to poke with the RTS afterwards.
 * Link Register: lr0
 */
load_txhdr_to_shm:
	sr [SHM_CUR_TXFIFO], CUR_TXFIFO_SHIFT, Ra	/* Ra = current TX FIFO */
	/* Lookup the table to get a pointer to the TXHDR scratch memory */
	mov SHM_TXHDR_LT, BASER_TXHDR
	add BASER_TXHDR, Ra, BASER_TXHDR		/* Table lookup */
	mov [0, OFFR_TXHDR], BASER_TXHDR		/* OFFR_TXHDR = pointer to TXHDR-mem */

	/* Now read the TX header data from the FIFO into SHM */
	orx 0, TXE_FIFO_CMD_COPY, 1, [SHM_CUR_TXFIFO], SPR_TXE0_FIFO_CMD
	sl BASER_TXHDR, 1, SPR_TXE0_TX_SHM_ADDR		/* TXHDR scratch SHM address times two */
	mov [SHM_CUR_TXFIFO], SPR_TXE0_SELECT		/* Select the FIFO */
	mov TXHDR_NR_COPY_BYTES, SPR_TXE0_TX_COUNT	/* Number of bytes to copy */
	/* Select source and destination. This will start the operation. */
	or (TXE_SELECT_DST_SHM | BIT(TXE_SELECT_USE_TXCNT)), [SHM_CUR_TXFIFO], SPR_TXE0_SELECT
 wait:	jnext COND_TX_BUSY, wait-			/* Wait for the TXE to start */
 wait:	jext COND_TX_BUSY, wait-			/* Wait for the TXE to finish */

	ret_after_jmp lr0, lr0

/* --- Function: Check whether the Bluetooth-transmitting GPIO is asserted ---
 * This checks the GPIO-in line from the bluetooth module.
 * Returns 1 in Ra, if the BT module is transmitting.
 * Returns 0 in Ra, if the BT module is idle or receiving.
 * Link Register: lr0
 */
bluetooth_is_transmitting:
	mov 0, Ra
	jzx 0, SHM_HF_LO_BTCOEX, [SHM_HF_LO], 0, out+	/* BT coex not used */
	jnzx 0, SHM_HF_MI_BTCOEXALT, [SHM_HF_MI], 0, bt_alt_pins+
	srx 0, 7, SPR_GPIO_IN, 0, Ra
	jmp out+
 bt_alt_pins:
	srx 0, 4, SPR_GPIO_IN, 0, Ra
 out:
	ret lr0, lr0

/* --- Function: Depending on Ra, notify TX or IDLE to the BT module ---
 * Notify either "WLAN is transmitting" or "WLAN is not transmitting"
 * to the Bluetooth module. The condition is passed in Ra.
 * If Ra is 0, then WLAN-is-NOT-transmitting is notified to BT.
 * If Ra is 1, then WLAN-is-transmitting is notified to BT.
 * Link Register: lr0
 */
bluetooth_notify:
	jzx 0, SHM_HF_LO_BTCOEX, [SHM_HF_LO], 0, out+	/* BT coex not used */
	jnzx 0, SHM_HF_MI_BTCOEXALT, [SHM_HF_MI], 0, bt_alt_pins+
	orx 0, 8, Ra, SPR_GPIO_OUT, SPR_GPIO_OUT
	jmp out+
 bt_alt_pins:
	orx 0, 5, Ra, SPR_GPIO_OUT, SPR_GPIO_OUT
 out:
	ret lr0, lr0

/* --- Function: Update QoS availability ---
 * Link Register: lr0
 */
update_qos_avail:
	//TODO
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

#include "initvals.asm"

// vim: syntax=b43 ts=8
