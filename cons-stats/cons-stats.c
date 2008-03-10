/* cons-stats.c: 
 *
 ****************************************************************
 * Copyright (C) 2008 Harvard University
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

/* Input is base calls from place-report.
 *
 * Output is summary statistics.
 *
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"

void
begin (int argc, const char * argv[])
{
  int argx;

  struct opts opts[] = 
    {
      { OPTS_END, }
    };

  size_t infile;
  size_t n_total = 0;
  size_t n_covered = 0;
  size_t n_undisputed = 0;
  size_t n_call_snp = 0;
  size_t c;
  size_t infile_pos_col = 0;
  size_t infile_acgt_col[4] = {1,2,3,4};
  size_t infile_ref_col = 5;

  opts_parse (&argx, opts, argc, argv,
              "cons-stats < infile > outfile");

  if ((argc - argx) != 0)
    Fatal ("usage: cons-stats < infile > outfile");

  infile = Infile ("-");
  File_fix (infile, 1, 0);

  for (c = 0; c < N_fields (infile); ++c)
    {
      if (Eq (Field_name (infile, c), Sym ("pos"))) infile_pos_col = c;
      if (Eq (Field_name (infile, c), Sym ("a"))) infile_acgt_col[0] = c;
      if (Eq (Field_name (infile, c), Sym ("c"))) infile_acgt_col[1] = c;
      if (Eq (Field_name (infile, c), Sym ("g"))) infile_acgt_col[2] = c;
      if (Eq (Field_name (infile, c), Sym ("t"))) infile_acgt_col[3] = c;
      if (Eq (Field_name (infile, c), Sym ("mer0ref"))) infile_ref_col = c;
    }
  
  while (N_ahead (infile) >= 1)
    {
      int x;
      int acgt_vote[4];
      int guessbp = 0;
      int refbp = as_uInt32 (Peek (infile, 0, infile_ref_col));
      int dispute = 0;
      for (x=0; x<4; x++)
	{
	  acgt_vote[x] = as_uInt32 (Peek (infile, 0, infile_acgt_col[x]));
	  if (acgt_vote[x] > 2 && !(refbp & (1 << x))) dispute=1;
	  if (acgt_vote[x])
	    {
	      guessbp |= (1 << x);
	    }
	}
      ++n_total;
      if (guessbp) ++n_covered;
      if (guessbp & ~refbp == 0) ++n_undisputed;
      if (dispute) ++n_call_snp;
      Advance (infile, 1);
    }

  Close (infile);
  printf ("%12d total\n"
	  "%12d covered\n"
	  "%12d undisputed\n"
	  "%12d call snp\n",
	  n_total, n_covered, n_undisputed, n_call_snp);
}
