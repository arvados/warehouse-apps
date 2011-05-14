/* must-malloc.h:
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

#ifndef INCLUDE__LIBCMD__MUST_MALLOC_H
#define INCLUDE__LIBCMD__MUST_MALLOC_H


#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


/* automatically generated __STDC__ prototypes */
extern void * must_malloc (size_t size);
extern void * must_realloc (void * was, size_t size);
extern char * must_strsave (char * str);
extern char * must_strcat (char * a, char * b);
extern char * safe_basename (char * f);
extern void must_write (int fd, char * buf, size_t amt);
extern ssize_t must_read (int fd, char * buf, size_t amt);
extern off_t must_lseek (int fd, off_t offset, int whence);
extern void must_fstat (int fd, struct stat * buf);
extern void must_fputc (int c, FILE * f);
extern void must_fwrite (void * ptr, size_t size, size_t nmemb, FILE * stream);
#endif  /* INCLUDE__LIBCMD__MUST_MALLOC_H */

/* arch-tag: Thomas Lord Sat Aug 19 14:59:27 2006 (libcmd/must-malloc.h)
 */
