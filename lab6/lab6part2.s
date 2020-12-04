/* lab6 part 2
 * running counter controlled by KEY toggle
 * counter displayed on LEDR 
*/

/* utilized Cyclone V FPGA devices from provided lab files */ 
.equ  LEDR_BASE,             	0xFF200000
.equ  KEY_BASE,             	0xFF200050
.equ  TIMER_BASE,            	0xFF202000                  

/* utilized Interrupt controller (GIC) CPU interface(s) from provided lab files */     
.equ	CPU0,         				0x01	// bit-mask; bit 0 represents cpu0
.equ	KEY0, 					0b0001
.equ	KEY1, 					0b0010
.equ	KEY2,					0b0100
.equ	KEY3,					0b1000

.equ	IRQ_MODE,				0b10010
.equ	SVC_MODE,				0b10011

/* utililized FPGA interrupts */
.equ	INTERVAL_TIMER_IRQ, 	72
.equ	KEYS_IRQ, 		73

/* utilized ARM A9 MPCORE devices */
.equ	MPCORE_GLOBAL_TIMER_IRQ,	27
.equ	MPCORE_PRIV_TIMER_IRQ,		29

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
            	.global  _start 

/* start of main program */ 

_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */			
		MOV      R0, #IRQ_MODE    	// IRQ mode
                MSR      CPSR, R0		// current mode is irq
                LDR      SP, =0x20000	 	// configure SVC mode stack pointer
				
		MOV      R0, #SVC_MODE   	// SVC mode
                MSR      CPSR, R0		// current mode is svc
                LDR      SP, =0x3FFFFFFc	// configure IRQ mode stack pointer


                BL       CONFIG_GIC       // configure the ARM generic
                                          // interrupt controller
                BL       CONFIG_TIMER     // configure the Interval Timer
                BL       CONFIG_KEYS      // configure the pushbutton KEYs port 

/* Enable IRQ interrupts in ARM processor */
		MOV     R0, #0b01010011	// IRQ unmasked, MODE = SVC
                MSR     CPSR, R0 
				  
                LDR      R5, =LEDR_BASE  
LOOP:                                          
                LDR      R3, COUNT        // global variable
                STR      R3, [R5]         // write to the LEDR lights
                B        LOOP                

SERVICE_IRQ: 
		PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface
KEYS_HANDLER:                       
                CMP      R5, #KEYS_IRQ   // check the interrupt ID
                BLEQ     KEY_ISR   

TIMER_HANDLER:	
		CMP	R5, #INTERVAL_TIMER_IRQ	// check the interrupt ID
		BLEQ 	TIMER_ISR

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception

KEY_ISR:	PUSH 	{R0, R1}
		LDR	R0, =KEY_BASE
		LDR	R1, [R0, #0xc]	// read edge capture
		STR	R1, [R0, #0xc]	// clear interrupt
		
		// toggle between run and don't run 
		LDR	R0, =RUN		
		LDR	R1, [R0]
		EOR	R1, #1		// switch toggle
		STR	R1, [R0]	 
		B	END_KEY_ISR

END_KEY_ISR:	POP 	{R0, R1}
		BX	LR

TIMER_ISR:	PUSH 	{R0-R2}
		LDR 	R1, =TIMER_BASE 
		MOV 	R0, #0
		STR 	R0, [R1] 	// clear interrupt
		LDR 	R0, =COUNT 	
		LDR 	R1, [R0]	// get count
		LDR 	R2, RUN		
		ADD 	R1, R2 		// increment count by run 
		STR 	R1, [R0]	// update count
		B 	END_TIMER_ISR

END_TIMER_ISR:	POP	{R0-R2}
		BX	LR	

/* Global variables */
                .global  COUNT                           
COUNT:          .word    0x0              // used by timer
                .global  RUN              // used by pushbutton KEYs
RUN:            .word    0x1              // initial value to increment COUNT

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
		LDR	R0, =KEY_BASE	// point to KEYs address
		MOV	R1, #0b1111	// to enable interrupt 
		STR	R1, [R0, #0x8] 	// shift needed to reach interrupt mask register of KEYs
               	BX   	LR                  

/* Configure Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:  	LDR	R0, =TIMER_BASE	
		LDR	R1, =25000000	// starting value needed for 0.25 sec interval
				
		// store starting value in counter start value register of interval timer 
		STR	R1, [R0, #0x8]		
		LSR	R1, #16
		STR 	R1, [R0, #0xc]
               	
		// set enable, interrupt, auto
		MOV	R1, #0b0111	
		STR	R1, [R0, #0x4]
                BX      LR 
 

/* Configure the Generic Interrupt Controller (GIC) from given lab files */ 
.global	CONFIG_GIC

CONFIG_GIC:
				PUSH	{LR}
    			
				/* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #MPCORE_PRIV_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #INTERVAL_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL		CONFIG_INTERRUPT
    			MOV		R0, #KEYS_IRQ
    			MOV		R1, #CPU0
    			BL		CONFIG_INTERRUPT

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

	