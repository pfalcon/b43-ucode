#ifndef PHY_REGISTERS_H_
#define PHY_REGISTERS_H_

/*** PHY Registers ***/

/* Routing */
#define PHYROUTE			0x0C00 /* PHY register routing bits mask */
#define  PHYROUTE_BASE			0x0000 /* Base registers */
#define  PHYROUTE_OFDM_GPHY		0x0400 /* OFDM register routing for G-PHYs */
#define  PHYROUTE_EXT_GPHY		0x0800 /* Extended G-PHY registers */
#define  PHYROUTE_N_BMODE		0x0C00 /* N-PHY BMODE registers */

/* CCK (B-PHY) registers. */
#define PHY_CCK(reg)			((reg) | PHYROUTE_BASE)
/* N-PHY registers. */
#define PHY_N(reg)			((reg) | PHYROUTE_BASE)
/* N-PHY BMODE registers. */
#define PHY_N_BMODE(reg)		((reg) | PHYROUTE_N_BMODE)
/* OFDM (A-PHY) registers. */
#define PHY_OFDM(reg)			((reg) | PHYROUTE_OFDM_GPHY)
/* Extended G-PHY registers. */
#define PHY_EXTG(reg)			((reg) | PHYROUTE_EXT_GPHY)


/* OFDM A-PHY registers */
#define APHY_PACKCNT			PHY_OFDM(0x5F)

/* CCK B-PHY registers */
#define BPHY_CHANINFO			PHY_CCK(0x08)
#define BPHY_JSSI			PHY_CCK(0x27)

/* Extended G-PHY registers */
#define GPHY_CLASSCTL			PHY_EXTG(0x02) /* Classify control */
#define  GPHY_CLASSCTL_CCK		0 /* bit0: CCK */
#define  GPHY_CLASSCTL_OFDM		1 /* bit1: OFDM */
#define GPHY_ANAOVER			PHY_EXTG(0x14) /* Analog override */



/* Values for the PHY-Type */
#define PHYTYPE_A		0
#define PHYTYPE_B		1
#define PHYTYPE_G		2
#define PHYTYPE_N		4
#define PHYTYPE_LP		5



/* 2050 radio registers */
#define R2050_TXCTL0			0x51



#endif /* PHY_REGISTERS_H_ */

// vim: syntax=b43 ts=8
