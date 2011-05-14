/* all-mers-gap.c: 
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

/* Given the output of all-mers, output n-mers with gaps inserted.
 * For example, with --n-mers 4 --gap-min 5 --gap-max 6 --gap-pos 2
 * and the following input:
 *
 * pos0	mer0
 * 0	bp0 bp1 bp2 bp3
 * 1	bp1 bp2 bp3 bp4
 * 2	bp2 bp3 bp4 bp5
 *      ...
 *
 * The output is:
 *
 * pos0	mer0		 gapsize
 * 0	bp0 bp1 bp7 bp8	 5
 * 0	bp0 bp1 bp8 bp9	 6
 * 1	bp1 bp2 bp8 bp9	 5
 * 1	bp1 bp2 bp9 bp10 6
 *
 * The output includes a column of starting positions (taken from the
 * input file) and a column of gap sizes.
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"


void
begin (int argc, const char * argv[])
{
  const char * in_col_name = "mer0";
  size_t in_col;
  const char * in_pos_col_name = "pos0";
  size_t in_pos_col;
  const char * n_mers_spec = "13";
  int n_mers;
  const char * gap_min_spec = "5";
  size_t gap_min;
  const char * gap_max_spec = "6";
  size_t gap_max;
  const char * gap_pos_spec = "6";
  size_t gap_pos;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-col", 0, &in_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_ARG, "-g", "--gap-min", 0, &gap_min_spec },
      { OPTS_ARG, "-G", "--gap-max", 0, &gap_max_spec },
      { OPTS_ARG, "-p", "--gap-pos", 0, &gap_pos_spec },
    };
  
  size_t infile;
  size_t outfile;

  t_taql_uint64 mer0_mask;
  t_taql_uint64 mer1_mask;

  t_taql_uint64 *mer;
  t_taql_boxed *pos;
  size_t bufpos;
  size_t bufsize;
  int buffull;

  int b;

  opts_parse (&argc, opts, argc, argv,
              "all-mers [-m col] [-n n-mers] [-g gap-min] [-G gap-max] [-p gap-pos] < table > table");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  gap_min = atoi (gap_min_spec);
  if (gap_min < 0)
    Fatal ("bogus gap_min");

  gap_max = atoi (gap_max_spec);
  if (gap_max < gap_min)
    Fatal ("bogus gap_max");

  gap_pos = atoi (gap_pos_spec);
  if (gap_pos <= 0 || gap_pos >= n_mers)
    Fatal ("bogus gap_pos");

  infile = Infile ("-");
  File_fix (infile, 1, 0);
  in_col = Field_pos (infile, Sym (in_col_name));
  in_pos_col = Field_pos (infile, Sym (in_pos_col_name));

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint64"), Sym (in_col_name));
  Add_field (outfile, Sym ("uint32"), Sym (in_pos_col_name));
  Add_field (outfile, Sym ("uint8"), Sym ("gapsize"));
  File_fix (outfile, 1, 0);

  mer0_mask = 0;
  mer1_mask = 0;
  for (b = 0; b < 16; ++b)
    {
      if (b < gap_pos)
	  mer0_mask |= (0xfULL << (b * 4));
      else
	  mer1_mask |= (0xfULL << (b * 4));
    }

  bufsize = gap_max + 1;
  mer = (t_taql_uint64*) malloc (sizeof (*mer) * (gap_max+1));
  pos = (t_taql_boxed*) malloc (sizeof (*pos) * (gap_max+1));
  bufpos = 0;
  buffull = 0;

  while (N_ahead (infile))
    {
      size_t nextbufpos = (bufpos + 1) % bufsize;
      pos[bufpos] = Peek (infile, 0, in_pos_col);
      mer[bufpos] = as_uInt64 (Peek (infile, 0, in_col));

      if (!buffull && nextbufpos == 0)
	{
	  buffull = 1;
	}

      if (buffull)
	{
	  t_taql_uint64 mer0 = mer0_mask & mer[nextbufpos];
	  size_t x;
	  size_t g;

	  for (x = (nextbufpos + gap_min) % bufsize, g = gap_min;
	       x != nextbufpos;
	       x = (x+1) % bufsize, ++g)
	    {
	      t_taql_uint64 mer1 = mer1_mask & mer[x];

	      Poke (outfile, 0, 0, uInt64 (mer0 | mer1));
	      Poke (outfile, 0, 1, pos[nextbufpos]);
	      Poke (outfile, 0, 2, uInt8 (g));

	      Advance (outfile, 1);
	    }
	}
      bufpos = nextbufpos;
      Advance (infile, 1);
    }

  /* XXX fixme -- the last few mers in the input (where gap_max isn't
     reached) are omitted here */

  Close (outfile);
  Close (infile);
}


/* arch-tag: Tom Clegg Sat Dec  9 23:47:23 PST 2006 (all-mers-gap/all-mers-gap.c)
 */

