/* Program that counts consecutive 1s, 0s, and alternating 01s  */
	
			.text // executable code follows
			.global _start

_start:
		MOV 	R4, #TEST_NUM 		// R4 points to list 
		MOV 	R5, #0 			// R5 holds largest string of 1s
		MOV	R6, #0			// R6 holds largest string of 0s
		MOV 	R7, #0 			// R7 holds largest string of 10s 
		MOV 	R8, #ALT_NUM		// alternating 01s
		LDR 	R8, [R8] 

			
MAIN_LOOP: 	LDR 	R1, [R4], #4 		// R1 holds element in list to pass 
						// to subroutine
						// R4 incremented to point to next 
						// element in list 
		CMP 	R1, #0			// word 0 indicates end of list 
		BEQ	END 			// if end of list reached, 
						// nothing to do 
		
		BL 	ONES 			// subroutine for shift-and algorithm
		CMP	R5, R0			// check if new result larger than 
						// current largest
		MOVLT	R5, R0			// if larger, update current 
						// largest 
			
		BL	ZEROS
		CMP 	R6, R0
		MOVLT 	R6, R0
			
		BL	ALTERNATE
		CMP	R7, R0
		MOVLT 	R7, R0
			
		B 	MAIN_LOOP

END:		B	END 

		// for all subroutines, R1 delivers initial word
		// R3 used to perform necessary manipulations 
		// R0 returns result (count)
		
ONES:		MOV	R0, #0
		MOV 	R3, R1
LOOP_ONES:	CMP 	R3, #0
		BEQ	END_ONES
		LSR 	R2, R3, #1 	// perform SHIFT, followed by AND
	 	AND 	R3, R3, R2
		ADD 	R0, #1 		// count the string length so far
		B 	LOOP_ONES
			
END_ONES:	MOV	PC, LR 

ZEROS:	
		MOV 	R0, #0
		MVN 	R3, R1
LOOP_ZEROS:	CMP 	R3, #0
		BEQ 	END_ZEROS
		LSR 	R2, R3, #1
		AND 	R3, R3, R2
		ADD 	R0, #1
		B 	LOOP_ZEROS 

END_ZEROS: 	MOV 	PC, LR

ALTERNATE:	// must check for longest stream of 1s and 0s 
		// take larger of the two 
		MOV 	R0, #0
		MOV	R3, R1 
		EOR 	R3, R8 
		B	LOOP_ONES 	// count # of 1s 
		PUSH 	{R0} 
		MOV 	R0, #0 
		MOV	R3, R1
		EOR 	R3, R8
		MVN	R3, R3
		B	LOOP_ONES	// count # of 0s 
		MOV	R3, R0
		POP    {R0}
		CMP	R3, R0
		MOVGT	R0, R3 
		B	END_ALTERNATE

END_ALTERNATE: MOV	PC, LR 

ALT_NUM:	.word 	0x55555555
TEST_NUM: 	.word 	0xffffff00
		.word   0xffffffff
		.word 	0x000000ff
		.word 	0xaaaa0000			
		.word 	0 
		.end


	