#ifndef SHARED_MEMORY_H_
#define SHARED_MEMORY_H_

/* SHM (Shared Memory) offsets */

/* Microcode versioning information */
#define SHM_UCODEREV		0x000
#define SHM_UCODEPATCH		0x001
#define SHM_UCODEDATE		0x002
#define SHM_UCODETIME		0x003
/* Debugging */
#define SHM_UCODESTAT		0x020
#define  SHM_UCODESTAT_INVAL	0
#define  SHM_UCODESTAT_INIT	1
#define  SHM_UCODESTAT_ACTIVE	2
#define  SHM_UCODESTAT_SUSPEND	3
#define  SHM_UCODESTAT_ASLEEP	4

#endif /* SHARED_MEMORY_H_ */
