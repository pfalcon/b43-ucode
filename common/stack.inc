#ifndef STACK_EMULATION_H_
#define STACK_EMULATION_H_

#include "gpr.inc"


/* Push a value (can be anything that's valid as operand) to the stack */
#define PUSH(value)									\
	mov value, [0, OFFR_STACKPTR];		/* Save the value on the stack */	\
	sub BASER_STACKPTR, 1, BASER_STACKPTR;	/* Decrement stack pointer */


/* Pop the last entry from the stack and save it in the register */
#define POP(register)									\
	add BASER_STACKPTR, 1, BASER_STACKPTR;	/* Increment stack pointer */		\
	mov [0, OFFR_STACKPTR], register;	/* Restore the value from the stack */


#endif /* STACK_EMULATION_H_ */

// vim: syntax=b43 ts=8
