/* Program that counts consecutive 1’s */
	
		.text // executable code follows
		.global _start

_start:
		MOV 	R4, #TEST_NUM 	// R4 points to list 
		MOV 	R5, #0 		// R5 holds final result
			
MAIN_LOOP:	LDR 	R1, [R4], #4 	// R1 holds element in list to pass to 
					// subroutine
					// R4 incremented to point to next element 
					// in list 
		CMP 	R1, #0		// word 0 indicates end of list 
		BEQ	END 		// if end of list reached, nothing to do 
		BL 	ONES 		// subroutine for shift-and algorithm
		CMP	R5, R0		// check if new result larger than current 
					// largest
		MOVLT	R5, R0		// if larger, update current largest 
		B 	MAIN_LOOP

END:		B	END 

ONES:		// R1 to receive input data. R0 to return result 
		MOV	R0, #0
ONES_LOOP:	CMP 	R1, #0
		BEQ	END_ONES
		LSR 	R2, R1, #1 	// perform SHIFT, followed by AND
	 	AND 	R1, R1, R2
		ADD 	R0, #1 		// count the string length so far
		B 	ONES_LOOP
			
END_ONES:	MOV	PC, LR 

TEST_NUM: 	.word 	0x103fe00f
		.word 	0xffff0000
		.word 	0xaf901101
		.word	0x4f09129a
		.word 	0x103fe00f
		.word 	0x88888888
		.word 	0xaf923101
		.word	0x4afff321
		.word 	0xa33310f6
		.word 	0xffffffff
		.word 	0 
		.end
	