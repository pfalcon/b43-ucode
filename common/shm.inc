#ifndef SHARED_MEMORY_H_
#define SHARED_MEMORY_H_

/* SHM (Shared Memory) offsets */

#define SHM(offset)		((offset) / 2)

/* Misc variables */
#define SHM_WLCOREREV		SHM(0x016) /* 802.11 core revision */
#define SHM_PCTLWDPOS		SHM(0x008)
#define SHM_RXPADOFF		SHM(0x034) /* RX Padding data offset (PIO only) */
#define SHM_PHYVER		SHM(0x050) /* PHY version */
#define SHM_PHYTYPE		SHM(0x052) /* PHY type */
#define SHM_ANTSWAP		SHM(0x05C) /* Antenna swap threshold */
#define SHM_HF_LO		SHM(0x05E) /* Hostflags for ucode options (low) */
#define SHM_HF_MI		SHM(0x060) /* Hostflags for ucode options (middle) */
#define SHM_HF_HI		SHM(0x062) /* Hostflags for ucode options (high) */
#define SHM_RFATT		SHM(0x064) /* Current radio attenuation value */
#define SHM_RADAR		SHM(0x066) /* Radar register */
#define SHM_PHYTXNOI		SHM(0x06E) /* PHY noise directly after TX (lower 8bit only) */
#define SHM_RFRXSP1		SHM(0x072) /* RF RX SP Register 1 */
#define SHM_CHAN		SHM(0x0A0) /* Current channel (low 8bit only) */
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

#endif /* SHARED_MEMORY_H_ */
