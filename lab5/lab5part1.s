.text 
.global _start
_start:
			MOV 	R0, #0				// R0 tracks number to display on HEX
			LDR 	R6, =0xFF200030 
			STR 	R0, [R6] 			// set HEX5 and 4 to nothing always 
			LDR 	R8, =0xFF200020
			STR	R0, [R8]			// set HEX3 to 0 to nothing to start 
			
MAIN:			CMP 	R0, #0x9
			MOVEQ	R0, #0x0			// reset to 0 if needed (prevent overflow)
			
			LDR 	R7, =0xFF200050			// R7 points to keys 
			LDR	R7, [R7]			// R7 holds value of keys 
			
			CMP	R7, #0x8 			// KEY = 4'b1000, KEY3 pressed 
			BGE	BLANK_HEX 			// subroutine to clear HEX display 
			
			CMP 	R7, #0x4			// KEY = 4'b0100, KEY2 pressed
			SUBEQ   R0, #0x1			// decrement value of inc/dec register
			
			CMP 	R7, #0x2			// KEY = 4'b0010, KEY1 pressed
			ADDEQ	R0, #0x1			// increment value of inc/dec register
			
			CMP	R7, #0x1			// KEY = 4'b0001, KEY0 pressed 
			BEQ	ZERO_HEX			// subroutine to reset counter & HEX
			
			CMP 	R7, #0x0			// KEY = 4'b0000, no key pressed 
			BEQ	MAIN				// loop back thru MAIN if nothing pressed 
			
			B	DISPLAY				// else, branch to subroutine to update HEX0

BLANK_HEX:		MOV	R0, #0
			LDR	R8, =0xFF200020
			STR 	R0, [R8]			// reset HEX0 to display nothing	

BLANK_LOOP: 		LDR	R2, =0xFF200050
			LDR	R2, [R2] 
			CMP	R2, #0x0			// remain in BLANK state until KEY3 no longer pressed
			BNE	BLANK_LOOP
			MOV	R0, #0				// before returning to MAIN, reset counter 
			B 	MAIN 				
	
ZERO_HEX: 		MOV	R0, #0				// hardcode (reset) counter back to 0
			B 	DISPLAY				// branch to subroutine to display 0 on HEX0 

/* Subroutine to display decimal number on HEX0 */
DISPLAY:    		PUSH	{R0}			// R0 used in DIVIDE and SEG7 subroutines
			LDR     R8, =0xFF200020 	// base address of HEX3-HEX0
			BL      DIVIDE 			// generates decimal number to pass to SEG7_CODE 
           		BL      SEG7_CODE		// generates bit code for number to display on HEX 
			MOV	R4, R0 			// R4 holds bit code from SEG7_CODE subroutine 
			STR	R4, [R8] 		// show number on HEX 
DISP_LOOP: 		LDR	R2, =0xFF200050
			LDR	R2, [R2] 		// read KEY value
			CMP	R2, #0x0	
			BNE	DISP_LOOP		// continue to loop through DISPLAY subroutine until 
							// no key pressed 
			POP	{R0} 			
			B 	MAIN 			// once no keys pressed, return to MAIN 

/* Subroutine from previous labs - displays decimal number on HEX0 */ 
SEG7_CODE:  		MOV     R1, #BIT_CODES  
           		ADD     R1, R0         		// index into the BIT_CODES "array"
           		LDRB    R0, [R1]      		// load the bit pattern (to be returned)
            		MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      		// pad with 2 bytes to maintain word alignment


/* Subroutine from previous labs - converts binary to decimal for display on HEX */
DIVIDE:     		MOV    R2, #0x0
CONT:       		CMP    R0, #10
            		BLT    DIV_END
            		SUB    R0, #10
            		ADD    R2, #1
            		B      CONT

DIV_END:    		MOV    R1, R2    		// quotient in R1 (remainder in R0)
            		MOV    PC, LR	