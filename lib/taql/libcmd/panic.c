/* panic.c: 
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

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "libcmd/panic.h"

static char errname[80] = "ERROR";

void
panic_set_errname (const char * name)
{

  if (!name || ((strlen (name) + 1) > sizeof (errname)))
    panic ("i can't even figure out my own name");

  strcpy (errname, name);
}

void
panic (char * msg)
{
#define default_msg "time to die"

  write (2, errname, strlen (errname));
  write (2, ": ", 2);
  if (msg)
    write (2, msg, strlen (msg));
  else
    write (2, default_msg, strlen (default_msg));
  write (2, "\n", 1);
  exit (2);
}




/* arch-tag: Thomas Lord Sat Aug 19 14:46:35 2006 (libcmd/panic.c)
 */

