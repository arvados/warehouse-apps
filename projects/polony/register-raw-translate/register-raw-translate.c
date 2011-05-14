/***************************************************************************************
 * register-raw.c                                                                      *
 *                                                                                     *
 * Takes a raw transmitted light image, and a fluorescence image, and returns the      *
 * offsets (x,y) to translate the fluorescent images by to bring them into register    *
 * with the transmitted light image.  Offset is reported on stdout.                    *
 *                                                                                     *
 * TO COMPILE: gcc register-raw.c -o register-raw -lm                                  *
 *                                                                                     * 
 * USAGE:  ./register-raw                                                              *
 *    (gives instructions)                                                             *
 *                                                                                     *
 * WRITTEN BY: Jay Shendure, Greg Porreca (Church Lab) 01-30-2005                      *
 * UPDATED BY: Erik Garrison (Church Lab) 01-29-2007                                   *
 *                                                                                     *
 *                                                                                     *
 ***************************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <dirent.h>


#define MAX_ROOTPATH_LEN 100
#define MAX_FULLPATH_LEN 150
#define MAX_OBJECTS 64000 //max objects per frame
#define MAX_FOCUS_PIXELS 20000     // maximum number of focus pixels allowed
#define PIXEL_MAX 65535 // maximum pixel value in 16-bit encoding

//function prototypes
void read_raw_image_from_stdin(short unsigned int*, int);

int main(int argc, char *argv[]){
  int i;
  short unsigned int* base_image;
  short unsigned int* align_image;
  short unsigned int* IP, *IP2;
  short unsigned int yrows, xcols;
  int curr_y_offset, curr_x_offset;
  int curr_pixel;


  int FOCUS_N, CUTOFF, MIN_MAX, MAX_OFF, FRAME_N;
  int INDEX;  
  int count, total_focus_pix, count3, curr_focus_pix, count5, count6, count7, max_total_offset;
  int FOCUS_PIXEL_X[MAX_FOCUS_PIXELS];
  int FOCUS_PIXEL_Y[MAX_FOCUS_PIXELS];
  int SCORE, BEST_X, BEST_Y, BEST_SCORE;
  int PRE_MULT[20000];
  int TOT_SIZE;
  unsigned short int ROW_SIZE, COL_SIZE;

  int n;


  if(argc < 7){
    fprintf(stderr, "\n");
    fprintf(stderr, "To use this program, execute as follows:\n");
    fprintf(stderr, " cat base_raw_image align_raw_image | ./register-raw-translate xcols yrows focus_n threshold bead_color max_offset\n");
    fprintf(stderr, "  WHERE:\n");
    fprintf(stderr, "        xcols = number of columns (in pixels) in image; 1000 with our camera\n");
    fprintf(stderr, "        yrows = number of rows (in pixels) in image; 1000 with our camera\n");
    fprintf(stderr, "        focus_n = number of sample pixels for use in alignment algorithm\n");
    fprintf(stderr, "        threshold = brightfield threshold used for find_object\n");
    fprintf(stderr, "        bead_color = 1 or -1 (as specified for find_object\n");
    fprintf(stderr, "        max_offset = maximum offset (in pixels) to translate image by to put it in register with the\n");
    fprintf(stderr, "                     base image; the larger this value, the longer it will take; we use 40\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Output is the align_raw_image translated by the offsets, with out-of-frame pixels\n");
    fprintf(stderr, "replaced with white (65535).\n");
    exit(0);
  }

  // Parse command-line arguments
  yrows = atoi(argv[1]);
  xcols = atoi(argv[2]);
  FOCUS_N  = atoi(argv[3]); //2000
  if (FOCUS_N > MAX_FOCUS_PIXELS) { 
      fprintf(stderr, "Number of focus pixels is greater than maximum allowed (%i)\n", MAX_FOCUS_PIXELS); 
      exit(1);
  }
  CUTOFF   = atoi(argv[4]); //7000
  MIN_MAX  = atoi(argv[5]); // -1
  MAX_OFF  = atoi(argv[6]); // 40 

  ROW_SIZE = yrows;
  COL_SIZE = xcols;
  TOT_SIZE = ROW_SIZE * COL_SIZE;
  // this deals with the -1/+1 dilemma...
  if (MIN_MAX >= 0) {MIN_MAX = 1;} else {MIN_MAX = -1;}

  max_total_offset = (MAX_OFF*2)-1;

  if((base_image = (short unsigned int *) malloc(TOT_SIZE * sizeof(short unsigned int))) == NULL){
    fprintf(stderr, "Could not allocate enough memory for the image.\n");
    exit(42);
  }

  if((align_image = (short unsigned int *) malloc(TOT_SIZE * sizeof(short unsigned int))) == NULL){
    fprintf(stderr, "Could not allocate enough memory for the image.\n");
    exit(42);
  }

  // our input should be two RAW images concatenated together
  // we use the yrows xcols variables to determine their size
  // it is assumed that they have 2 bytes/pixel
  read_raw_image_from_stdin(base_image, TOT_SIZE);
  read_raw_image_from_stdin(align_image, TOT_SIZE);
  
  // Base image processing
  // We create a set of focus pixels from the brightfield image of the frame in question.
  // These focus pixels match several criteria:
  //   1) they must be above the cutoff threshold from which the mask files were created (e.g. 7800)
  //   2) there must not be more focus pixels than FOCUS_N:
  //        To ensure this, we take every other pixel above the cutoff if there are 
  //        greater than 2x as many possible focus pixels as FOCUS_N, every 3rd if there
  //        are greater than 3x, etc.
  // We then store the x and y offsets of each focus pixel FOCUS_PIXEL_X and FOCUS_PIXEL_Y for later use.


    // Calculate the number of focus (e.g. sample) pixels we have to poll.
    // Select focus pixels
    total_focus_pix = 0;
    //iterate over all pixels in the raw image
    //adding a focus pixel if the pixel is > the cutoff given
    for(curr_pixel = 0; curr_pixel < TOT_SIZE; curr_pixel++){
      if ((MIN_MAX*base_image[curr_pixel]) > (MIN_MAX*CUTOFF)) {
        total_focus_pix++;
      }
    }

    // find the floor of the ratio between the number of possible focus pixels and FOCUS_N
    count3 = (int) floorl(((float) total_focus_pix) / ((float) FOCUS_N));
    if(count3==0){
      fprintf(stderr, "count3 (floorl(total_focus_pix / FOCUS_N))==0; setting count3=1\n");
      count3 = 1;
    }// DONE counting focus pix


    total_focus_pix = 0;
    curr_focus_pix = 0;
    
    // for each pixel in the 'raw' image 
    for(curr_pixel = 0; curr_pixel < TOT_SIZE; curr_pixel++){
      // if the pixel is above the cutoff level
      if ((MIN_MAX*base_image[curr_pixel]) > (MIN_MAX*CUTOFF)) {
        // (again) sum the number of pixels above the cutoff
        total_focus_pix++;
        // and check if the current count of 'focus_pix' is divisible by 'count3'
        // basically this ensures that we only get FOCUS_N pixels into the FOCUS_PIXEL_X and FOCUS_PIXEL_Y arrays
        if ((total_focus_pix % count3) == 0 && curr_focus_pix < FOCUS_N) { 
          // if we select this pixel, we set...
          // FOCUS_PIXEL_X[N] = X location of pixel under focus less MAX_OFF (max offset)
          // FOCUS_PIXEL_Y[N] = Y location of pixel under focus less MAX_OFF '' ''
          FOCUS_PIXEL_X[curr_focus_pix] = ((int) curr_pixel % COL_SIZE) - MAX_OFF;
          FOCUS_PIXEL_Y[curr_focus_pix] = ((int) floorl(((float)curr_pixel) / ((float)COL_SIZE))) - MAX_OFF;
          curr_focus_pix++; // and increment the count of 'focus_pix'
        }
      }
    }
   


  // ALIGNMENT LOGIC
  //
  // Basically this is a brute-force search, in which a set of pixels which were aligned
  // to beads in the (e.g. they were above the cutoff)
  // For each x,y offset within the preset bounds,
  //    1) For each preselected focus pixel
  //    2) iterate over all the preselected focus pixele
  //        and sum the values of the pixels in the fluorescent image to align.
  //        The x,y offset with the highest sum of intensities wins.
  //
  //  The intuition is pretty simple.  Basically you're looking through a mask at the image to align.
  //  When the image to align is moved into the correct positon, it should result in a large
  //  amount of transmitted light passing through the mask.  Basically, as long as the offsets 
  //  encountered in experiments have no rotational component, we should be able to use
  //  this alignment method.

  BEST_SCORE = 0;

  // for each xy offset within bounds
  for (curr_y_offset = 0; curr_y_offset < max_total_offset; curr_y_offset++) {	
	for (curr_x_offset = 0; curr_x_offset < max_total_offset; curr_x_offset++) {
	  count5 = 0; // number of sample/focus pixels we check
	  count6 = 0; // sum of their intensities
	  
      // for each focus pixel (preselected previously)
	  for (curr_focus_pix = 0; curr_focus_pix < FOCUS_N; curr_focus_pix++) {
	    count7 = FOCUS_PIXEL_Y[curr_focus_pix] + curr_y_offset;
	    if (count7 > 0) {  // this makes sure we're within the image frame
	      INDEX = (COL_SIZE * count7) + FOCUS_PIXEL_X[curr_focus_pix] + curr_x_offset;
	      if (INDEX >= 0 && INDEX < TOT_SIZE) {
            count6+= align_image[INDEX];
            count5++;
	      }
	    }
	  }
	  
      // the score is the average intensity of the locations of sample pixels in the mask
      // in the image we wish to align.
	  SCORE = (int) count6/count5;
	  if (SCORE > BEST_SCORE) {
	    BEST_Y = curr_y_offset - MAX_OFF;
	    BEST_X = curr_x_offset - MAX_OFF;
	    BEST_SCORE = SCORE;
	  }
	}
  }
  // ALIGNMENT LOGIC ENDS
      
  // Report optimal offset
  fprintf(stderr, "%d\t%d\t%d\n", BEST_X, BEST_Y, BEST_SCORE);

  short unsigned int* output_image;
  short unsigned int output_pixel;
  int pix,x,y,x_result,y_result;

  if((output_image = (short unsigned int *) malloc(TOT_SIZE * sizeof(short unsigned int))) == NULL){
    fprintf(stderr, "Could not allocate enough memory for the image.\n");
    exit(42);
  }
  
  for (curr_pixel=0; curr_pixel<TOT_SIZE; curr_pixel++) {
      // we translate the image by the offset suggested by the alignment algorithm
      // we first check if the current pixel would lie outside the boundaries
      // if so, we set the output_image pixel to PIXEL_MAX
      // else, we get it from the align_image vector
      // the result is a raw image offset by the suggested offsets

      x = curr_pixel % ROW_SIZE;
      y = curr_pixel / COL_SIZE;
      x_result = x + BEST_X;
      y_result = y + BEST_Y;
      //printf("x_result = %i, y_result = %i", x_result, y_result);
      if(x_result < 0 || y_result < 0 
         || x_result > ROW_SIZE || y_result > COL_SIZE) {
          //printf(" out of bounds\n");
          output_image[curr_pixel] = (short unsigned int) PIXEL_MAX; 
      } else {
          //printf(" in bounds\n");
          output_image[curr_pixel] = align_image[(y_result * ROW_SIZE) + x_result];
      }
      //printf("x = %i, y = %i\n", x,y);

  } 

  fwrite(output_image, sizeof(short unsigned int) * TOT_SIZE, 1, stdout);

}//end int(main)

void read_raw_image_from_stdin(short unsigned int* img, int size) {
    int i;
    for(i=0; i < size; i++) {
        fread(&img[i], sizeof(short unsigned int), 1, stdin);
    }
}

/*
  arch-tag: Tom Clegg Fri Mar 16 20:46:44 PDT 2007 (register-raw-translate/register-raw-translate.c)
*/
