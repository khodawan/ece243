#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
	
volatile int pixel_buffer_start; // global variable

void plot_pixel(int x, int y, short int line_color) {
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void wait_for_vsync() {
	volatile int * pixel_ctrl_ptr = (int*)0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3); 
	while ((status & 0x01) != 0) 
		status = *(pixel_ctrl_ptr + 3); 
}
	

void clear_screen(){
	for (int x=0;x<320;x++) 
		for (int y=0; y<240; y++)
			plot_pixel(x,y,0);
	
}


void swap(int *x0, int *x1) {
	int temp = *x0;
	*x0 = *x1;
	*x1 = temp;
}

void draw_line(int x0, int y0, int x1, int y1, short int color) {
	int delta_x = x1 - x0;	
 	int delta_y = abs(y1 - y0);
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	int error = -(delta_x / 2);
	
	// swapping
	if (is_steep) {
		swap(&x0, &y0);
		swap(&x1, &y1);
 	}
	//swapping
 	if (x0 > x1) {
		swap(&x0, &x1);
		swap(&y0, &y1); 
	}
	
	int y_step = -1;
 	if (y0 < y1) 
		y_step = 1;

	int y = y0;
 	for (int x=x0;  x< x1; x++){
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

void draw_rectangle(int x, int y, int size, int color) {
	for (int i = x; i < (size + x); i++){
		draw_line(i, y, i, (size + y), color);
	}
}


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    
	// declare other variables(not shown)
	int rect_x[8];
	int rect_y[8];
	int vertical[8];
	int horizontal[8]; 
	int size = 2; // size of rectangles 
	
	for (int i=0; i < 8; i++) {
		rect_x[i] = rand()%319 -size;
		rect_y[i] = rand()%239 -size; 
		vertical[i] = rand()%2; 
		horizontal[i] = rand()%2; 
	}
	
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the back buffer
    
	/* now, swap the front/back buffers, to set the front buffer location */
    
	wait_for_vsync();
    
	/* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    
	/* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer

    clear_screen(); 

    while (1)
    {
        /* Erase any boxes and lines that were drawn in the last iteration */

        
        // code for drawing the boxes and lines (not shown)
		for (int i = 0; i < 8; i++) {
			
			if (rect_x[i] == (319 - size))
				horizontal[i]= 0;
			
			else if(rect_x[i] == 0)
				horizontal[i] = 1;
			
			if(rect_y[i] == (239 - size))
				vertical[i] = 0;
			
			else if(rect_y[i] == 0)
				vertical[i] = 1;
			
			
			//incrementing x and y values
			if(horizontal[i])
				rect_x[i] ++;
			
			else
				rect_x[i] --;
			
			
			if(vertical[i])
				rect_y[i] ++;
			
			else
				rect_y[i] --;
			
			
			draw_rectangle(rect_x[i], rect_y[i], size, 0x001F);
			
			if(i != 7)
				draw_line(rect_x[i], rect_y[i], rect_x[i + 1], rect_y[i + 1], 0x001F);
			
			else
				draw_line(rect_x[i], rect_y[i], rect_x[0], rect_y[0], 0x001F);
			
        // code for updating the locations of boxes (not shown)
		}
	wait_for_vsync(); // swap front and back buffers on VGA vertical sync
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    
	}
}

// code for subroutines (not shown)
