// Lab 7 part 2
// simple animation: moving horizontal line 

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

volatile int pixel_buffer_start; // global variable

// provided function
void plot_pixel(int x, int y, short int line_color) {
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

// synchronization with VGA display; code from lecture notes 
void wait_for_vsync() {
	volatile int * pixel_ctrl_ptr = (int*)0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3); 
	while ((status & 0x01) != 0) 
		status = *(pixel_ctrl_ptr + 3); 
}

// from part 1 
void clear_screen(){
	for (int x=0;x<320;x++) 
		for (int y=0; y<240; y++)
			plot_pixel(x,y,0);
	
}

// from part 1
void swap(int *x0, int *x1) {
	int temp = *x0;
	*x0 = *x1;
	*x1 = temp;
}

// from part 1
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
	
	int y_step = 0;
 	if (y0 < y1) 
		y_step = 1;
	else 
		y_step = -1; 

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

    clear_screen();
	
	// initialize line to draw
	// start at top. line is full width of display 
	int y = 0; 
	int x0 = 0;
	int x1 = 319; 
	int up = 0; // 0 = down, 1 = up;
	
	//endless loop 
	while (1) {
		draw_line(x0, y, x1, y, 0x07E0); // green
    	
		/* clear previous line */ 
		if (y==0) {
			draw_line(x0, 1, x1, 1, 0); 
			up = 0; 
		}
		else if (y==239) {
			draw_line(x0, 238, x1, 238, 0); 
			up = 1; 
		} 
		else if (!up) 
			draw_line(x0, y-1, x1, y-1, 0); 
		else if (up)
			draw_line(x0, y+1, x1, y+1, 0);
		
		/* update position to draw line for next loop */ 
		if (up)
			y=y-1;
		else 
			y=y+1; 
		
		wait_for_vsync(); 
	}
}

