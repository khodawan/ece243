/* program that counts from 0 to 99 automatically. pauses count whenever a KEY button is pushed, and continues once button is released */

.text 
.global _start

_start:
			MOV 	R0, #0			// R0 tracks number to display on HEX
			LDR 	R8, =0xFF200030 
			STR 	R0, [R8] 		// set HEX5 and 4 to nothing always 
			LDR 	R8, =0xFF200020
			STR	R0, [R8]		// set HEX3 to 0 to nothing to start 
			LDR	R9, =0xFF20005C		// edge capture address 
			MOV	R5, #15			// else if key pressed,
			STR 	R5, [R9]		// initial reset of edge capture addresses
			
			
MAIN:		
			CMP 	R0, #99
			MOVGT	R0, #0x0		// reset to 0 if needed (prevent overflow)
			
			//MOV	R5, #15			// else if key pressed 
			//STR 	R5, [R9]		// initial reset of edge capture addresses
						
			LDR	R9, =0xFF200050	
			LDR 	R5, [R9]  
			CMP	R5, #0	 		// check if any key pressed 
			
			ADDEQ 	R0, #1			// if no key pressed, increment number to be displayed 
			BEQ 	DISPLAY
			
			MOV	R5, #15			// else if key pressed 
			STR 	R5, [R9]		// initial reset of edge capture addresses
			
/* Subroutine to display decimal number on HEX0 */
DISPLAY:    		PUSH	{R0}			// R0 used in DIVIDE and SEG7 subroutines
			BL      DIVIDE 			// generates decimal to pass to SEG7_CODE 
           		PUSH	{R1}			// save 10s digit 
		    	BL      SEG7_CODE		// generates bit code for number to display on HEX 
			POP	{R1}			// get back 10s digit 
			PUSH 	{R0} 			// save bit code of 1s digit
			MOV	R0, R1 			// place 10s digit in R0 to be passed to SEG7 subroutine
			BL	SEG7_CODE
			MOV	R1, R0			// store bit code of 10s digit 
			LSL	R1, #8			// shift bit code so that 1s digit bit code can be added 
			POP	{R0}			// retrieve 1s digit bit code 
			ORR	R0, R1 			// combine bit codes for both digits 
			
			STR	R0, [R8]		// load bit code to HEX display 		
			
			POP	{R0}			// restore value of R0 
			
			B	DO_DELAY

			
/* delay counter subroutine used to update HEX display every 0.25 seconds */				
DO_DELAY: 		LDR 	R7, =200000000 		// note: # was changed to 100 for CPUlator simulations 
SUB_LOOP: 		SUBS   	R7, R7, #1
			BNE    	SUB_LOOP
			B	MAIN 			// return to MAIN once R7 reaches 0

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