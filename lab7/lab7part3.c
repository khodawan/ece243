// Lab 7 part 3. Animation.
// 8 connected points moving across screen.
// bounce off edges when boundaries reached 

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h> 

volatile int pixel_buffer_start; // global variable

// synchronize with VGA display 
// code from lecture notes 
void wait_for_vsync(){
	volatile int *pixel_ctrl_ptr = (int*)0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3);
	while((status & 0x01) != 0){
		status = *(pixel_ctrl_ptr +3);
	}
}

// given function 
void plot_pixel(int x, int y, short int line_color) {
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

// line drawing algorithm from lab instructions 
// changed implementation from parts 1 and 2 to not use pointers when swapping
// previous implementation led to issues in main animation 
void draw_line(int x0, int y0, int x1, int y1, int colour) {
	
	int delta_x = x1 - x0;
 	int delta_y = y1 - y0;
	
	if (delta_y < 0)
		delta_y = delta_y * (-1); 
	
	if (delta_x < 0)
		delta_x = delta_x * (-1);
	
	int is_steep; //= abs(y1 - y0) > abs(x1 - x0);
 	
	if (delta_y > delta_x)
		is_steep = 1;
	else 
		is_steep = 0; 
	
	if (is_steep) {
		int temp = x0;
		x0 = y0;
		y0 = temp; 
 		temp = x1;
		x1=y1;
		y1=temp;
	}
	
	if (x0 > x1) {
		int temp = x0;
		x0=x1;
		x1=temp;
		temp=y0;
		y0=y1;
		y1=temp; 
	}
	
 	delta_x = x1 - x0;
 	delta_y = y1 - y0;
	
	if (delta_y < 0)
		delta_y = delta_y * (-1); 
	
	int error = -(delta_x / 2);
 	int y = y0;
	int y_step; 
 	
	if (y0 < y1) 
		y_step = 1;
	else 
		y_step = -1;

 	for (int x = x0; x <= x1; x++) {
 		if (is_steep) 
			plot_pixel(y, x, colour);
 		else
 			plot_pixel(x, y, colour);
 		error = error + delta_y;
 		if (error >= 0) {
 			y = y + y_step;
 			error = error - delta_x;
		} 
	}
}

// for drawing points on screen 
void draw_rectangle(int x1, int y1, int size, int colour) {
	for (int x = x1; x < (size + x1); x++)
		draw_line(x, y1, x, (size + y1), colour);
	
}

// makes starting screen black 
void clear_screen() {
	for (int x = 0; x < 320; x++) 
		for (int y = 0; y < 240; y++) 
			plot_pixel(x, y, 0);
}


int main(void) {
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
	
    // use arrays to keep track of coordinates of boxes and direction of movement 
	int x[8];
	int y[8];
	int horizontal[8];
	int vertical[8];
	int color_rect[8];
	int size = 3; // size of rectangles 
	short color[10] = {0xFFFF, 0xF800, 0x07E0, 0x001F, 0xF81F, 0xFFE0, 0x07FF, 0x18E3, 0x381F, 0x5555}; 
	
	srand(time(0)); 
	// initialize coordinates and direction of movement of rectangles 
	for(int i = 0; i < 8; i++){
		x[i] = rand()%(319 - size);
		y[i] = rand()%(239 - size);
		horizontal[i] = rand()%2;
		vertical[i] = rand()%2;
		color_rect[i] = color[rand()%10]; 
	}

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

    while (1) {
		
		/* get rid of previously drawn lines/rectangles */ 
		clear_screen();
		
		/*Update coordinates and directionality if needed (boundary check) */ 
		for (int i = 0; i < 8; i++){ 
			
			// hit bounds on x axis?
			if(x[i] == (319 - size))
				horizontal[i] = 0;
			else if(x[i] == 0)
				horizontal[i] = 1;	
			
			// hit bounds on y axis?
			if(y[i] == (239 - size))
				vertical[i] = 0;
			else if(y[i] == 0)
				vertical[i] = 1;
			
			//increment/decrement x and y values appropriately 
			if(horizontal[i]==1)
				x[i] ++;
			else
				x[i] --;
			
			if(vertical[i] == 1)
				y[i] ++;
			else
				y[i] --;
		}
		
		/* update screen with new locations. rectangles in pink, lines in green */  
		for(int i = 0; i < 8; i++){
			draw_rectangle(x[i], y[i], size, color_rect[i]);
			
			if(i != 7)
				draw_line(x[i], y[i], x[i + 1], y[i + 1], color_rect[i]);
			else
				draw_line(x[i], y[i], x[0], y[0], color_rect[0]);
			
		}
       
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }
}

	
	

	