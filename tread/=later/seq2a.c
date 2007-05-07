/* seq2a.c: 
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

#include "libtaql/taql.h"
#include "taql/bp.ch"


void
begin (int argc, const char * argv[])
{
  size_t input;

  input = Infile ("-");
  File_fix (input, 1, 0);

  while (N_ahead (input))
    {
      int c1 = bp_int4_to_letter ((int)as_Int32 (Peek (input, 0, 0)));
      int c2 = bp_int4_to_letter ((int)as_Int32 (Peek (input, 0, 1)));

      if (   (c1 && (EOF == putchar (c1)))
          || (c2 && (EOF == putchar (c2))))
        Fatal ("output error");

      Advance (input, 1);
    }

  Close (input);
}


/* arch-tag: Thomas Lord Mon Oct 30 17:49:35 2006 (taql/seq2a.c)
 */
