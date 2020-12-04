.global _start
_start:			LDR 	R8, =0xFFFEC600			// address of A9 private timer
			LDR	R2, =5000000
			STR	R2, [R8] 			// load 5 mill into starting count of internal timer
			MOV	R2, #0b011
			STR	R2, [R8, #8] 			// write to control register (set A bit and E bit)

			MOV 	R0, #0				// R0 tracks number to display on HEX
			LDR 	R7, =0xFF200030 
			STR 	R0, [R7] 			// set HEX5 and 4 to nothing always 
			LDR 	R7, =0xFF200020
			STR	R0, [R7]			// set HEX3 to 0 to nothing to start 
			
			LDR	R9, =0xFF20005C			// edge capture address 
			MOV	R5, #15				// 
			STR 	R5, [R9]			// initial reset of edge capture addresses
			
			
	
MAIN: 			CMP 	R0, #99
			MOVGT	R0, #0x0			// reset to 0 if needed (prevent overflow)
			
			LDR	R9, =0xFF200050	
			LDR 	R5, [R9]  
			CMP	R5, #0	 			// check if any key pressed 
			
			ADDEQ 	R0, #1				// if no key pressed, increment number to be displayed 
			BEQ 	DISPLAY
			
			MOV	R5, #15				 
			STR 	R5, [R9]			// reset edge capture addresses
			
/* from part 2 of pre-lab. 
* modified to use R7 as register to access HEX addresses.
* calls DELAY subroutine instead of DO_DELAY as in part 2 
*/ 			
DISPLAY:    		PUSH	{R0}			
			BL      DIVIDE 			 
           		PUSH	{R1}			
		    	BL      SEG7_CODE		
			POP	{R1}			
			PUSH 	{R0} 			
			MOV	R0, R1 			
			BL	SEG7_CODE
			MOV	R1, R0
			LSL	R1, #8
			POP	{R0}
			ORR	R0, R1 
			
			STR	R0, [R7]			
			
			POP	{R0}
			
			B	DELAY						

/* delay subroutine from lecture notes */ 
DELAY:			LDR	R2, [R8, #0xc]		// read status register 
			CMP 	R2, #0
			BEQ	DELAY			// wait for F bit (interrupt status)
			STR	R2, [R8, #0xc]		// reset F bit 
			B	MAIN
			

/* Subroutine from previous labs - displays decimal number on HEX0 */ 
SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment


/* Subroutine from previous labs - converts binary to decimal for display on HEX */
DIVIDE:     MOV    	R2, #0x0
CONT:       CMP    	R0, #10
            BLT   	DIV_END
            SUB    	R0, #10
            ADD    	R2, #1
            B      	CONT
DIV_END:    MOV    	R1, R2     // quotient in R1 (remainder in R0)
            MOV    	PC, LR