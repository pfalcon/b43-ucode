#ifndef IEEE80211_DEFINITIONS_H_
#define IEEE80211_DEFINITIONS_H_

/* Some IEEE 802.11 definitions in this file are derived from the linux kernel
 * include/linux/ieee80211.h file and are covered by the following copyrights.
 *
 * Copyright (c) 2001-2002, SSH Communications Security Corp and Jouni Malinen
 * Copyright (c) 2002-2003, Jouni Malinen
 * Copyright (c) 2005, Devicescape Software, Inc.
 * Copyright (c) 2006, Michael Wu
 * Copyright (c) 2008, Michael Buesch
 */



/* Convert a mask number to a mask bitmask.
 * Use this to convert FOOBAR_M into a bitmask. */
#define MASK(m)			((1 << (m + 1)) - 1)
/* Convert a bit-number to a mask with that bit set (only) */
#define BIT(nr)			(1 << (nr))




/* Frame Check Sequence length; in bytes */
#define FCS_LEN			4
/* Smallest possible frame length; in bytes. */
#define MIN_IEEE80211_FRAME_LEN	(((6 + 2) + 2) + FCS_LEN)
/* Maximum possible frame length; in bytes. */
#define MAX_IEEE80211_FRAME_LEN	(2352 + FCS_LEN)
/* The PLCP header length; in bytes. */
#define PLCP_HDR_LEN		6


/* Frame control field WORD(!)-offset in the frame */
#define FCTL_WOFFSET		((PLCP_HDR_LEN + 0) / 2)
#define FCTL_VERS_M		1 /* MASK() value:	Frame header version */
#define FCTL_VERS_S		0 /* Shift:		Frame header version */
#define FCTL_FTYPE_M		1 /* MASK() value:	Frame type */
#define FCTL_FTYPE_S		2 /* Shift:		Frame type */
#define FCTL_STYPE_M		3 /* MASK() value:	Frame subtype */
#define FCTL_STYPE_S		4 /* Shift:		Frame subtype */
/* Frame control field contents */
#define FCTL_TODS		8 /* bit 8: To DS */
#define FCTL_FROMDS		9 /* bit 9: From DS */
#define FCTL_MOREFRAGS		10 /* bit 10: More frags */
#define FCTL_RETRY		11 /* bit 11: Frame retry */
#define FCTL_PM			12 /* bit 12: PM */
#define FCTL_MOREDATA		13 /* bit 13: More data */
#define FCTL_PROT		14 /* bit 14: Protected */
#define FCTL_ORDER		15 /* bit 15: Order */

/* Frame types. (rightshifted!) */
#define FTYPE_MGMT			(0x0000 >> FCTL_FTYPE_S)
#define FTYPE_CTL			(0x0004 >> FCTL_FTYPE_S)
#define FTYPE_DATA			(0x0008 >> FCTL_FTYPE_S)

/* Management frame subtypes (rightshifted!) */
#define STYPE_ASSOC_REQ			(0x0000 >> FCTL_STYPE_S)
#define STYPE_ASSOC_RESP		(0x0010 >> FCTL_STYPE_S)
#define STYPE_REASSOC_REQ		(0x0020 >> FCTL_STYPE_S)
#define STYPE_REASSOC_RESP		(0x0030 >> FCTL_STYPE_S)
#define STYPE_PROBE_REQ			(0x0040 >> FCTL_STYPE_S)
#define STYPE_PROBE_RESP		(0x0050 >> FCTL_STYPE_S)
#define STYPE_BEACON			(0x0080 >> FCTL_STYPE_S)
#define STYPE_ATIM			(0x0090 >> FCTL_STYPE_S)
#define STYPE_DISASSOC			(0x00A0 >> FCTL_STYPE_S)
#define STYPE_AUTH			(0x00B0 >> FCTL_STYPE_S)
#define STYPE_DEAUTH			(0x00C0 >> FCTL_STYPE_S)
#define STYPE_ACTION			(0x00D0 >> FCTL_STYPE_S)

/* Control frame subtypes (rightshifted!) */
#define STYPE_BACK_REQ			(0x0080 >> FCTL_STYPE_S)
#define STYPE_BACK			(0x0090 >> FCTL_STYPE_S)
#define STYPE_PSPOLL			(0x00A0 >> FCTL_STYPE_S)
#define STYPE_RTS			(0x00B0 >> FCTL_STYPE_S)
#define STYPE_CTS			(0x00C0 >> FCTL_STYPE_S)
#define STYPE_ACK			(0x00D0 >> FCTL_STYPE_S)
#define STYPE_CFEND			(0x00E0 >> FCTL_STYPE_S)
#define STYPE_CFENDACK			(0x00F0 >> FCTL_STYPE_S)

/* Data frame subtypes (rightshifted!) */
#define STYPE_DATA			(0x0000 >> FCTL_STYPE_S)
#define STYPE_DATA_CFACK		(0x0010 >> FCTL_STYPE_S)
#define STYPE_DATA_CFPOLL		(0x0020 >> FCTL_STYPE_S)
#define STYPE_DATA_CFACKPOLL		(0x0030 >> FCTL_STYPE_S)
#define STYPE_NULLFUNC			(0x0040 >> FCTL_STYPE_S)
#define STYPE_CFACK			(0x0050 >> FCTL_STYPE_S)
#define STYPE_CFPOLL			(0x0060 >> FCTL_STYPE_S)
#define STYPE_CFACKPOLL			(0x0070 >> FCTL_STYPE_S)
#define STYPE_QOS_DATA			(0x0080 >> FCTL_STYPE_S)
#define STYPE_QOS_BIT			(7 - FCTL_STYPE_S) /* QoS indicator bit */
#define STYPE_QOS_DATA_CFACK		(0x0090 >> FCTL_STYPE_S)
#define STYPE_QOS_DATA_CFPOLL		(0x00A0 >> FCTL_STYPE_S)
#define STYPE_QOS_DATA_CFACKPOLL	(0x00B0 >> FCTL_STYPE_S)
#define STYPE_QOS_NULLFUNC		(0x00C0 >> FCTL_STYPE_S)
#define STYPE_QOS_CFACK			(0x00D0 >> FCTL_STYPE_S)
#define STYPE_QOS_CFPOLL		(0x00E0 >> FCTL_STYPE_S)
#define STYPE_QOS_CFACKPOLL		(0x00F0 >> FCTL_STYPE_S)

/* Frame duration / ID field WORD(!)-offset in the frame */
#define DURID_WOFFSET		((PLCP_HDR_LEN + 2) / 2)
#define DURID_CFP		15 /* bit 15: Set if TX-by-PC & non-QoS & CFP */

/* Address 1 WORD(!)-offset in the frame */
#define ADDR1_WOFFSET		((PLCP_HDR_LEN + 4) / 2)
#define ADDR_MCAST_BIT		0 /* bit 0 indicates a multicast address */

/* Address 2 WORD(!)-offset in the frame */
#define ADDR2_WOFFSET		((PLCP_HDR_LEN + 10) / 2)

/* Address 3 WORD(!)-offset in the frame */
#define ADDR3_WOFFSET		((PLCP_HDR_LEN + 16) / 2)

/* Sequence counter WORD(!)-offset in the frame */
#define SEQCTL_WOFFSET		((PLCP_HDR_LEN + 22) / 2)

/* Address 4 WORD(!)-offset in the frame */
#define ADDR4_WOFFSET		((PLCP_HDR_LEN + 24) / 2)


#endif /* IEEE80211_DEFINITIONS_H_ */

// vim: syntax=b43 ts=8
