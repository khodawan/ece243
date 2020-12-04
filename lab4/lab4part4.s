			.text // executable code follows
			.global _start

_start:
			MOV 	R4, #TEST_NUM 		// R4 points to list 
			MOV 	R5, #0 			// R5 holds largest string of 1s
			MOV	R6, #0			// R6 holds largest string of 0s
			MOV 	R7, #0 			// R7 holds largest string of 10s 
			MOV 	R8, #ALT_NUM		// alternating 01s
			LDR 	R8, [R8] 

			
MAIN_LOOP: 		LDR 	R1, [R4], #4 		// R1 holds element in list to pass to subroutine. R4 incremented to point to next element in list 
			CMP 	R1, #0			// word 0 indicates end of list 
			
			BEQ	DISPLAY 		// if end of list reached, nothing to do 
			
			BL 	ONES 			// subroutine for shift-and algorithm
			CMP	R5, R0			// check if new result larger than current largest
			MOVLT	R5, R0			// if larger, update current largest 
			
			BL	ZEROS
			CMP 	R6, R0
			MOVLT 	R6, R0
			
			BL	ALTERNATE
			CMP	R7, R0
			MOVLT 	R7, R0
			
			B 	MAIN_LOOP

END:			B	END 

		// for all subroutines, R1 delivers initial word
		// R3 used to perform necessary manipulations 
		// R0 returns result (count)
		
ONES:			MOV	R0, #0
			MOV 	R3, R1
LOOP_ONES:		CMP 	R3, #0
			BEQ	END_ONES
			LSR 	R2, R3, #1 		// perform SHIFT, followed by AND
	 		AND 	R3, R3, R2
			ADD 	R0, #1 			// count the string length so far
			B 	LOOP_ONES
			
END_ONES:		MOV	PC, LR 

ZEROS:	
			MOV 	R0, #0
			MVN 	R3, R1
LOOP_ZEROS:		CMP 	R3, #0
			BEQ 	END_ZEROS
			LSR 	R2, R3, #1
			AND 	R3, R3, R2
			ADD 	R0, #1
			B 	LOOP_ZEROS 

END_ZEROS: 		MOV 	PC, LR

ALTERNATE:		// must check for longest stream of 1s and 0s - take larger of the two 
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

END_ALTERNATE: 		MOV	PC, LR 


/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */
SEG7_CODE:  	MOV     R1, #BIT_CODES  
            	ADD     R1, R0         // index into the BIT_CODES "array"
            	LDRB    R0, [R1]       // load the bit pattern (to be returned)
            	MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2     		 // pad with 2 bytes to maintain word alignment

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit code 
           
 	    BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
			

		// code for R6 to HEX
		PUSH	{R4}			// save LSBs for loading HEX1-0
		MOV	R0, R6
		BL 	DIVIDE
		MOV	R9, R1
		BL 	SEG7_CODE
		LSL	R0, #8			// to preserve ones digit to go to HEX2		
		MOV	R4, R0
		MOV 	R0, R9
		BL 	SEG7_CODE
		LSL	R0, #16			// to preserve tens digit to go to HEX3
		ORR	R4, R0 
		MOV	R0, R4			// use R0 as dummy to save digits for HEX3-2
		LSL	R0, #8 			// shift digits to be in 100s and 1000s positions 
		POP	{R4}			// get previous digits to got to HEX1-0
		ADD	R4, R0 			// get R4 to hold all required digits in proper places
          
		STR     R4, [R8]  		// display the digits numbers from R6 and R5 on HEX
		LDR     R8, =0xFF200030 	// base address of HEX5-HEX4
			

		// code for r7
		MOV     R0, R7          // display R5 on HEX1-0
        	BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            	MOV     R9, R1          // save the tens digit
            	BL      SEG7_CODE       
            	MOV     R4, R0          // save bit code
            	MOV     R0, R9          // retrieve the tens digit, get bit code
            	BL      SEG7_CODE       
            	LSL     R0, #8
            	ORR     R4, R0			
		STR     R4, [R8]        // display the number from R7
           
		B	END 

DIVIDE:     	MOV    R2, #0
CONT:       	CMP    R0, #10
            	BLT    DIV_END
            	SUB    R0, #10
            	ADD    R2, #1
            	B      CONT
DIV_END:    	MOV    R1, R2     // quotient in R1 (remainder in R0)
            	MOV    PC, LR

ALT_NUM:	.word 	0x55555555
TEST_NUM: 	.word 	0xffffff00
			.word   0xffffffff
			.word 	0x000000ff
			.word 	0xaaaa0000
			.word 	0 
			.end