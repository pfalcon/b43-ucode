#ifndef SHARED_MEMORY_H_
#define SHARED_MEMORY_H_

/* SHM (Shared Memory) offsets */

/* Host-side routing values for the SHM.
 * This is only useful for the initvals */
#define HOST_SHM_UCODE		0
#define HOST_SHM_SHARED		1
#define HOST_SHM_SCRATCH	2
#define HOST_SHM_IHR		3
#define HOST_SHM_RCMTA		4


/* Macro to convert a host-SHM-address to a microcode-SHM-address.
 * This also asserts that the address is word aligned. */
#define SHM(address)		(((address) / 2) +		\
				 (%assert((address & 1) == 0)))
/* Macro to convert a byte-offset into a microcode-SHM-word-offset.
 * This does the same as SHM(), but is used to mark offsets that are not
 * based on absolute zero, but relative. */
#define SHM_OFFSET(offset)	SHM(offset)


/* Misc variables */
#define SHM_WLCOREREV		SHM(0x016) /* 802.11 core revision */
#define SHM_PCTLWDPOS		SHM(0x008)
#define SHM_RXPADOFF		SHM(0x034) /* RX Padding data offset (PIO only) */
#define SHM_PHYVER		SHM(0x050) /* PHY version */
#define SHM_PHYTYPE		SHM(0x052) /* PHY type */
#define SHM_ANTSWAP		SHM(0x05C) /* Antenna swap threshold */
#define SHM_HF_LO		SHM(0x05E) /* Hostflags for ucode options (low) */
#define  SHM_HF_LO_ANTDIVHELP	0 /* bit0: ucode antenna div helper */
#define  SHM_HF_LO_SYMW		1 /* bit1: G-PHY SYM workaround */
#define  SHM_HF_LO_RXPULLW	2 /* bit2: RX pullup workaround */
#define  SHM_HF_LO_CCKBOOST	3 /* bit3: 4dB CCK power boost (exclusive with OFDM boost) */
#define  SHM_HF_LO_BTCOEX	4 /* bit4: Bluetooth coexistence */
#define  SHM_HF_LO_GDCW		5 /* bit5: G-PHY DC canceller filter bw workaround */
#define  SHM_HF_LO_OFDMPABOOST	6 /* bit6: Enable PA gain boost for OFDM */
#define  SHM_HF_LO_ACPR		7 /* bit7: Disable for Japan, channel 14 */
#define  SHM_HF_LO_EDCF		8 /* bit8: on if WME and MAC suspended */
#define  SHM_HF_LO_TSSIRPSMW	9 /* bit9: TSSI reset PSM ucode workaround */
#define  SHM_HF_LO_20IN40IQW	9 /* bit9: 20 in 40 MHz I/Q workaround (rev >= 13 only) */
#define  SHM_HF_LO_DSCRQ	10 /* bit10: Disable slow clock request in ucode */
#define  SHM_HF_LO_ACIW		11 /* bit11: ACI workaround: shift bits by 2 on PHY CRS */
#define  SHM_HF_LO_2060W	12 /* bit12: 2060 radio workaround */
#define  SHM_HF_LO_RADARW	13 /* bit13: Radar workaround */
#define  SHM_HF_LO_USEDEFKEYS	14 /* bit14: Enable use of default keys */
#define  SHM_HF_LO_AFTERBURNER	15 /* bit15: Afterburner enabled */
#define SHM_HF_MI		SHM(0x060) /* Hostflags for ucode options (middle) */
#define  SHM_HF_MI_BT4PRIOCOEX	0 /* bit0: Bluetooth 4-priority coexistence */
#define  SHM_HF_MI_FWKUP	1 /* bit1: Fast wake-up ucode */
#define  SHM_HF_MI_VCORECALC	2 /* bit2: Force VCO recalculation when powering up synthpu */
#define  SHM_HF_MI_PCISCW	3 /* bit3: PCI slow clock workaround */
#define  SHM_HF_MI_4318TSSI	5 /* bit5: 4318 TSSI */
#define  SHM_HF_MI_FBCMCFIFO	6 /* bit6: Flush bcast/mcast FIFO immediately */
#define  SHM_HF_MI_HWPCTL	7 /* bit7: Enable hardware power control */
#define  SHM_HF_MI_BTCOEXALT	8 /* bit8: Bluetooth coexistence in alternate pins */
#define  SHM_HF_MI_TXBTCHECK	9 /* bit9: Bluetooth check during transmission */
#define  SHM_HF_MI_SKCFPUP	10 /* bit10: Skip CFP update */
#define  SHM_HF_MI_N40W		11 /* bit11: N PHY 40 MHz workaround (rev >= 13 only) */
#define  SHM_HF_MI_ANTSEL	13 /* bit13: Antenna selection (for testing antenna div.) */
#define  SHM_HF_MI_BT3COEXT	13 /* bit13: Bluetooth 3-wire coexistence (rev >= 13 only) */
#define  SHM_HF_MI_BTCANT	14 /* bit14: Bluetooth coexistence (antenna mode) (rev >= 13 only) */
#define SHM_HF_HI		SHM(0x062) /* Hostflags for ucode options (high) */
#define  SHM_HF_HI_ANTSELEN	0 /* bit0: Antenna selection enabled (rev >= 13 only) */
#define  SHM_HF_HI_ANTSELMODE	1 /* bit1: Antenna selection mode (rev >= 13 only) */
#define  SHM_HF_HI_MLADVW	4 /* bit4: N PHY ML ADV workaround (rev >= 13 only) */
#define  SHM_HF_HI_PR45960W	11 /* bit11: PR 45960 workaround (rev >= 13 only) */
#define SHM_RFATT		SHM(0x064) /* Current radio attenuation value */
#define SHM_RADAR		SHM(0x066) /* Radar register */
#define SHM_PHYTXNOI		SHM(0x06E) /* PHY noise directly after TX (lower 8bit only) */
#define SHM_RFRXSP1		SHM(0x072) /* RF RX SP Register 1 */
#define SHM_CHAN		SHM(0x0A0) /* Current channel (low 8bit only) */
#define SHM_GCLASSCTL		SHM(0x0A6) /* Value for the G-PHY classify control register */
#define SHM_BCMCFIFOID		SHM(0x108) /* Last posted cookie to the bcast/mcast FIFO */

/* TSSI information */
#define SHM_TSSI_CCK_LO		SHM(0x058) /* TSSI for the last 4 CCK frames (low) */
#define SHM_TSSI_CCK_HI		SHM(0x05A) /* TSSI for the last 4 CCK frames (high) */
#define SHM_TSSI_OFDM_A_LO	SHM(0x068) /* TSSI for the last 4 OFDM (A) frames (low) */
#define SHM_TSSI_OFDM_A_HI	SHM(0x06A) /* TSSI for the last 4 OFDM (A) frames (high) */
#define SHM_TSSI_OFDM_G_LO	SHM(0x070) /* TSSI for the last 4 OFDM (G) frames (low) */
#define SHM_TSSI_OFDM_G_HI	SHM(0x072) /* TSSI for the last 4 OFDM (G) frames (high) */

/* TX FIFO variables */
#define SHM_TXFIFO_SIZE01	SHM(0x098) /* TX FIFO size for FIFO 0 (low) and 1 (high) */
#define SHM_TXFIFO_SIZE23	SHM(0x09A) /* TX FIFO size for FIFO 2 and 3 */
#define SHM_TXFIFO_SIZE45	SHM(0x09C) /* TX FIFO size for FIFO 4 and 5 */
#define SHM_TXFIFO_SIZE67	SHM(0x09E) /* TX FIFO size for FIFO 6 and 7 */

/* Background noise */
#define SHM_JSSI0		SHM(0x088) /* Measure JSSI 0 */
#define SHM_JSSI1		SHM(0x08A) /* Measure JSSI 1 */
#define SHM_JSSIAUX		SHM(0x08C) /* Measure JSSI AUX */

/* Crypto engine */
#define SHM_DEFAULTIV		SHM(0x03C) /* Default IV location */
#define SHM_NRRXTRANS		SHM(0x03E) /* # of soft RX transmitter addresses (max 8) */
#define SHM_KTP			SHM(0x056) /* Key table pointer */
#define SHM_TKIP_P1KEYS		SHM(0x2E0) /* TKIP Phase 1 keys. */
#define SHM_KEYIDXBLOCK		SHM(0x5D4) /* Key index/algorithm block. */

/* WME variables */
#define SHM_EDCFSTAT		SHM(0x00E) /* EDCF status */
#define SHM_TXFCUR		SHM(0x030) /* TXF current index */
#define SHM_EDCFQ		SHM(0x240) /* EDCF Q info */

/* Powersave mode related variables */
#define SHM_SLOTT		SHM(0x010) /* Slot time */
#define SHM_DTIMPER		SHM(0x012) /* DTIM period */
#define SHM_NOSLPZNATDTIM	SHM(0x04C) /* NOSLPZNAT DTIM */

/* Beacon/AP variables */
#define SHM_BTL0		SHM(0x018) /* Beacon template length 0 */
#define SHM_BTL1		SHM(0x01A) /* Beacon template length 1 */
#define SHM_BTSFOFF		SHM(0x01C) /* Beacon TSF offset */
#define SHM_TIMBPOS		SHM(0x01E) /* TIM B position in beacon */
#define SHM_DTIMP		SHM(0x012) /* DTIP period */
#define SHM_MCASTCOOKIE		SHM(0x0A8) /* Last bcast/mcast frame ID */
#define SHM_SFFBLIM		SHM(0x044) /* Short frame fallback retry limit */
#define SHM_LFFBLIM		SHM(0x046) /* Long frame fallback retry limit */
#define SHM_BEACPHYCTL		SHM(0x054) /* Beacon PHY TX control word (see PHY TX control) */
#define SHM_EXTNPHYCTL		SHM(0x0B0) /* Extended bytes for beacon PHY control (N) */

/* ACK/CTS control */
#define SHM_ACKCTSPHYCTL	SHM(0x022) /* ACK/CTS PHY control word (see PHY TX control) */

/* Probe response variables */
#define SHM_PRSSID		SHM(0x160) /* Probe Response SSID */
#define SHM_PRSSIDLEN		SHM(0x048) /* Probe Response SSID length */
#define SHM_PRTLEN		SHM(0x04A) /* Probe Response template length */
#define SHM_PRMAXTIME		SHM(0x074) /* Probe Response max time */
#define SHM_PRPHYCTL		SHM(0x188) /* Probe Response PHY TX control word */

/* Rate tables */
#define SHM_OFDMDIRECT		SHM(0x1C0) /* Pointer to OFDM direct map */
#define SHM_OFDMBASIC		SHM(0x1E0) /* Pointer to OFDM basic rate map */
#define SHM_CCKDIRECT		SHM(0x200) /* Pointer to CCK direct map */
#define SHM_CCKBASIC		SHM(0x220) /* Pointer to CCK basic rate map */

/* Microcode soft registers */
#define SHM_UCODEREV		SHM(0x000) /* Microcode revision */
#define SHM_UCODEPATCH		SHM(0x002) /* Microcode patchlevel */
#define SHM_UCODEDATE		SHM(0x004) /* Microcode date */
#define SHM_UCODETIME		SHM(0x006) /* Microcode time */
#define SHM_UCODESTAT		SHM(0x040) /* Microcode debug status code */
#define  SHM_UCODESTAT_INVALID	0
#define  SHM_UCODESTAT_INIT	1
#define  SHM_UCODESTAT_ACTIVE	2
#define  SHM_UCODESTAT_SUSP	3 /* suspended */
#define  SHM_UCODESTAT_SLEEP	4 /* asleep (PS) */
#define SHM_MAXBFRAMES		SHM(0x080) /* Maximum number of frames in a burst */
#define SHM_SPUWKUP		SHM(0x094) /* pre-wakeup for synth PU in us */
#define SHM_PRETBTT		SHM(0x096) /* pre-TBTT in us */



/* TX header WORD(!) offsets. These are used as offsets into the TX header
 * information fields in SHM for each FIFO via offset register pointer. */
#define TXHDR_MACLO		SHM_OFFSET(0x00) /* MAC control lo */
#define TXHDR_MACHI		SHM_OFFSET(0x02) /* MAC control hi */
#define TXHDR_FCTL		SHM_OFFSET(0x04) /* Frame Control field copy */
#define TXHDR_FES		SHM_OFFSET(0x06) /* TX FES Time Normal */
#define TXHDR_PHYCTL		SHM_OFFSET(0x08) /* PHY control word */
#define TXHDR_PHYCTL1		SHM_OFFSET(0x0A) /* PHY control word 1 */
#define TXHDR_PHYCTL1FB		SHM_OFFSET(0x0C) /* PHY control word 1 for fallback */
#define TXHDR_PHYCTL1RTS	SHM_OFFSET(0x0E) /* PHY control word 1 RTS */
#define TXHDR_PHYCTL1RTSFB	SHM_OFFSET(0x10) /* PHY control word 1 RTS for fallback */
#define TXHDR_PHYRATES		SHM_OFFSET(0x12) /* PHY rates */
#define TXHDR_EFT		SHM_OFFSET(0x14) /* Extra Frame Types */
#define TXHDR_IV		SHM_OFFSET(0x16) /* IV / crypto field */
#define TXHDR_RA		SHM_OFFSET(0x26) /* Frame receiver address */
#define TXHDR_FESFB		SHM_OFFSET(0x2C) /* TX FES Time fallback */
#define TXHDR_RTSPLCPFB		SHM_OFFSET(0x2E) /* RTS PLCP fallback */
#define TXHDR_RTSDURFB		SHM_OFFSET(0x34) /* RTS duration fallback */
#define TXHDR_PLCPFB		SHM_OFFSET(0x36) /* PLCP fallback */
#define TXHDR_DURFB		SHM_OFFSET(0x3C) /* Duration fallback */
#define TXHDR_MIMOML		SHM_OFFSET(0x3E) /* MIMO mode length */
#define TXHDR_MIMOFBRL		SHM_OFFSET(0x40) /* MIMO fallback rate length */
#define TXHDR_TOLO		SHM_OFFSET(0x42) /* Timeout low */
#define TXHDR_TOHI		SHM_OFFSET(0x44) /* Timeout high */
#define TXHDR_MIMOAS		SHM_OFFSET(0x46) /* MIMO antenna select */
#define TXHDR_PRELSZ		SHM_OFFSET(0x48) /* Preload size */
#define TXHDR_UNUSED1		SHM_OFFSET(0x4A) /* Unused padding */
#define TXHDR_COOKIE		SHM_OFFSET(0x4C) /* Frame ID */
#define TXHDR_STAT		SHM_OFFSET(0x4E) /* Status */
#define TXHDR_RTSPLCP		SHM_OFFSET(0x50) /* RTS PLCP header */
#define TXHDR_RTS		SHM_OFFSET(0x56) /* RTS frame */
#define TXHDR_UNUSED2		SHM_OFFSET(0x66) /* Unused padding */
#define TXHDR_WSIZE		(104 / 2) /* Header size, in words */



/* --- Misc offsets that are only valid for the OpenSource firmware. --- */


/* The TX FIFO index that we are currently processing.
 * Note that this index is leftshifted by 8 to avoid shifting when
 * writing it to the hardware registers. */
#define SHM_CUR_TXFIFO		SHM(0x970)
#define  CUR_TXFIFO_SHIFT	8
/* Lookup table for the mapping of the FIFO number to the TX header
 * scratch space in SHM. The lookup table is written in initvals. */
#define SHM_TXHDR_LT		SHM_TXHDR_LT_FIFO0
#define  SHM_TXHDR_LT_FIFO0	SHM(0x972)
#define  SHM_TXHDR_LT_FIFO1	SHM(0x974)
#define  SHM_TXHDR_LT_FIFO2	SHM(0x976)
#define  SHM_TXHDR_LT_FIFO3	SHM(0x978)
#define  SHM_TXHDR_LT_FIFO4	SHM(0x97A)
/* Allocated space for the FIFO-0 TX header */
#define SHM_TXHDR0_START	SHM(0x97C)
#define SHM_TXHDR0_END		SHM(0x9E2)
/* Allocated space for the FIFO-1 TX header */
#define SHM_TXHDR1_START	SHM(0x9E4)
#define SHM_TXHDR1_END		SHM(0xA4A)
/* Allocated space for the FIFO-2 TX header */
#define SHM_TXHDR2_START	SHM(0xA4C)
#define SHM_TXHDR2_END		SHM(0xAB2)
/* Allocated space for the FIFO-3 TX header */
#define SHM_TXHDR3_START	SHM(0xAB4)
#define SHM_TXHDR3_END		SHM(0xB1A)
/* Allocated space for the FIFO-4 TX header */
#define SHM_TXHDR4_START	SHM(0xB1C)
#define SHM_TXHDR4_END		SHM(0xB82)

/* Background noise measuring context */
#define SHM_BGN_START_TSF1	SHM(0xB84) /* TSF word1 when the measurement started */
#define SHM_BGN_STATUS		SHM(0xB86)
#define  BGN_INPROGRESS		0 /* bit0: Background noise measurement in progress */

/* The place where the driver will put the hwcrypto keys to.
 * The key table pointer will point to this. */
#define SHM_KEY_TABLE_START	SHM(0xB88) /* First word */
#define SHM_KEY_TABLE_END	SHM(0xF26) /* Last word */

/* RX-header for the driver.
 * The RXE will take it from here and put it into the DMA FIFO. */
#define SHM_RXHDR		SHM(0xF28) /* Address where the RXE will take the RXHDR from */
#define  SHM_RXHDR_FRAMELEN	SHM(0xF28) /* Frame length in bytes, not including RX-header */
#define  SHM_RXHDR_PAD		SHM(0xF2A) /* Unused */
#define  SHM_RXHDR_PHYSTAT0	SHM(0xF2C) /* PHY RX Status 0 */
#define  SHM_RXHDR_PHYSTAT1	SHM(0xF2E) /* PHY RX Status 1 */
#define  SHM_RXHDR_PHYSTAT2	SHM(0xF30) /* PHY RX Status 2 */
#define  SHM_RXHDR_PHYSTAT3	SHM(0xF32) /* PHY RX Status 3 */
#define  SHM_RXHDR_MACSTAT0	SHM(0xF34) /* MAC RX Status low */
#define   MACSTAT0_FCSERR		0 /* bit0: FCS error */
#define   MACSTAT0_RESP			1 /* bit1: Response frame transmitted */
#define   MACSTAT0_PADDING		2 /* bit2: Pad bytes present */
#define   MACSTAT0_DEC			3 /* bit3: Decryption attempted */
#define   MACSTAT0_DECERR		4 /* bit4: Decrypt error */
#define  SHM_RXHDR_MACSTAT1	SHM(0xF36) /* MAC RX Status high */
#define  SHM_RXHDR_TIME		SHM(0xF38) /* MAC time + PHY delay */
#define  SHM_RXHDR_CHAN		SHM(0xF3A) /* RX Channel information */
#define  SHM_RXHDR_SIZE		10 /* Header size in words */

#define SHM_RX_TSF0		SHM(0xF3C) /* TSF for the received frame (word 0) */
#define SHM_RX_TSF1		SHM(0xF3E) /* TSF for the received frame (word 1) */
#define SHM_RX_TSF2		SHM(0xF40) /* TSF for the received frame (word 2) */
#define SHM_RX_TSF3		SHM(0xF42) /* TSF for the received frame (word 3) */
#define SHM_RXFRAME_HDR		SHM(0xF44) /* ieee80211 Frame header of received frame is stored here. */
#define SHM_RXFRAME_HDR_END	SHM(0xF7E) /* Frame header - end */
#define SHM_RXFRAME_HDR_LEN	(((SHM_RXFRAME_HDR_END - SHM_RXFRAME_HDR) + 1) * 2) /* RXframe header space in bytes */
#define SHM_STACK_END		SHM(0xF80) /* Last element of stack. Stacksize is 128 bytes */
#define SHM_STACK_START		SHM(0xFFE) /* Stack grows down from end of memory */

#endif /* SHARED_MEMORY_H_ */

// vim: syntax=b43 ts=8
