#ifndef STACK_EMULATION_H_
#define STACK_EMULATION_H_

#include "gpr.inc"


/* Push a value (can be anything that's valid as operand) to the stack */
#define PUSH(value)									\
	mov value, [0, OFFR_STACKPTR];		/* Save the value on the stack */	\
	sub BASER_STACKPTR, 1, BASER_STACKPTR;	/* Decrement stack pointer */

/* Helpers to push the link registers to the stack */
#define __PUSH_LR(nr)		PUSH(SPR_PC##nr);
#define PUSH_LR0		__PUSH_LR(0)
#define PUSH_LR1		__PUSH_LR(1)
#define PUSH_LR2		__PUSH_LR(2)
#define PUSH_LR3		__PUSH_LR(3)

/* Pop the last entry from the stack and save it in the register */
#define POP(register)									\
	add BASER_STACKPTR, 1, BASER_STACKPTR;	/* Increment stack pointer */		\
	mov [0, OFFR_STACKPTR], register;	/* Restore the value from the stack */

/* Helpers to pop values from the stack to the link registers */
#define __POP_LR(nr)		POP(SPR_PC##nr); mov SPR_PC##nr, 0;
#define POP_LR0			__POP_LR(0)
#define POP_LR1			__POP_LR(1)
#define POP_LR2			__POP_LR(2)
#define POP_LR3			__POP_LR(3)


#endif /* STACK_EMULATION_H_ */

// vim: syntax=b43 ts=8
