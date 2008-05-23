#ifndef GENERAL_PURPOSE_REGISTERS_H_
#define GENERAL_PURPOSE_REGISTERS_H_

/* Registers with a special function throughout the whole code. */
#define R_MIN_CONTWND		r3
#define R_MAX_CONTWND		r4
#define R_CUR_CONTWND		r5
#define R_SHORT_RETRY		r6
#define R_LONG_RETRY		r7
#define R_DTIM_CNT		r8
#define R_SEQ_COUNT		r9
#define R_BEAC0_LEN		r21
#define R_BEAC1_LEN		r22
#define R_SHORT_FB		r23
#define R_LONG_FB		r24

#define R_WATCHDOG		r1

/* Registers used by the stack implementation only. */
#define R_STACK_POINTER		r35
#define R_STACK_SCRATCH0	r36
#define R_STACK_SCRATCH1	r37

/* General purpose registers (r38 - r63) */
#define Ra	r38 /* Caller-saved. Any function can clobber this without saving. */
#define Rb	r39 /* Caller-saved. Any function can clobber this without saving. */
#define Rc	r40 /* Caller-saved. Any function can clobber this without saving. */
#define Rd	r41 /* Caller-saved. Any function can clobber this without saving. */
#define Re	r42 /* Caller-saved. Any function can clobber this without saving. */
#define Rf	r43 /* Caller-saved. Any function can clobber this without saving. */
#define Rg	r44 /* Caller-saved. Any function can clobber this without saving. */
#define Rh	r45 /* Caller-saved. Any function can clobber this without saving. */
#define Ri	r46 /* Callee-saved. Save it before clobbering! */
#define Rj	r47 /* Callee-saved. Save it before clobbering! */
#define Rk	r48 /* Callee-saved. Save it before clobbering! */
#define Rl	r49 /* Callee-saved. Save it before clobbering! */
#define Rm	r50 /* Callee-saved. Save it before clobbering! */
#define Rn	r51 /* Callee-saved. Save it before clobbering! */
#define Ro	r52 /* Callee-saved. Save it before clobbering! */
#define Rp	r53 /* Callee-saved. Save it before clobbering! */
#define Rq	r54 /* Callee-saved. Save it before clobbering! */
#define Rr	r55 /* Callee-saved. Save it before clobbering! */
#define Rs	r56 /* Callee-saved. Save it before clobbering! */
#define Rt	r57 /* Callee-saved. Save it before clobbering! */
#define Ru	r58 /* Callee-saved. Save it before clobbering! */
#define Rv	r59 /* Callee-saved. Save it before clobbering! */
#define Rw	r60 /* Callee-saved. Save it before clobbering! */
#define Rx	r61 /* Caller-saved. Any function can clobber this without saving. */
#define Ry	r62 /* Caller-saved. Any function can clobber this without saving. */
#define Rz	r63 /* Caller-saved. Any function can clobber this without saving. */

#define R_DEBUGIRQ_REASON	Rz
#define R_MARKER_ID		r2
#define R_MARKER_LINE		r3
#define R_PANIC_REASON		r3

#endif /* GENERAL_PURPOSE_REGISTERS_H_ */

// vim: syntax=b43 ts=8
