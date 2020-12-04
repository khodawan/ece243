// Question 2c 
// honestly have no clue how to implement this 

.equ  	HEX3_HEX0_BASE,        0xFF200020
.equ  	HEX5_HEX4_BASE,        0xFF200030
.equ  	SW_BASE,               0xFF200040

.equ		A9_TIMER_BASE, 		0xFFFEC600
.equ		LEDR_BASE,			0xFF200000

.equ		IRQ_MODE,			0b10010
.equ		SVC_MODE,			0b10011

.equ		CPU0,         		0x01
.equ 		A9_TIMER_IRQ,		29 

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

/* from provided ISR file */ 
.section 	.vectors, "ax"
		B        _start              // reset vector
        B        SERVICE_UND         // undefined instruction vector
        B        SERVICE_SVC         // software interrupt vector
        B        SERVICE_ABT_INST    // aborted prefetch vector
		B        SERVICE_ABT_DATA    // aborted data vector
     	.word    0                   // unused vector
        B        SERVICE_IRQ         // IRQ interrupt vector
		B        SERVICE_FIQ         // FIQ interrupt vector
	
	.text 
	.global _start
	
// global variable for writing to ledr0 
			.global CHECK 
CHECK:		.word 0x1

_start:			MOV      R0, #IRQ_MODE    	// IRQ mode
				MSR      CPSR, R0			// current mode is irq
				LDR      SP, =0x20000	 	// configure SVC mode stack pointer

				MOV      R0, #SVC_MODE   	// SVC mode
				MSR      CPSR, R0			// current mode is svc
				LDR      SP, =0x40000		// configure IRQ mode stack pointer


				BL       CONFIG_GIC       // configure ARM gic from lab 6
				BL       CONFIG_TIMER     // configure A9 Timer 

				/* Enable IRQ interrupts in ARM processor */
				MOV     R0, #0b01010011	// IRQ unmasked, MODE = SVC
				MSR     CPSR, R0 

				LDR		R4, =SW_BASE			// pointer to sw
				LDR		R5, =HEX3_HEX0_BASE		// pointer to hex3-0
				LDR		R6, =HEX5_HEX4_BASE		// pointer to hex5-4

				MOV		R0, #zero_seg			// use R0 to store data for HEX3-0
				STR		R0, [R5]				// show 0 in hex0 to start, will always remain there 

				MOV		R1, #0					// use R1 to store data for HEX5-4
			
MAIN:			LDR		R2, [R4]				// read SW value 

				CMP		R2, #ONE				
				BLEQ	HEX_ONE					// subroutine to show 1 in hex1

				CMP		R2, #TWO
				BLEQ	HEX_TWO					// subroutine to show 2 in hex2

				CMP 	R2, #THREE
				BLEQ	HEX_THREE				// subroutine to show 3 in hex3

				CMP		R2, #FOUR	
				BLEQ	HEX_FOUR				// subroutine to show 4 in hex4

				CMP		R2, #FIVE				// subroutine to show 5 in hex5
				BLEQ	HEX_FIVE
				
				MOV		R2, #CHECK				// check bit alternates between 0 and 1 based on interrupt 
				CMP		R2, #0
				STREQ	R2, [R5]
				STREQ	R2, [R6]
				B		MAIN 					// loop back if no condition entered

HEX_ONE:	MOV		R3, #one_seg			// seg_7 code for 1
			LSL		R3, #8					// shift to fall into hex1 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 0
			STR		R0, [R5]				// show on hex display	
			MOV		PC, LR					// loop back to main 

HEX_TWO:	MOV		R3, #two_seg		
			LSL		R3, #16					// shift to fall into hex2 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 1 and 0 
			STR		R0, [R5]				// show on hex display
			MOV		PC, LR	

HEX_THREE: 	MOV		R3, #three_seg
			LSL		R3, #24					// shift to fall into hex3 bounds
			ORR		R0, R3					// ORR to not wipe out seg_7 code for 2, 1, 0
			STR		R0, [R5]				// show on hex display
			MOV		PC, LR	

HEX_FOUR:	MOV		R3, #four_seg
			ORR		R1, R3					// no need to shift for hex4 base address
			STR		R1, [R6]
			MOV		PC, LR	

HEX_FIVE: 	MOV		R3, #five_seg
			LSL		R3, #8					// shift to reach hex5 bounds 
			ORR		R1, R3					// orr to not wipe out seg_7 code for 4
			STR		R1, [R6]				// show on hex display
			MOV		PC, LR	


SERVICE_IRQ: 
				PUSH     {R0-R7, LR}     
				LDR      R4, =0xFFFEC100 // GIC CPU interface base address
				LDR      R5, [R4, #0x0C] // read ICCIAR in CPU interface
				
TIMER_HANDLER:	
				CMP		R5, #A9_TIMER_IRQ	// check interrupt ID
				BLEQ 	TIMER_ISR
		
EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt Register
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception

TIMER_ISR:		PUSH 	{R0-R3}
				LDR 	R1, =A9_TIMER_BASE 
				MOV 	R0, #1			// clear F bit by writing 1 to 
				STR 	R0, [R1, #0xC] 	// interrupt status reg
										
				LDR		R3, =CHECK
				LDR		R2, [R3]
				MVN		R2, R2 			// alternate value of R3 (0 or 1) 
				AND		R2, #0b1
				STR		R2, [R3]		// update check 
				
				B 		END_TIMER_ISR

END_TIMER_ISR:	POP		{R0-R3}
				BX		LR


/* Configure Timer to create interrupts at 0.5 second intervals */
CONFIG_TIMER:  	PUSH 	{R0, R1}
				LDR		R0, =A9_TIMER_BASE	
				LDR		R1, =50000000	// starting value for 0.5 sec interval
				
				// store starting value in counter start value register of interval timer 
				STR		R1, [R0]		
               	
				// set enable, interrupt, auto
				MOV		R1, #0b0111	
				STR		R1, [R0, #0x8]
				POP 	{R0, R1}
                BX      LR 


/* Configure the Generic Interrupt Controller (GIC) from given lab files */ 
.global	CONFIG_GIC

CONFIG_GIC:
				PUSH	{LR}
    			
				/* Configure the A9 Private Timer interrupt, r
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #A9_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL		CONFIG_INTERRUPT
   				// i removed configurations for interval times and KEYs

				/* configure the GIC CPU interface */
    			LDR		R0, =0xFFFEC100		// base address of CPU interface
    			/* Set Interrupt Priority Mask Register (ICCPMR) */
    			LDR		R1, =0xFFFF 			// enable interrupts of all priorities levels
    			STR		R1, [R0, #0x04]
    			/* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
				 * allows interrupts to be forwarded to the CPU(s) */
    			MOV		R1, #1
    			STR		R1, [R0]
    
    			/* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
				 * allows the distributor to forward interrupts to the CPU interface(s) */
    			LDR		R0, =0xFFFED000
    			STR		R1, [R0]    
    
    			POP     {PC}
/* 
 * Configure registers in GIC for individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
    			PUSH	{R4-R5, LR}
    
    			/* Configure Interrupt Set-Enable Registers (ICDISERn). 
				 * reg_offset = (integer_div(N / 32) * 4
				 * value = 1 << (N mod 32) */
    			LSR		R4, R0, #3							// calculate reg_offset
    			BIC		R4, R4, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED100
				ADD		R4, R2, R4							// R4 = address of ICDISER
    
    			AND		R2, R0, #0x1F   					// N mod 32
				MOV		R5, #1								// enable
    			LSL		R2, R5, R2							// R2 = value

				/* now that we have the register address (R4) and value (R2), we need to set the
				 * correct bit in the GIC register */
    			LDR		R3, [R4]							// read current register value
    			ORR		R3, R3, R2							// set the enable bit
    			STR		R3, [R4]							// store the new register value

    			/* Configure Interrupt Processor Targets Register (ICDIPTRn)
     			 * reg_offset = integer_div(N / 4) * 4
     			 * index = N mod 4 */
    			BIC		R4, R0, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED800
				ADD		R4, R2, R4							// R4 = word address of ICDIPTR
    			AND		R2, R0, #0x3						// N mod 4
				ADD		R4, R2, R4							// R4 = byte address in ICDIPTR

				/* now that we have the register address (R4) and value (R2), write to (only)
				 * the appropriate byte */
				STRB	R1, [R4]
    
    			POP		{R4-R5, PC}

/* Undefined instructions */
SERVICE_UND:                                
                B   SERVICE_UND         
/* Software interrupts */
SERVICE_SVC:                                
                B   SERVICE_SVC         
/* Aborted data reads */
SERVICE_ABT_DATA:                           
                B   SERVICE_ABT_DATA    
/* Aborted instruction fetch */
SERVICE_ABT_INST:                           
                B   SERVICE_ABT_INST    
SERVICE_FIQ:                                
                B   SERVICE_FIQ 

			 	
				.end  
	
	