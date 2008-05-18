#ifndef STACK_EMULATION_H_
#define STACK_EMULATION_H_

#include "gpr.inc"

/* The link register used for stack operations.
 * This link register is clobbered on every stack operation. */
#define STACK_LINK_REGISTER	lr3

#define PUSH(value)	mov value, R_STACK_SCRATCH0;	\
			call STACK_LINK_REGISTER, __stack_push;

#define POP(register)	call STACK_LINK_REGISTER, __stack_pop;	\
			mov R_STACK_SCRATCH0, register;


#endif /* STACK_EMULATION_H_ */

// vim: syntax=b43 ts=8
