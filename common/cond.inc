#ifndef EXTERNAL_CONDITIONS_H_
#define EXTERNAL_CONDITIONS_H_

/* Definitions for the External Conditions */

#define EXTCOND(reg, bit)	((bit) | ((reg) << 4))

/* Wrap a condition in the EOI() wrapper to EOI it */
#define EOI(ext_condition)	((ext_condition) | 0x80)



/* RX condition register */
#define CONDREG_RX		0
#define COND_RX_FCS_GOOD	EXTCOND(CONDREG_RX, 3)		/* RX FCS good */
#define COND_RX_COMPLETE	EXTCOND(CONDREG_RX, 6)		/* RX complete */
#define COND_RX_CRYPTBUSY	EXTCOND(CONDREG_RX, 10)		/* RX crypto engine busy */
#define COND_RX_FIFOFULL	RXTCOND(CONDREG_RX, 13)		/* RX FIFO full */

/* RXE/MAC match condition register (core rev < 5) */
#define CONDREG_RXE		1

/* TX condition register */
#define CONDREG_TX		2
#define COND_MACEN		EXTCOND(CONDREG_TX, 4)		/* MAC enabled */
#define COND_TX_FLUSH		EXTCOND(CONDREG_TX, 14)		/* TX flush requested */
#define COND_TX_BUSY		EXTCOND(CONDREG_TX, 15)		/* TX engine busy */

/* PHY condition register */
#define CONDREG_PHY		3
#define COND_RADAR		EXTCOND(CONDREG_PHY, 2)		/* Radar detected */

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
