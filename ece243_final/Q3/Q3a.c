#include <stdlib.h>
#include <stdio.h>

volatile int * HEX3_0_ptr = (int *)0xFF200020;
volatile int * HEX5_4_ptr = (int *) 0xFF200030; 

// function declarations 
void show();
void blank();

// E C E 2 4 3 in array 
char seg_7[] = {0x79, 0x39, 0x79, 0x5b, 0x66, 0x4f}; 
 
// flashes ECE243 on HEX with ~0.5s breaks
int main () {

	// endless loop 
	while (1){
		show();
		for (int i = 0; i <= 1000; i++)
       		for (int j = 0; j <= 1000; j++)
       			{}
		blank();
		for (int i = 0; i <= 1000; i++)
       		for (int j = 0; j <= 1000; j++)
       			{}

	} 
}

// hex with ECE243 message 
void show() {
	*HEX3_0_ptr = seg_7[5] | seg_7[4] << 8 | seg_7[3] << 16 | seg_7[2] << 24;
	*HEX5_4_ptr = seg_7[1] | seg_7[0] << 8; 
} 

// blank hex
void blank(){
	*HEX3_0_ptr = 0x00000000;
	*HEX5_4_ptr = 0x00000000; 
} 