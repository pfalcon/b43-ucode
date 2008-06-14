#ifndef DEBUG_H_
#define DEBUG_H_


/* Magic value to detect stack overflows. */
#define MAGIC_STACK_END		0x574C

/* Reason codes for PANICs */
#define PANIC_DIE		0 /* Die and don't let the driver auto-reload us. */
#define PANIC_RESTART		1 /* The driver will restart the device and firmware. */

/* Macro to conveniently trigger a panic and loop forever. */
#if DEBUG
# define PANIC(reason)			\
	mov reason, R_PANIC_REASON;	\
	call lr0, __panic;
#else
# define PANIC(reason)		call lr0, __panic;
#endif

/* Reason codes for the debug-IRQ */
#define DEBUGIRQ_PANIC		0	/* The firmware panic'ed */
#define DEBUGIRQ_DUMP_SHM	1	/* Dump shared SHM */
#define DEBUGIRQ_DUMP_REGS	2	/* Dump the microcode registers */
#define DEBUGIRQ_MARKER		3	/* Throw a "marker" */
#define DEBUGIRQ_ACK		0xFFFF	/* ACK from the kernel */

/* Macro to conveniently trigger a debug-IRQ. Clobbers lr0 and Rz */
#if DEBUG
# define DEBUGIRQ_THROW(reason)		\
	mov reason, R_DEBUGIRQ_REASON;	\
	call lr0, debug_irq;
#else
# define DEBUGIRQ_THROW(reason)		/* Nothing */
#endif

/* A marker can be used to let the kernel driver print a message
 * telling the user that the firmware just executed the code line the
 * MARKER statement was put into. The marker can't tell which codefile
 * it was triggered from (only the line number), but it does have an ID
 * number that can be used for file identification.
 * This is only for temporary local debugging,
 * as it adds a lot of inline code. Do not put this into release code. */
#if DEBUG
# define MARKER(id)				\
	PUSH(SPR_PC0);				\
	PUSH(R_MARKER_ID);			\
	PUSH(R_MARKER_LINE);			\
	PUSH(R_DEBUGIRQ_REASON);		\
	mov id , R_MARKER_ID;			\
	mov __LINE__ , R_MARKER_LINE;		\
	DEBUGIRQ_THROW(DEBUGIRQ_MARKER);	\
	POP(R_DEBUGIRQ_REASON);			\
	POP(R_MARKER_LINE);			\
	POP(R_MARKER_ID);			\
	POP(SPR_PC0);				\
	mov SPR_PC0, 0;
#else
# define MARKER(id)			/* Nothing */
#endif

#endif /* DEBUG_H_ */

// vim: syntax=b43 ts=8
