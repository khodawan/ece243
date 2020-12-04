/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
            STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the list
 *             R1 has the address of the start of the list
 *	       R2 and R3 used as dummy registers to keep track of largest element 
 * Returns: R0 returns the largest item in the list
 */

LARGE: 		LDR 	R2, [R1],#4 	// R2 stores first element in NUMBERS list
ITERATE: 	SUBS 	R0, #1 		// decrement thru list
		BEQ 	IT_END 		// stop iterating when all elements iterated thru
		LDR 	R3, [R1],#4 	// R3 holds next element in NUMBERS list
		CMP 	R2, R3 		// compare values
		BGE 	ITERATE 	// if current value in R2 larger, continue iterating
		MOV 	R2, R3 		// if compared value larger, update R2 with this value
		B 	ITERATE 	// then, continue iterating thru NUMBERS list
IT_END: 	MOV 	R0, R2 		// update R0 to hold largest element (for correct return)
		MOV 	PC, LR 		// return to start (required step) 

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            

