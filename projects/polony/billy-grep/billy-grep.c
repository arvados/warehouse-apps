/* billy-grep.c: 
 *
 ****************************************************************
 * Copyright (C) 2006 Harvard University
 * Authors: Tom Clegg
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

/* Input contains "mer0gap" and "mer1gap" fields.
 *
 * Output is identical to input, except that records are omitted
 * unless they satisfy the "two letter constraint".
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"


int
constraint_ok (t_taql_uint64 gapmer0,
	       t_taql_uint64 gapmer1)
{
  int saw[4] = {0, 0, 0, 0};
  t_taql_uint64 bps_seen;
  int n_letters = 0;
  size_t x;
  t_taql_uint64 gapmer[2] = { gapmer0, gapmer1 };
  size_t i;

  bps_seen = 0;

  for (i = 0; i < 2; ++i)
    {
      for (x = 0; x < 16; ++x)
	{
	  int g = (gapmer[i] >> (x*4)) & 0xf;

	  if (!g)
	    {
	      break;
	    }
          bps_seen |= g;
          if (bp_possibilities_count[bps_seen] > 2)
            return 0;
	}
    }
  return 1;
}



void
begin (int argc, const char * argv[])
{
  size_t gapmer0_col;
  size_t gapmer1_col;
  size_t infile;
  size_t outfile;
  size_t c;

  infile = Infile ("-");
  File_fix (infile, 1, 0);
  gapmer0_col = Field_pos (infile, Sym ("mer0gap"));
  gapmer1_col = Field_pos (infile, Sym ("mer1gap"));

  outfile = Outfile ("-");
  for (c = 0; c < N_fields (infile); ++c)
    {
      Add_field (outfile,
		 Field_type (infile, c),
		 Field_name (infile, c));
    }
  File_fix (outfile, 1, 0);

  while (N_ahead (infile))
    {
      if (constraint_ok (as_uInt64 (Peek (infile, 0, gapmer0_col)),
			 as_uInt64 (Peek (infile, 0, gapmer1_col))))
	{
	  for (c = 0; c < N_fields (infile); ++c)
	    {
	      Poke (outfile, 0, c, Peek (infile, 0, c));
	    }
	  Advance (outfile, 1);
	}
      Advance (infile, 1);
    }

  Close (outfile);
  Close (infile);
}


/* arch-tag: Tom Clegg Wed Jan 17 00:51:10 PST 2007 (billy-grep/billy-grep.c)
 */
