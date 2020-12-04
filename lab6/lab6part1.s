/* Lab6 part 1. 
 * Toggles between # and blank on HEX displays 3, 2, 1, and 0 based on KEY 3, 2, 1, 0 pushbuttons. 
 * first press shows appropriate number, second press clears display */ 
 
/* utilized Cyclone V FPGA devices */
/* from provided lab files */ 
.equ  LEDR_BASE,             0xFF200000
.equ  HEX3_HEX0_BASE,        0xFF200020
.equ  HEX5_HEX4_BASE,        0xFF200030
.equ  SW_BASE,               0xFF200040
.equ  KEY_BASE,              0xFF200050
.equ  TIMER_BASE,            0xFF202000

/* utilized Interrupt controller (GIC) CPU interface(s) */
/* from provided lab files */     

.equ		CPU0,         				0x01	// bit-mask; bit 0 represents cpu0
.equ		KEY0, 					0b0001
.equ		KEY1, 					0b0010
.equ		KEY2,					0b0100
.equ		KEY3,					0b1000

.equ		USER_MODE,				0b10000
.equ		FIQ_MODE,				0b10001
.equ		IRQ_MODE,				0b10010
.equ		SVC_MODE,				0b10011
.equ		ABORT_MODE,				0b10111
.equ		UNDEF_MODE,				0b11011
.equ		SYS_MODE,				0b11111


/* utililized FPGA interrupts */
.equ	INTERVAL_TIMER_IRQ, 			72
.equ	KEYS_IRQ, 				73

/* utilized ARM A9 MPCORE devices */
.equ	MPCORE_PRIV_TIMER_IRQ,		29

/* from given ISR file */ 
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
            .global  _start 

/* start of main program */ 

_start:         

/* Set up stack pointers for IRQ and SVC processor modes (following outline from lecture notes) */ 
                MOV      R0, #SVC_MODE   	
                MSR      CPSR, R0		// current mode is SVC
                LDR      SP, =0x20000		// configure SVC mode stack pointer

                MOV      R0, #IRQ_MODE    	
                MSR      CPSR, R0		// current mode is IRQ
                LDR      SP, =0x3FFFFFFC 	// IRQ mode stack pointer

                BL       CONFIG_GIC      	// configure ARM generic interrupt controller


/* Configure  KEY pushbuttons port to generate interrupts */
                LDR     R0, =KEY_BASE		
                MOV     R1, #0b1111 			
                STR     R1, [R0, #0x8]   // Enables interrupt for all KEY buttons

/* Enable IRQ interrupts in  ARM processor */
                MOV     R0, #0b01010011	// IRQ unmasked, MODE = SVC
                MSR     CPSR, R0        //copies contents of r0 into CPSR

IDLE:                                    
                B        IDLE            // main program simply idles

/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU interface
                                        

KEYS_HANDLER:                       
                CMP      R5, #KEYS_IRQ   // check the interrupt ID

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
                BL       KEY_ISR         

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception

.global KEY_ISR

/* KEY_ISR subroutine
 * R7 used as pointer to KEY to determine which key raised interrupt
 * R6 used as pointer to HEX displays 
 * R1 reads KEYs to see which KEY(s) pushed. 
 * R2 used to load correct seg7 bit codes into HEX 3, 2, 1, and 0 displays 
 * R3 used as comparison register to check whether a given KEY is pressed 
*/ 
KEY_ISR:    	PUSH	{R0-R7}
         	LDR 	R7, =KEY_BASE
         	LDR 	R1, [R7, #0xC]			// read edge capture to see which KEY(s) pressed 
         	STR 	R1, [R7, #0xC]   		// Disable edge capture 
         	LDR 	R7, =PREVIOUS
         	LDR 	R2, [R7]
         	EOR 	R1, R2		       		// Toggles to flip HEX display from showing # to going blank 
         	STR 	R1, [R7]         		// Reset key value

         	LDR 	R6, =HEX3_HEX0_BASE 	// points to HEX3-0 
         	MOV 	R2, #0				// reset R2 to be used for holding # to load into HEX display

/* check if KEY0 pressed */ 
		MOV 	R3, #KEY0				 
		ANDS 	R3, R1		// compare current pattern of pressed keys to R3
		BEQ 	CHECK_KEY1		// if not a match, move on to check next key 
		MOV 	R2, #0b00111111		// if a match, update R2 to hold seg7 code for displaying 0

/* check if KEY1 pressed */ 
CHECK_KEY1: 
		MOV 	R3, #KEY1
		ANDS 	R3, R1
		BEQ 	CHECK_KEY2
		MOV 	R3, #0b00000110		// seg7 code for 1
		ORR 	R2, R3, LSL #8		// shift to fall into HEX1 address

/* check if KEY2 pressed */ 
CHECK_KEY2: 
		MOV 	R3, #KEY2
		ANDS 	R3, R1
		BEQ 	CHECK_KEY3
		MOV 	R3, #0b01011011		// seg7 code for 2
		ORR 	R2, R3, LSL #16		// shift to fall into HEX2 address

/* check if KEY3 pressed */ 
CHECK_KEY3: 
		MOV 	R3, #KEY3
		ANDS 	R3, R1
		BEQ 	END_KEY_ISR
		MOV 	R3, #0b01001111		// seg7 code for 3
		ORR 	R2, R3, LSL #24		// shift to fall into HEX3 address 

END_KEY_ISR: 
		STR 	R2, [R6]    		// update HEX displays
       		POP	{R0-R7}
		BX 	LR

		.global PREVIOUS 
PREVIOUS:   	.word   0b0000

/* Undefined instructions */
SERVICE_UND:		B   SERVICE_UND  

/* Software interrupts */
SERVICE_SVC:        B   SERVICE_SVC

/* Aborted data reads */
SERVICE_ABT_DATA:   B   SERVICE_ABT_DATA 

/* Aborted instruction fetch */
SERVICE_ABT_INST:   B   SERVICE_ABT_INST 

SERVICE_FIQ:        B   SERVICE_FIQ         

/* Configure Generic Interrupt Controller (GIC) */
/* provided in lab files */ 
.global	CONFIG_GIC

CONFIG_GIC:		PUSH		{LR}
    			/* Configure A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #MPCORE_PRIV_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #INTERVAL_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #KEYS_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT

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
    
    			POP     	{PC}
/* Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target   */
CONFIG_INTERRUPT:
    			PUSH		{R4-R5, LR}
    
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
    			LDR		R3, [R4]								// read current register value
    			ORR		R3, R3, R2							// set the enable bit
    			STR		R3, [R4]								// store the new register value

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
				STRB		R1, [R4]
    
    			POP		{R4-R5, PC}

                
				.end                                    

