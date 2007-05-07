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

void
begin (int argc, const char * argv[])
{
  int argx;
  const char * mer0_col_name = "mer0";
  size_t mer0_col;
  const char * mer1_col_name = 0;
  size_t mer1_col;
  int mer1_flag = 0;
  const char * n_mers_spec = "16";
  int n_mers;
  int only_rc_flag = 0;
  struct opts opts[] = 
    {
      { OPTS_FLAG, "-o", "--only-rc", &only_rc_flag, 0 },
      { OPTS_ARG, "-m", "--mer0-col", 0, &mer0_col_name },
      { OPTS_ARG, "-M", "--mer1-col", 0, &mer1_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
    };
  
  size_t infile;
  size_t outfile;
  size_t c;

  opts_parse (&argx, opts, argc, argv,
              "complement-mers [-o] [-m col] [-M col] [-n n-mers] < infile > outfile");

  if ((argc - argx) != 0)
    Fatal ("usage: complement-mers [-o] [-m col] [-M col] [-n n-mers] < infile > outfile");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  infile = Infile ("-");
  File_fix (infile, 1, 0);
  mer0_col = Field_pos (infile, Sym (mer0_col_name));

  outfile = Outfile ("-");
  for (c = 0; c < N_fields (infile); ++c)
    {
      Add_field (outfile,
		 Field_type (infile, c),
		 Field_name (infile, c));
      if (mer1_col_name)
	{
	  if (Eq (Field_name (infile,c), Sym (mer1_col_name)))
	    {
	      mer1_col = c;
	      mer1_flag = 1;
	    }
	}
    }
  if (mer1_col_name && !mer1_flag)
    {
      Fatal ("field specified by -M is not present in input.");
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
	  if ((!mer1_flag && c == mer0_col)
	      ||
	      (mer1_flag && c == mer1_col))
	    {
	      Poke (outfile, 0, c,
		    uInt64 (reverse_complement_mer (as_uInt64 (Peek (infile, 0, mer0_col)))));
	    }
	  else if (c == mer0_col)
	    {
	      Poke (outfile, 0, c,
		    uInt64 (reverse_complement_mer (as_uInt64 (Peek (infile, 0, mer1_col)))));
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
