#include "stack.inc"


__stack_push:
	mov SPR_BASE0, R_STACK_SCRATCH1		/* Save off0 */
	mov R_STACK_POINTER, SPR_BASE0		/* Stackpointer -> off0 */
	mov R_STACK_SCRATCH0, [0, off0]		/* Save the value */
	mov R_STACK_SCRATCH1, SPR_BASE0		/* Restore off0 */
	sub R_STACK_POINTER, 1, R_STACK_POINTER	/* Decrement stack pointer */
	ret STACK_LINK_REGISTER, STACK_LINK_REGISTER

__stack_pop:
	add R_STACK_POINTER, 1, R_STACK_POINTER	/* Increment stack pointer */
	mov SPR_BASE0, R_STACK_SCRATCH1		/* Save off0 */
	mov R_STACK_POINTER, SPR_BASE0		/* Stackpointer -> off0 */
	mov [0, off0], R_STACK_SCRATCH0		/* Restore the value */
	mov R_STACK_SCRATCH1, SPR_BASE0		/* Restore off0 */
	ret STACK_LINK_REGISTER, STACK_LINK_REGISTER

// vim: syntax=b43 ts=8
