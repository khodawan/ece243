/* required memory address from ARM address map provided in lab 6 */
.equ  PIXEL_BUF_CTRL_BASE,   0xFF203020

/* required constants */ 
.equ	BLACK,	0x0000
.equ	X_MAX,	320
.equ	Y_MAX,	240
.equ	WHITE,	0xFFFF

.global _start
_start:

		/* global ptr to pixel buffer controller*/ 
		LDR		R12, =PIXEL_BUF_CTRL_BASE


// Question 1(e)
/* 
* subroutine to draw an animated horizontal white line 
* that extends from x-100 to x-220 
*/ 

MAIN: 		B 		CLEAR_SCREEN
			
			/* initialize R0-R3 with required info for draw_line */
			MOV		R0, #100
			MOV		R1, #220
			MOV		R2, #0
			LDR		R3, =WHITE
			B 		DRAW_LINE
			
MAIN_LOOP:	B		WAIT_FOR_VSYNC
			MOV		R0, #100
			MOV		R1, #220
			MOV		R2, #0
			MOV		R3, #BLACK
			PUSH	{R2}	// will need to modify y coord throughout main 
			B		DRAW_LINE
			POP		{R2}
			ADD		R2, #1 
			CMP		R2, #0 
			SUBEQ	R2, #1 
			CMP		R2, #239
			SUBEQ	R2, #1 
			PUSH	{R2}
			LDR		R3, =WHITE
			POP		{R2}
			B		MAIN_LOOP
// Question 1(a)

/* subroutine: 
* does not exit until S bit == 0 in pixel buff status reg
*/  
WAIT_FOR_VSYNC:	
		LDR 	R0, [R12, #0xC] // load R0 with memory contents at status register address
		AND 	R0, #1			// isolate S bit 
		CMP		R0, #0			// when S bit = 0, it means sync is done 		
		BNE		WAIT_FOR_VSYNC 	// stay within subroutine until S bit becomes 0 
		MOV		PC, LR
		
		
// Question 1(c) 

/* 
* subroutine to clear screen, using black colour 
* prior to calling plot_pixel:
	* R0 must hold x coord of pixel 
	* R1 must hold y coord of pixel
	* R2 must hold color of pixel as 16 bits, ASSUMPTION: held in bits 0 to 15 in reg, does not require adjustment 
* note that plot_pixel modifies R3 to access memory address 
*/ 
CLEAR_SCREEN: 	
		MOV		R0, #0		// use R0 as x coord
		MOV		R1, #0		// use R1 as y coord
		MOV		R2, #BLACK 	// R2 holds colour = 0 
				

Y_LOOP:	PUSH	{LR}		// nested subroutine
		B		PLOT_PIXEL
		POP 	{LR}
		ADD		R1, #1 
		CMP		R1, #Y_MAX
		BNE		Y_LOOP		// iterate thru columns while within y bounds
				
		MOV		R1, #0		// reset y value after filling a row 
		ADD		R0, #1 		// move down a row after filling a row 
		CMP 	R0, #X_MAX
		BNE		Y_LOOP		// iterate thru next row while within x bounds		
		MOV		PC, LR

// Question 1(d) 

/* 
* subroutine to draw a line 
* R0 holds x0 coord
* R1 holds x1 coord
* R2 holds y coord
* R3 holds color 
* prior to calling plot_pixel:
	* R0 must hold x coord of pixel 
	* R1 must hold y coord of pixel
	* R2 must hold color of pixel as 16 bits, ASSUMPTION: held in bits 0 to 15 in reg, does not require adjustment 
* note that plot_pixel modifies R3 to access memory address 
*/
DRAW_LINE: 	PUSH 	{R4, LR} 
			MOV		R4, R1		// store x1 coord, as R1 must be changed before calling plot_pixel 
				
			MOV 	R1, R2 		// R1 holds y coord, required by plot_pixel
			MOV 	R2, R3		// R2 holds colour, required by plot_pixel
LOOP:		B		PLOT_PIXEL 
			ADD		R0, #1 		// while in loop, continue to increase x coord by 1 
			CMP 	R0, R4 		// check if bound reached 
			BNE		LOOP 		// continue plotting pixel while bound not reached 
			B		PLOT_PIXEL 	// must draw final pixel on line 
			POP		{R4, LR}	// restore non-scratch register used in subroutine 
			MOV		PC, LR
			
			
// Question 1(b)

/* 
* R0 holds x coord of pixel
* R1 holds y coord of pixel
* R2 holds color of pixel as 16 bits, ASSUMPTION: held in bits 0 to 15 in reg, does not require adjustment 
* use R3 to access memory address 
*/ 				
PLOT_PIXEL:		
		/* pixel address = base + y << 10 + x << 1 */ 
		LSL 	R0, R0, #1 		// must shift x address left 1 
		LSL 	R1, R1, #10		// must shift y address left 10 
		ADD		R3, R0, R1 		// combine x and y addresses to be added to base address
		STRH 	R2, [R12, R3] 	// store pixel colour at pixel address in memory  
		MOV		PC, LR
