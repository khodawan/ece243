// Q3 (d) 
#include <stdlib.h>
#include <stdio.h>

volatile int * HEX3_0_ptr = (int *)0xFF200020;
volatile int * HEX5_4_ptr = (int *) 0xFF200030; 
volatile int * KEY_ptr = (int *) 0xFF200050; 
volatile int * int_timer_ptr = (int *) 0xFF202000;  

// 250ms timer: count from 25 million = 101111101 0111100001000000
#define HIGH_START 0x17D	// high bits (16-32) converted to hex
#define LOW_START 0x7840	// low bits (0-15) converted to hex
	
// 125ms timer: count from 12.5 million = 10111110 1011110000100000
#define FAST_HIGH_START 0xBE
#define FAST_LOW_START 0xBC20
	
	
// 500ms timer: count from 50 million = 1011111010 1111000010000000
#define SLOW_HIGH_START 0x2FA
#define SLOW_LOW_START	0xF080
	
#define KEY0 0x01
#define KEY1 0x02
#define KEY2 0x04
#define KEY3 0x08


// function declarations 
void show(int i);
void show_rev(int i); 

// U of t ECE-243 in array 
char seg_7[] = {0x3e, 0x00000000, 0x5c, 0x71, 0x00000000, 0x78, 0x00000000, 0x79, 0x39, 0x79, 0x40, 0x5b, 0x66, 0x4f}; 
char seg_7_rev[] = {0x4f, 0x66, 0x5b, 0x40, 0x79, 0x39, 0x79, 0x00000000, 0x78, 0x00000000, 0x71, 0x5c, 0x00000000, 0x3e}; 
 

int main () {

	// endless loop 
	while (1){
		
		for (int i = 0; i < 14; i++) {
			
			int key_check =  *(KEY_ptr); 
			
			// if key3 pressed, reverse direction 
			if (key_check == KEY3)
				show_rev(i);
			else 
				show(i); 
			
			// pause if key0 pressed 
			if (key_check == KEY0) 
				while ( key_check != 0)
					key_check = *(KEY_ptr); 
			
			int check = 0; 		// to check when TO flag is raised in status reg
			
			// speed up scroll speed if key1 pressed 
			if (key_check == KEY1) {
				*(int_timer_ptr + 2) = FAST_LOW_START;
				*(int_timer_ptr + 3) =  FAST_HIGH_START; 
			} 
			
			// slow down speed if key2 pressed 
			else if (key_check == KEY2) {
				*(int_timer_ptr + 2) = SLOW_LOW_START;
				*(int_timer_ptr + 3) =  SLOW_HIGH_START;
			}
			else {
				// load reg with 25mill
				*(int_timer_ptr + 2) = LOW_START;
				*(int_timer_ptr + 3) =  HIGH_START; 
			}
			
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


void show_rev(int i){
	*HEX3_0_ptr = seg_7_rev[i] | seg_7_rev[i+1] << 8 | seg_7_rev[i+2] << 16 | seg_7_rev[i+3] << 24;
	*HEX5_4_ptr = seg_7_rev[i+4] | seg_7_rev[i+5] << 8;
}

	