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

/* Registers used by the stack implementation only. */
#define R_STACK_POINTER		r35
#define R_STACK_SCRATCH0	r36
#define R_STACK_SCRATCH1	r37

/* General purpose registers (r38 - r63) */
#define Ra	r38
#define Rb	r39
#define Rc	r40
#define Rd	r41
#define Re	r42
#define Rf	r43
#define Rg	r44
#define Rh	r45
#define Ri	r46
#define Rj	r47
#define Rk	r48
#define Rl	r49
#define Rm	r50
#define Rn	r51
#define Ro	r52
#define Rp	r53
#define Rq	r54
#define Rr	r55
#define Rs	r56
#define Rt	r57
#define Ru	r58
#define Rv	r59
#define Rw	r60
#define Rx	r61
#define Ry	r62
#define Rz	r63

#endif /* GENERAL_PURPOSE_REGISTERS_H_ */

// vim: syntax=b43 ts=8
