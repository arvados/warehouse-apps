/* must-malloc.c: 
 *
 ****************************************************************
 * Copyright (C) 2006 Harvard University
 * Authors: Thomas Lord
 * 
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */


#include <stdlib.h>
#include <string.h>
#include "libcmd/panic.h"
#include "libcmd/must-malloc.h"

void *
must_malloc (size_t size)
{
  void * answer;

  answer = malloc (size);
  if (!answer)
    panic ("bummer, malloc failed");

  return answer;
}


void *
must_realloc (void * was, size_t size)
{
  void * answer;

  answer = realloc (was, size);
  if (!answer)
    panic ("bummer, realloc failed");

  return answer;
}

char *
must_strsave (char * str)
{
  size_t l;
  char * answer;

  l = strlen (str);
  answer = must_malloc (l + 1);
  strcpy (answer, str);
  return answer;
}


char *
must_strcat (char * a, char * b)
{
  size_t al;
  size_t bl;
  char * answer;

  al = strlen (a);
  bl = strlen (b);
  answer = must_malloc (al + bl + 1);
  strcpy (answer, a);
  strcpy (answer + al, b);
  return answer;
}


char *
safe_basename (char * f)
{
  char * answer;

  answer = strrchr (f, '/');
  if (!answer)
    answer = f;
  else
    answer += 1;

  return answer;
}

void
must_write (int fd, char * buf, size_t amt)
{
  size_t did;


  did = 0;

  while (did < amt)
    {
      ssize_t here;

      here = write (fd, buf, amt);
      if (here < 0)
        panic ("i/o error on output");
      did += here;
      buf += here;
    }
}


ssize_t
must_read (int fd, char * buf, size_t amt)
{
  ssize_t did;

  did = read (fd, buf, amt);
  if (did < 0)
    panic ("i/o error on input");
  return did;
}


off_t
must_lseek (int fd, off_t offset, int whence)
{
  off_t answer;

  answer = lseek (fd, offset, whence);
  if (answer < 0)
    {
      panic ("lseek error");
    }

  return answer;
}


void
must_fstat (int fd, struct stat * buf)
{
  if (0 > fstat (fd, buf))
    {
      panic ("fstat error");
    }
}


void
must_fputc (int c, FILE * f)
{
  if (EOF == fputc (c, f))
    panic ("output error");
}


void
must_fwrite (void * ptr, size_t size, size_t nmemb, FILE * stream)
{
  if (nmemb != fwrite (ptr, size, nmemb, stream))
    panic ("output error");
}


/* arch-tag: Thomas Lord Sat Aug 19 14:41:19 2006 (libcmd/must-malloc.c)
 */

