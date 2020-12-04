.equ  	HEX3_HEX0_BASE,        0xFF200020
.equ  	HEX5_HEX4_BASE,        0xFF200030
.equ  	SW_BASE,               0xFF200040

// to compare SW values against 
.equ	ONE,					0b001
.equ	TWO,					0b010
.equ	THREE,					0b011
.equ	FOUR,					0b100
.equ	FIVE,					0b101

// seg_7 codes for the numbers 
.equ	zero_seg,				0x3f
.equ	one_seg,				0x06
.equ	two_seg,				0x5b
.equ	three_seg,				0x4f
.equ	four_seg,				0x66
.equ	five_seg,				0x6d

.global _start
_start:

			LDR		R4, =SW_BASE			// pointer to sw
			LDR		R5, =HEX3_HEX0_BASE		// pointer to hex3-0
			LDR		R6, =HEX5_HEX4_BASE		// pointer to hex5-4
			
			MOV		R0, #zero_seg			// use R0 to store data for HEX3-0
			STR		R0, [R5]				// show 0 in hex0 to start, will always remain there 
			
			MOV		R1, #0					// use R1 to store data for HEX5-4
			
MAIN:		LDR		R2, [R4]				// read SW value 
			
			CMP		R2, #ONE				
			BEQ		HEX_ONE					// subroutine to show 1 in hex1
			
			CMP		R2, #TWO
			BEQ		HEX_TWO					// subroutine to show 2 in hex2
			
			CMP 	R2, #THREE
			BEQ		HEX_THREE				// subroutine to show 3 in hex3
			
			CMP		R2, #FOUR	
			BEQ		HEX_FOUR				// subroutine to show 4 in hex4
			
			CMP		R2, #FIVE				// subroutine to show 5 in hex5
			BEQ		HEX_FIVE
			
			B		MAIN 					// loop back if no condition entered

HEX_ONE:	MOV		R3, #one_seg			// seg_7 code for 1
			LSL		R3, #8					// shift to fall into hex1 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 0	
			STR		R0, [R5]				// show on hex display	
			B		MAIN					// loop back to main 

HEX_TWO:	MOV		R3, #two_seg		
			LSL		R3, #16					// shift to fall into hex2 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 1 and 0 
			STR		R0, [R5]				// show on hex display
			B		MAIN

HEX_THREE: 	MOV		R3, #three_seg
			LSL		R3, #24					// shift to fall into hex3 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 2, 1, 0
			STR		R0, [R5]				// show on hex display
			B		MAIN

HEX_FOUR:	MOV		R3, #four_seg
			ORR		R1, R3					// no need to shift for hex4 base address
			STR		R1, [R6]
			B		MAIN

HEX_FIVE: 	MOV		R3, #five_seg
			LSL		R3, #8					// shift to reach hex5 bounds 
			ORR		R1, R3					// orr to not wipe out seg_7 code for 4
			STR		R1, [R6]				// show on hex display
			B		MAIN
			
			

	
	