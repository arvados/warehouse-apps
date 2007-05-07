/***************************************************************************************
 * find_objects.c                                                                      *
 *                                                                                     *
 *
 *  NOTE: I have ripped out the directory processing aspect of this --Erik
 *    Thu Jan 25 12:07:28 NZDT 2007
 *
 *     I then removed the TIFF dependency.  The script now works on RAW images,
 *     fed from stdin, produces a 'bwlabel' image to stdout. --Erik
 *      Mon Jan 29 21:03:40 NZDT 2007
 *
 * Takes a raw transmitted light image, finds all objects, and outputs a new image     *
 * file where every object from the original image is numbered sequentially (same      *
 * as bwlabel in Matlab) in the 'object' file.                                         *
 *                                                                                     *
 * TO COMPILE: g++ find_objects.c -O3 -ffloat-store -foptimize-sibling-calls           * 
 *             -fno-branch-count-reg -o find_objects -ltiff -lm -I../../INCLUDE        * 
 *             -L../../LIB                                                             *
 *                                                                                     *
 * USAGE:                                                                              *
 *       ./find_objects xcols yrows base_dir/ cutoff {-1,1}                            *
 *       WHERE:                                                                        *
 *             xcols = number of colums in the images (e.g. 1000)                      *
 *             yrows = number of rows in the images (e.g. 1000)                        *
 *             base_dir/ = the base dir (e.g. /mnt/data_seq1/B6/)                      *
 *             cutoff = the threshold value (e.g. 9000)                                *
 *             {-1, 1} = whether bead val is 0 or 65535 (black beads = -1, white = 1)  *
 *                                                                                     *
 * OUTPUT goes to base_dir/IMAGES/OBJECT/obj_counts.dat and to base_dir/IMAGES/OBJECT/ *
 *                                                                                     *
 * WRITTEN BY: Jay Shendure, Greg Porreca (Church Lab) 01-30-2005                      *
 * UPDATED BY: Erik Garrison (Church Lab) 01-29-2007
 *                                                                                     *
 *                                                                                     *
 ***************************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <dirent.h>
#include <iostream>
#include <map>
#include <string>
#include <algorithm>
#include <iterator>
#include <fstream>

using namespace std;

#define MAX_OBJECTS 64000 //max objects per frame

//function prototypes
int assign(int, int);
void read_raw_image_from_stdin(short unsigned int*, int);

//global variables
unsigned short int yrows, xcols;
multimap <int, int> m1;
map <int, int> m2;
map <int, int> m3;
map <int, int> m4;


int main(int argc, char *argv[]){
  
  short unsigned int *raw_image, *object_image;
  
  int CUTOFF, MIN_MAX, TOT_SIZE;
  
  int count, count2, count3, count4, count5;  
  
  int flag1, flag2, N1, N2;
  

  if(argc != 5) {
    fprintf(stderr, "To use find_objects, execute as follows:\n");
    fprintf(stderr, " cat raw_image | ./find_objects xcols yrows threshold bead_color >object_file\n");
    fprintf(stderr, "  WHERE:\n");
    fprintf(stderr, "        xcols = number of colums (in pixels) in the image; will be 1000 for Hamamatsu 1k EM\n");
    fprintf(stderr, "        yrows = number of rows (in pixels) in the image; will be 1000 for the Hamamatsu 1k EM\n");
    fprintf(stderr, "        threshold = the value to use when thresholding the brightfield images such that beads\n");
    fprintf(stderr, "                    pass the threshold but the background does not\n");
    fprintf(stderr, "        bead_color = 1 if the beads appear white in the brightfield images (as they will with\n");
    fprintf(stderr, "                     the phase plan apo we recommend).  Set this to -1 if the beads appear black\n");
    fprintf(stderr, "                     (as they will if you use a non-phase objective and Abbe condenser)\n");
    fprintf(stderr, "\n");
    exit(0);
  }

  yrows = atoi(argv[1]);
  xcols = atoi(argv[2]);
  CUTOFF   = atoi(argv[3]);
  MIN_MAX  = atoi(argv[4]);
  if (MIN_MAX >= 0) {MIN_MAX = 1;} else {MIN_MAX = -1;}
  TOT_SIZE = yrows * xcols;
  
  
    if((raw_image = (short unsigned int *) calloc(TOT_SIZE, sizeof(short unsigned int))) == NULL){
      fprintf(stderr, "Could not allocate enough memory for the raw image.\n");
      exit(42);
    }
    read_raw_image_from_stdin(raw_image, TOT_SIZE);
    
    //allocate memory for object image (output)
    if((object_image = (short unsigned int *) calloc(TOT_SIZE, sizeof(short unsigned int))) == NULL){
      fprintf(stderr, "Could not allocate enough memory for the object image.\n");
      exit(42);
    }
    
    //------------------- PERFORM REGISTRATION ---------------------------
    //
    
    // Clear maps
    // NOTE: they should be already clear, as this script now executes against a single image
    
    m1.clear();
    m2.clear();
    m3.clear();
    m4.clear();
    
    count3=0;
    count2=1;  // store label count 
    
    for(count = 0; count < (yrows * xcols); count++){
      
      //object_image[count] = 0;  -- because we use calloc, this is unnecessary
      
      if ((MIN_MAX*raw_image[count]) > (MIN_MAX*CUTOFF)) {	
	
	count3++;
	
	flag1 = 0; flag2 = 0;
	N1 = count - xcols;
	N2 = count - 1;
	if ((N1 >= 0) && (object_image[N1] > 0) && ((MIN_MAX*raw_image[N1]) > (MIN_MAX*CUTOFF))) {flag1 = 1;} 
	if ((count % xcols != 0) && (object_image[N2]) > 0 && ((MIN_MAX*raw_image[N2]) > (MIN_MAX*CUTOFF))) {flag2 = 1;}
	if (flag1 == 0 && flag2 == 0) {object_image[count] = count2; count2++;}  // untouched by labeled already-seen neighbors
	else if (flag1 == 1 && flag2 == 0) {object_image[count] = object_image[N1];}      // connected to pixel to top only
	else if (flag1 == 0 && flag2 == 1) {object_image[count] = object_image[N2];}      // connected to pixel to left only
	else {                                                          // connected to both neighbors
	  object_image[count] = object_image[N1];
	  if (object_image[N1] != object_image[N2]) {                                     // add entry (object_image[N1]=object_image[N2]) to equivalency table 
	    
	    m1.insert(pair<int, int>(object_image[N1],object_image[N2]));
	    m1.insert(pair<int, int>(object_image[N2],object_image[N1]));
	    m1.insert(pair<int, int>(object_image[N1],object_image[N1]));
	    m1.insert(pair<int, int>(object_image[N2],object_image[N2]));
	    
	  }
	}
	
	if (count2 > MAX_OBJECTS) {
	  fprintf(stderr, "Too many objects in an image to keep track...\n");
	  exit(42);
	}
      }
      
    }
    
    // consolidate equivalency list
    
    for (count4 = 1; count4 < count2; count4++) { 
      assign(count4, count4);	
    }
    
    // run through image again and reassign labels
    
    map<int,int>::iterator p;
    map<int,int>::iterator p2;
    
    count4 = 1;
    
    for (count5 = 1; count5 < count2; count5++) {
      if (m2.count(count5) == 0) {
	m2.insert(pair<int, int>(count5, -1));	
      }
      
      p = m2.find(count5);
      
      if (m3.count(p->second) > 0 && p->second != -1) {
	p2 = m3.find(p->second);
	m4.insert(pair<int,int>(count5,p2->second));
      } else {
	m4.insert(pair<int,int>(count5,count4));
	m3.insert(pair<int,int>(p->second,count4));
	count4++;
      }
      
    }
    
    count5 = 0;
    
    for (count4 = 1; count4 < count2; count4++) {
      p = m4.find(count4);
      if (p->second > count5) {count5 = p->second;} 
    }
    
    // Iterate over the bwlabel image, replacing values with object numbers specified by the m4 map
    for(count = 0; count < (yrows * xcols); count++){
      if (object_image[count]>0) {
	p = m4.find(object_image[count]);
	object_image[count] = p->second;	  
      }
    }    
    fprintf(stderr, "One frame analyzed.  %d pixels met threshold (%i).  %d objects found.\n", count3, CUTOFF, count5);
    
    //
    //--------------------- END REGISTRATION -----------------------------
    
    // write the RAW object image to stdout 
    fwrite(object_image, sizeof(short unsigned int) * TOT_SIZE, 1, stdout);
    // free memory
    free(raw_image);
    free(object_image);

  exit(0);
}  


int assign(int A, int B) {
  
  multimap<int,int>::iterator iter;
  multimap<int,int>::iterator lower;
  multimap<int,int>::iterator upper;
  
  lower = m1.lower_bound(A);
  upper = m1.upper_bound(A);
  
  for (iter = lower; iter != upper; iter++) {
    
    if (m2.count(iter->second) == 0) {      
      m2.insert(pair<int, int>(iter->second,B));
      assign(iter->second,B);
    }
  }
  
  return 0;
}

void read_raw_image_from_stdin(short unsigned int* img, int size) {
    int i;
    for(i=0; i < size; i++) {
        fread(&img[i], sizeof(short unsigned int), 1, stdin);
    }
}

/*
  arch-tag: Tom Clegg Fri Mar 16 20:46:10 PDT 2007 (find-objects/find-objects.c)
*/
