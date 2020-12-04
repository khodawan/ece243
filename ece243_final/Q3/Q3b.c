// Q3 (b)

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h> 
	
// global variables 
volatile int * int_timer_ptr = (int *) 0xFF202000; 
volatile int * LEDR_ptr = (int *) 0xFF200000; 
volatile int * KEY_ptr = (int *) 0xFF200050; 

// use indexing to light up one LEDR at a time
char led[] = {0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200}; 
char led_rev[] = {0x200, 0x100, 0x80, 0x40, 0x20, 0x10, 0x8, 0x4, 0x2, 0x1};

// 250ms timer: count from 25 million = 101111101 0111100001000000 in binary 
#define HIGH_START 0x17D 	// high bits (16-32) converted to hex
#define LOW_START 0x7840	// low bits (0-15) converted to hex 
	
int main(){

	
	// endless loop
	while (1){
		
		// iterate through each of the LEDRs 
		for (int i=0; i < 10; i++){
			
			if ( *(KEY_ptr) != 0) 
				*(LEDR_ptr) = led_rev[i]; 
			else 
				*(LEDR_ptr) = led[i]; 
			
			int check = 0; 		// to check when TO flag is raised in status reg
			
			// load reg with 25mill
			*(int_timer_ptr + 2) = LOW_START;
			*(int_timer_ptr + 3) =  HIGH_START; 
			
			// write to control reg: START = 1, CONT = 0, no interrupts
			*(int_timer_ptr +1) = 0x4;
			
			// while TO flag not raised, do nothing
			while (!check){			
				check = ( *(int_timer_ptr) & 0x1); // read TO bit in status register 
			}
			
			// once TO flag raised, restart for loop, thus changing the LEDR  
			
			*(int_timer_ptr) = 0x0000; // reset TO by writing 0 to it  
		}
		
		// once for loop done, while loop restarts it 
	}
} 


	
	
	