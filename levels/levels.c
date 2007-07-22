/***************************************************************************************
 * levels.c                                                                      *
 *                                                                                     *
 * Given any image in RAW format, provides a table of:
 * <intensity> <number of pixels at intensity> <fraction of all pixels at intensity>
 *                                                                                     *
 * WRITTEN BY: Erik Garrison (Church Lab) 02-01-2007                                   *
 *                                                                                     *
 *                                                                                     *
 ***************************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <tiffio.h>
#include <unistd.h>

#define MAX_FILESIZE 2252800 //2200KB
#define ROW 1000 // 1000 pixel images
#define PIXEL_COUNT 1000000 // number of pixels in an image
#define DYNAMIC_RANGE 16384 // 2^14; levels of image intensity in a 14-bit image


//function prototypes
void read_raw_image_from_stdin(short unsigned int*, int);
void read_raw_image_from_file(short unsigned int* img, int size, char* fn);
double sum_pixels(short unsigned int* img);
short unsigned int* load_tiff_image(char* FILENAME);
void print_summary_stats(short unsigned int* image, int* level_table);
int count_objects(short unsigned int* image, int cutoff); 
double focus(short unsigned int* img);

int threshold = 9000;

int main(int argc, char *argv[]){
  short unsigned int* image;
  int curr_pixel, i; 
  char* fn;
  int ch;
  extern char *optarg;
  extern int optind, optopt, opterr;
  int tiff_in = 0; 
  int raw_stdin = 0;
  int just_sum = 0;
  int stat_info = 0;
  int object_tally = 0;

  int level_table[DYNAMIC_RANGE];

  for (i=0;i<DYNAMIC_RANGE;i++) { 
      level_table[i] = 0;
  }


  if (argc < 2) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "./levels -r image.raw\n");
    fprintf(stderr, "./levels -t image.tiff\n");
    fprintf(stderr, "cat image.raw | ./levels -s\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "By default the program produces a tab-delimited table for each intensity level in the image:\n");
    fprintf(stderr, " <intensity> <pixels at intensity>\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Other options:\n");
    fprintf(stderr, " -g:   sum pixel intensity.\n");
    fprintf(stderr, " -i:   mean, median, mode1, mode2, standard deviation, variance, object count, focus factor\n");
    fprintf(stderr, " -T <threshold>: set a threshold for use in object counting (defaults to 9000)\n");
    fprintf(stderr, "\n");
    exit(0);
  }

  if((image = (short unsigned int *) malloc(PIXEL_COUNT * sizeof(short unsigned int))) == NULL){
    fprintf(stderr, "Could not allocate enough memory for the image.\n");
    exit(42);
  }

  while ((ch = getopt(argc, argv, "igsr:t:T:")) != -1) {
      switch (ch) {
        case 't':
          image = load_tiff_image(optarg);
          break;
        case 'r':
          read_raw_image_from_file(image, PIXEL_COUNT, optarg);
          break;
        case 's':
          read_raw_image_from_stdin(image, PIXEL_COUNT);
          break;
        case 'g':
          just_sum = 1;
          break;
        case 'i':
          stat_info = 1;
          break;
        case 'T':
          threshold = atoi(optarg);
          break;
        default:
          break;
      }
  }


  for(i=0; i<PIXEL_COUNT; i++) {
      //printf("at pixel %i, intensity = %i\n", i, image[i]);
      level_table[image[i]] += 1;
  }

  if (just_sum) {
    printf("%f\n", sum_pixels(image));
  } else if (stat_info) {
    print_summary_stats(image, level_table);
  } else if (object_tally) {
    printf("%i\n", count_objects(image, threshold));
  } else {
    for (i=0; i<DYNAMIC_RANGE; i++) printf("%i\t%i\n", i, level_table[i]);
  }

  free(image);
      
}//end int(main)


void print_summary_stats(short unsigned int* image, int* level_table) {

  int max = 0;
  int i, mode, mode2, median;
  double mean;
  double sum;
  double standard_deviation, variance;
  double j = 0.0;
  int k = 0;

  //mode
  for (i=0; i<DYNAMIC_RANGE; i++) {
    if (level_table[i] > max) {
      max = level_table[i];
      mode2 = mode;
      mode = i;
    }
  }

  sum = sum_pixels(image);

  //mean
  mean = sum/PIXEL_COUNT;

  //standard deviation
  // 1. For each value xi calculate the difference x_i - \overline{x} 
  // between xi and the average value \overline{x}.
  // 2. Calculate the squares of these differences.
  for (i=0; i<PIXEL_COUNT; i++) {
   // j += pow(image[i]-mean,2);
   //printf("j is %f\n", j);
   j += pow((double) image[i] - mean, 2);
  }
  // 3. Find the average of the squared differences. This quantity is the variance σ2.
  variance = j/PIXEL_COUNT;
  // 4. Take the square root of the variance.
  standard_deviation = sqrt(variance);


  //median
  // loop through the levels table, adding the counts
  // when the sum passes 1/2 the # of obs, we're at the median
  for (i=0; i<DYNAMIC_RANGE; i++) {
    k += level_table[i];
    if (k > PIXEL_COUNT / 2) {
      median = i;
      break;
    }
  }

  printf("%f\t%i\t%i\t%i\t%f\t%f\t%i\t%f\t%.0f\n",
      mean,   // average pixel value
      median, // most middle pixel value
      mode,   // most common pixel value
      mode2,  // second most common pixel value
      standard_deviation,
      variance,
      count_objects(image, threshold),
      focus(image),
      sum_pixels(image));

}

double sum_pixels(short unsigned int* img) {
  int i;
  double sum;
  for (i=0; i < PIXEL_COUNT; i++) {
    sum += img[i];
  }
  return sum;
}



double focus(short unsigned int* image) {

  int i;
  int convsomcntr = 0;
  double convulsom = 0;
  double imagesom = 0;

  short unsigned int* current;
  current = image;

  for(i = 0; i < PIXEL_COUNT; i++)
  { 
    //if (!(i%ROW))
    //  printf("convulsom %f; imagesom %f\n", (double)convulsom, (double)imagesom);
    // first/last row: only make image sum, not convolution sum
    if (i < ROW | i > PIXEL_COUNT - ROW | !(i%ROW) | !((i-1)%ROW)) 
    {
      imagesom += *current;
    }
    else // not first or last row, nor first or last column: take convolution sum too..
    {
      convulsom += abs(4* *current - *(current-ROW) - *(current-1) - *(current+1) - *(current+ROW));
      imagesom += *current;
      convsomcntr++;
    }
    current++;
  }

  return (double)convulsom/(double)imagesom;

}


int count_objects(short unsigned int *image, int cutoff) {
  
  int i;
  int object_count = 0;

  for (i=0; i < PIXEL_COUNT; i++) {

    if (image[i] > cutoff) {
      // check we're not touching an object we've already counted
      // we check only up and left neighbors
      // we do not check left if we are in the first column
      // we do not check up if we are in the first row
      if (i < ROW)
        object_count++;
      else if (!(i % ROW))
        object_count++;
      else if (!(image[i-1] > cutoff) && !(image[i-ROW] > cutoff)) 
        object_count++;

    }

  }

  return object_count;

} 

// IMAGE I/O

void read_raw_image_from_stdin(short unsigned int* img, int size) {
    int i;
    for(i=0; i < size; i++) {
        fread(&img[i], sizeof(short unsigned int), 1, stdin);
    }
}

void read_raw_image_from_file(short unsigned int* img, int size, char* fn) {
    int i;
    FILE* raw;
    raw = fopen(fn, "r");
    for(i=0; i < size; i++) {
        fread(&img[i], sizeof(short unsigned int), 1, raw);
    }
    fclose(raw);
}


short unsigned int* load_tiff_image(char* FILENAME){
  TIFF *image;
  tsize_t stripSize;
  unsigned long imageOffset, result;
  int stripMax, stripCount;
  unsigned long count;
  char* buffer;
  
  if((buffer = (char*) malloc(MAX_FILESIZE)) == NULL){
    fprintf(stderr, "Could not allocate enough memory for the image.\n");
    exit(42);
  }
  
  // Open the TIFF image
  if((image = TIFFOpen(FILENAME, "r")) == NULL){
    fprintf(stderr, "Could not open image %s\n", FILENAME);
    exit(42);
  }
  
  stripSize = TIFFStripSize (image);
  stripMax = TIFFNumberOfStrips (image);
  //STRIPSIZE = stripSize;
  //STRIPMAX = stripMax;
  imageOffset = 0;
  
  // Load data to buffer
  for (stripCount = 0; stripCount < stripMax; stripCount++){
    if((result = TIFFReadEncodedStrip (image, stripCount,
				       buffer + imageOffset,
				       stripSize)) == -1){
      fprintf(stderr, "Read error on input strip number %d\n", stripCount);
      exit(42);
    }
    
    imageOffset += result;
  }
  
  // Close image
  TIFFClose(image);   
  return (short unsigned int*) buffer;
}

