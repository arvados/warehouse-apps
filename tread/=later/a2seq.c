/* a2seq.c: 
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
  size_t output;
  size_t pos;

  output = Outfile ("-");

  Add_field (output, Sym ("uint4"), Sym ("bp0"));
  Add_field (output, Sym ("uint4"), Sym ("bp1"));
  File_fix (output, 1, 0);


  pos = 0;
  while (1)
    {
      const int char_in = getchar ();

      if (char_in == EOF)
        {
          if (ferror (stdin))
            Fatal ("input error");
          else
            {
              if (pos % 2)
                {
                  Poke (output, 0, 1, uInt4 (bp_letter_to_int4 (0)));
                  Advance (output, 1);
                }
              break;
            }
        }

      Poke (output, 0, (pos % 2),
            uInt4 (bp_letter_to_int4 (char_in)));

      ++pos;

      if (!(pos % 2))
        Advance (output, 1);
    }

  Close (output);
}


/* arch-tag: Thomas Lord Mon Oct 30 16:38:02 2006 (taql/a2seq.c)
 */
