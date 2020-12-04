// Lab 7 part 1 - line drawing 

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

volatile int pixel_buffer_start; // global variable

// provided code 
void plot_pixel(int x, int y, short int line_color) {
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

// makes default screen black 
void clear_screen(){
	for (int x=0;x<320;x++) 
		for (int y=0; y<240; y++)
			plot_pixel(x,y,0);
}

// helper function for draw_line 
void swap(int *x0, int *x1) {
	int temp = *x0;
	*x0 = *x1;
	*x1 = temp;
}

// draws line from starting point to end point
// follows algorithm provided in lab instructions 
void draw_line(int x0, int y0, int x1, int y1, short int color) {
	
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	
	// swapping
	if (is_steep) {
		swap(&x0, &y0);
		swap(&x1, &y1);
 	} 
	else if (x0 > x1) {
		swap(&x0, &x1);
		swap(&y0, &y1); 
	}
	
	int delta_x = x1 - x0;	
 	int delta_y = abs(y1 - y0);
	int error = (-1)*(delta_x / 2);
	
	// preset increment/decrement value  
	int y_step = -1;
 	if (y0 < y1) 
		y_step = 1;
	
	// algorithm discussed in lecture 
	int y = y0;
 	for (int x=x0;  x != x1; x++){
 		if (is_steep)
			plot_pixel(y, x, color);
 		else 
 			plot_pixel(x,y,color);
 		error = error + delta_y;
 		if (error >= 0) {
 			y = y + y_step;
 			error = error - delta_x;
		}
  	}
}

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;

    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
	
	/*get rid of static - make background black */ 
	clear_screen();
	
	// draw lines 
	draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
	
	// endless loop (to prevent application error upon exit of main function
	while (1) {
    // do nothing
	}
	
}


