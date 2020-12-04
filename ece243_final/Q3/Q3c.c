// Q3 (c) 
#include <stdlib.h>
#include <stdio.h>

volatile int * HEX3_0_ptr = (int *)0xFF200020;
volatile int * HEX5_4_ptr = (int *) 0xFF200030; 
volatile int * KEY_ptr = (int *) 0xFF200050; 

// global variables 
volatile int * int_timer_ptr = (int *) 0xFF202000;  

// 250ms timer: count from 25 million = 101111101 0111100001000000
#define HIGH_START 0x17D	// high bits (16-32) converted to hex
#define LOW_START 0x7840	// low bits (0-15) converted to hex 

// function declarations 
void show(int i);

// U of t ECE-243 in array 
char seg_7[] = {0x3e, 0x00000000, 0x5c, 0x71, 0x00000000, 0x78, 0x00000000, 0x79, 0x39, 0x79, 0x40, 0x5b, 0x66, 0x4f}; 
 

int main () {

	// endless loop 
	while (1){
		
		for (int i = 0; i < 14; i++) {
			show(i);
			
			int key_check =  *(KEY_ptr); 
			
			while ( key_check != 0)
				key_check = *(KEY_ptr); 
			
			int check = 0; 		// to check when TO flag is raised in status reg
			
			// load reg with 25mill
			*(int_timer_ptr + 2) = LOW_START;
			*(int_timer_ptr + 3) =  HIGH_START; 
			
			// write to control reg: START = 1, CONT = 0
			*(int_timer_ptr +1) = 0x4;
			
			// while TO flag not raised, do nothing
			while (!check){			
				check = ( *(int_timer_ptr) & 0x1); // reach TO in status register 
			}
			
			// once TO flag raised, restart for loop 
			*(int_timer_ptr) = 0x0000; // reset TO by writing 0 to it  
		}

	} 
}

// to display portion of U of t ECE-243 on hex  
void show(int i) {
	*HEX3_0_ptr = seg_7[i+5] | seg_7[i+4] << 8 | seg_7[i+3] << 16 | seg_7[i+2] << 24;
	*HEX5_4_ptr = seg_7[i+1] | seg_7[i] << 8; 
} 


	