#ifndef IEEE80211_DEFINITIONS_H_
#define IEEE80211_DEFINITIONS_H_


/* Convert a mask number to a mask bitmask.
 * Use this to convert FOOBAR_M into a bitmask. */
#define MASK(m)			((1 << (m + 1)) - 1)



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

/* Frame duration / ID field WORD(!)-offset in the frame */
#define DURID_WOFFSET		((PLCP_HDR_LEN + 2) / 2)
#define DURID_CFP		15 /* bit 15: Set if TX-by-PC & non-QoS & CFP */


#endif /* IEEE80211_DEFINITIONS_H_ */

// vim: syntax=b43 ts=8
