/* snp-mers.c: 
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

/* Input has any number of fields, at least one of which is a target
 * field:
 * 
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 * 
 * For each input record, two output records are produced.  The first
 * is identical to the input record.  The second is identical except
 * that the target fields contain the reverse complement of the
 * original fields, and (if two target fields are specified) the
 * target fields are swapped.
 *
 * For example:
 *
 * Input                       Output
 * "pos0" "mer0"               "pos0" "mer0"
 * 123    ACGGTTAC             123    ACGGTTAC
 * 345    GGGAAATT             123    GTAACCGT
 *                             345    GGGAAATT
 *                             345    AATTTCCC
 *
 * Input                       Output
 * "mer0"   "mer1"             "mer0"   "mer1"
 * CCCCAAAA ACGGTTAC           CCCCAAAA ACGGTTAC
 * CCCCTTTT GGGAAATT           GTAACCGT TTTTGGGG
 *                             CCCCTTTT GGGAAATT
 *                             AATTTCCC AAAAGGGG
 *
 * The size of the "mer" field should be supplied using the "-n n_mer"
 * command line argument.  In the above examples, the mer size is 8.
 *
 * If the name of the target fields are not "mer0" and "mer1", an
 * alternate name can be specified using "-m mer_col_name".
 *
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"

#define MAXMERCOUNT 4

void
begin (int argc, const char * argv[])
{
  int argx;
  const char * mer_col_name[MAXMERCOUNT] = { "mer0", 0, 0, 0, 0, 0 };
  size_t mer_col[MAXMERCOUNT];
  int *complement_from_col;

  const char * n_mers_spec_unused = "16";
  int mercount;
  int did;
  int only_rc_flag = 0;
  struct opts opts[] = 
    {
      { OPTS_FLAG, "-o", "--only-rc", &only_rc_flag, 0 },
      { OPTS_ARG, "-m", "--mer0-col", 0, &mer_col_name[0] },
      { OPTS_ARG, "-M", "--mer1-col", 0, &mer_col_name[1] },
      { OPTS_ARG, 0, "--mer2-col", 0, &mer_col_name[2] },
      { OPTS_ARG, 0, "--mer3-col", 0, &mer_col_name[3] },
      { OPTS_ARG, 0, "--mer3-col", 0, &mer_col_name[4] },
      { OPTS_ARG, 0, "--mer3-col", 0, &mer_col_name[5] },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec_unused },
    };
  
  size_t infile;
  size_t outfile;
  size_t c;
  size_t m;

  opts_parse (&argx, opts, argc, argv,
              "complement-mers [-o] [--mer0-col col] ... [--mer5-col col] < infile > outfile");

  if ((argc - argx) != 0)
    Fatal ("usage: complement-mers [-o] [--mer0-col col] ... [--mer5-col col] < infile > outfile");

  infile = Infile ("-");
  File_fix (infile, 1, 0);

  outfile = Outfile ("-");

  complement_from_col = (int *)malloc (N_fields (infile) * sizeof(int));
  for (m = 0; m < MAXMERCOUNT && mer_col_name[m]; ++m)
    {
      mer_col[m] = -1;
      mercount = m + 1;
    }

  for (c = 0; c < N_fields (infile); ++c)
    {
      complement_from_col[c] = -1;
      Add_field (outfile,
		 Field_type (infile, c),
		 Field_name (infile, c));
      for (m = 0; m < mercount; ++m)
	{
	  if (Eq (Field_name (infile, c), Sym (mer_col_name[m])))
	    {
	      mer_col[m] = c;
	      break;
	    }
	}
    }
  for (m = 0; m < mercount; ++m)
    {
      if (mer_col[m] < 0)
	{
	  Fatal ("specified field is not present in input.");
	}
      else
	{
	  complement_from_col[mer_col[m]] = mer_col[mercount-m-1];
	}
    }

  File_fix (outfile, 1, 0);
  
  while (N_ahead (infile) >= 1)
    {
      if (!only_rc_flag)
	{
	  for (c = 0; c < N_fields (infile); ++c)
	    {
	      Poke (outfile, 0, c, Peek (infile, 0, c));
	    }
	  Advance (outfile, 1);
	}

      for (c = 0; c < N_fields (infile); ++c)
	{
	  if (complement_from_col[c] >= 0)
	    {
	      Poke (outfile, 0, c,
		    uInt64 (reverse_complement_mer
			    (as_uInt64 (Peek (infile, 0,
					      complement_from_col[c])))));
	    }
	  else
	    {
	      Poke (outfile, 0, c, Peek (infile, 0, c));
	    }
	}
      Advance (outfile, 1);
      Advance (infile, 1);
    }

  Close (outfile);
  Close (infile);
}


/* arch-tag: Tom Clegg Tue Nov 14 01:29:15 PST 2006 (complement-mers/complement-mers.c)
 */
