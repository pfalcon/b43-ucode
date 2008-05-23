#ifndef EXTERNAL_CONDITIONS_H_
#define EXTERNAL_CONDITIONS_H_

/* Definitions for the External Conditions */

#define EXTCOND(reg, bit)	((bit) | ((reg) << 4))


/* Wrap a condition in the EOI() wrapper to EOI it.
 * Example:	jext EOI(COND_RADAR), jump_target
 */
#define EOI(ext_condition)	((ext_condition) | 0x80)
/* Use extcond_eoi_only() to EOI a condition without jumping.
 * Example:	extcond_eoi_only(COND_RADAR)
 */
#define extcond_eoi_only(ext_condition)		\
	jext EOI(ext_condition), __next_insn+;	\
	__next_insn:;



/* RX condition register */
#define CONDREG_RX		0
#define COND_RX_FCS_GOOD	EXTCOND(CONDREG_RX, 3)		/* RX FCS good */
#define COND_RX_COMPLETE	EXTCOND(CONDREG_RX, 6)		/* RX complete */
#define COND_RX_CRYPTBUSY	EXTCOND(CONDREG_RX, 10)		/* RX crypto engine busy */
#define COND_RX_FIFOBUSY	EXTCOND(CONDREG_RX, 11)		/* RX FIFO operating */
#define COND_RX_FIFOFULL	EXTCOND(CONDREG_RX, 13)		/* RX FIFO full */
#define COND_RX_PLCP		EXTCOND(CONDREG_RX, 14)		/* We received a valid PLCP header */

/* RXE/MAC match condition register (core rev < 5) */
#define CONDREG_RXE		1

/* TX condition register */
#define CONDREG_TX		2
#define COND_TX_NOW		EXTCOND(CONDREG_TX, 0)		/* TX should be done now */
#define COND_TX_1		EXTCOND(CONDREG_TX, 1)		/* FIXME: Unknown meaning */
#define COND_TX_2		EXTCOND(CONDREG_TX, 2)		/* FIXME: Unknown meaning */
#define COND_MACEN		EXTCOND(CONDREG_TX, 4)		/* MAC enabled */
#define COND_TX_UNDERFLOW	EXTCOND(CONDREG_TX, 11)		/* TX underflow */
#define COND_TX_PHYERR		EXTCOND(CONDREG_TX, 13)		/* Check for PHY TX errors needed */
#define COND_TX_FLUSH		EXTCOND(CONDREG_TX, 14)		/* TX flush requested */
#define COND_TX_BUSY		EXTCOND(CONDREG_TX, 15)		/* TX engine busy */

/* PHY condition register */
#define CONDREG_PHY		3
#define COND_PHY0		EXTCOND(CONDREG_PHY, 0)		/* FIXME: Unknown meaning */
#define COND_PHY1		EXTCOND(CONDREG_PHY, 1)		/* FIXME: Unknown meaning */
#define COND_RADAR		EXTCOND(CONDREG_PHY, 2)		/* Radar detected */

/* Unknown condition register */
#define CONDREG_4		4
#define CONDREG_4_C1		EXTCOND(CONDREG_4, 1)		/* FIXME: Unknown meaning */
#define CONDREG_4_C9		EXTCOND(CONDREG_4, 9)		/* FIXME: Unknown meaning */

/* PSM condition register */
#define CONDREG_PSM		5
#define COND_PSM(bit)		EXTCOND(CONDREG_PSM, bit)

/* RCM condition register */
#define CONDREG_RCM		6
#define COND_RX_RAMATCH		EXTCOND(CONDREG_RCM, 0)		/* RX RA match */
#define COND_RX_BSSMATCH	EXTCOND(CONDREG_RCM, 6)		/* RX BSS match */

/* Condition register 7 */
#define CONDREG_7		7
#define COND_TRUE		EXTCOND(CONDREG_7, 15)		/* Always true */

#endif /* EXTERNAL_CONDITIONS_H_ */

// vim: syntax=b43 ts=8
