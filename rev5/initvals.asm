/*
 *  BCM43xx device microcode
 *  Initial values
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

#include "../common/initvals.inc"
#include "../common/shm.inc"
#include "../common/debug.inc"


.initvals(b0g0initvals5)
	/* Initialize the interrupts */
	mmio32 0, MMIO_GEN_IRQ_REASON
	mmio32 0, MMIO_GEN_IRQ_MASK
	mmio32 0x01000000, MMIO_IPFT0

	/* Receive engine */
	mmio16 SHM_RXFRAME_HDR, MMIO_RXE_RXMEM
	mmio16 SHM_RXFRAME_HDR_LEN, MMIO_RXE_RXCOPYLEN
	mmio16 1, MMIO_RXE_FIFOCTL
	mmio16 0, MMIO_RXE_FIFOCTL
	mmio16 0x14, 0x40C
	mmio16 0, MMIO_RXE_FIFOCTL

	/* Initialize PHY */
	mmio16 0, MMIO_PHY0

	/* Initialize PSM */
	mmio16 0, MMIO_PSM_BRC
	mmio16 0xE3F9, MMIO_PSM_BRED0
	mmio16 0xFDAF, MMIO_PSM_BRPO0
	mmio16 0xFFFF, MMIO_PSM_BRCL0
	mmio16 0x0000, MMIO_PSM_BRCL0
	mmio16 0x0000, MMIO_PSM_BRCL1
	mmio16 0x1ACF, MMIO_PSM_BRED2
	mmio16 0x0000, MMIO_PSM_BRCL2
	mmio16 0x0000, MMIO_PSM_BRWK2
	mmio16 0x00C7, MMIO_PSM_BRED3
	mmio16 0xFFFF, MMIO_PSM_BRPO3
	mmio16 0xFFFF, MMIO_PSM_BRCL3

	/* TSF init */
	mmio16 1, MMIO_TSF_CFP_PRETBTT
	mmio16 0xA2E9, 0x62E
	mmio16 0xB, 0x630
	mmio16 0x8004, 0x600

	/* Interframe space init */
	mmio16 0xB, MMIO_IFSCTL

	/* Transmit control init */
	mmio16 0x8000, MMIO_TCTL_FIFOCMD
	mmio16 0x0E06, MMIO_TCTL_FIFODEF
	mmio16 0x8000, MMIO_TCTL_FIFOCMD

	mmio16 0x8100, MMIO_TCTL_FIFOCMD
	mmio16 0x1B0F, MMIO_TCTL_FIFODEF
	mmio16 0x8100, MMIO_TCTL_FIFOCMD

	mmio16 0x8200, MMIO_TCTL_FIFOCMD
	mmio16 0x251C, MMIO_TCTL_FIFODEF
	mmio16 0x8200, MMIO_TCTL_FIFOCMD

	mmio16 0x8300, MMIO_TCTL_FIFOCMD
	mmio16 0x2D26, MMIO_TCTL_FIFODEF
	mmio16 0x8300, MMIO_TCTL_FIFOCMD

	mmio16 0x8400, MMIO_TCTL_FIFOCMD
	mmio16 0x2A2E, MMIO_TCTL_FIFODEF
	mmio16 0x8400, MMIO_TCTL_FIFOCMD

	mmio16 0x8500, MMIO_TCTL_FIFOCMD
	mmio16 0x3B3B, MMIO_TCTL_FIFODEF
	mmio16 0x8500, MMIO_TCTL_FIFOCMD

	/* Magic stack-end signature used to detect stack overflow. */
	shm16 MAGIC_STACK_END, HOST_SHM_SHARED, (SHM_STACK_END * 2)
	/* Key table pointer */
	shm16 SHM_KEY_TABLE_START, HOST_SHM_SHARED, (SHM_KTP * 2)
	/* Unused padding in RX header */
	shm16 0, HOST_SHM_SHARED, (SHM_RXHDR_PAD * 2)


.initvals(b0g0bsinitvals5)
	/* Interframe space init */
	mmio16 0x0B4E, 0x686
	mmio16 0x3E3E, 0x680
	mmio16 0x023E, 0x682
	mmio16 0x0212, MMIO_IFS_SLOT

	/* Network allocation vector */
	mmio16 0x3C, MMIO_NAV_CTL


.text

// vim: syntax=b43 ts=8
