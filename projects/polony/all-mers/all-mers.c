/* all-mers.c: 
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

/* Consider a column which is a "mer-tiling" of 
 * a sequence.   E.g., if the sequence is:
 * 
 *      bp0 bp1 bp2 bp3 bp4 bp5 bp6 bp7 bp8 ....
 * 
 * then the 3-mer tiling is:
 * 
 * 	bp0 bp1 bp2
 * 	bp3 bp4 bp5
 * 	bp6 bp7 bp8
 *      ..
 * 
 * A corresponding all-3-mer table is:
 * 
 * 	bp0 bp1 bp2
 * 	bp1 bp2 bp3
 * 	bp2 bp3 bp4
 *      ...
 * 
 * This program reads an n-mer tiling and
 * writes an all-n-mer table.  The table includes
 * a column of starting positions.
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"


void
begin (int argc, const char * argv[])
{
  const char * in_col_name = "mer0";
  size_t in_col;
  const char * n_mers_spec = "13";
  int n_mers;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-col", 0, &in_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_END, 0 }
    };
  
  size_t infile;
  size_t outfile;
  t_taql_uint32 position;

  opts_parse (&argc, opts, argc, argv,
              "all-mers [-m col] [-n n-mers] < table > table");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  infile = Infile ("-");
  File_fix (infile, 2, 0);
  in_col = Field_pos (infile, Sym (in_col_name));

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint64"), Sym ("mer0"));
  Add_field (outfile, Sym ("uint32"), Sym ("pos0"));
  File_fix (outfile, n_mers, 0);
  
  position = 0;

  while (N_ahead (infile) > 1)
    {
      t_taql_uint64 mer0;
      t_taql_uint64 mer1;
      int x;

      mer0 = as_uInt64 (Peek (infile, 0, in_col));
      mer1 = as_uInt64 (Peek (infile, 1, in_col));

      for (x = 0; x < n_mers; ++x)
        {
          Poke (outfile, x, 0, uInt64 (mer0));
          Poke (outfile, x, 1, uInt32 (position));

          ++position;

          mer0 >>= 4;
          mer0 |= (   (0xf & (mer1 >> (x * 4)))
                   << (4 * (n_mers - 1)));
          
        }
      Advance (infile, 1);
      Advance (outfile, n_mers);
    }

  if (N_ahead (infile))
    {
      Poke (outfile, 0, 0, Peek (infile, 0, in_col));
      Poke (outfile, 0, 1, uInt32 (position));
      Advance (outfile, 1);
    }

  Close (outfile);
  Close (infile);
}


/* arch-tag: Thomas Lord Mon Nov  6 12:58:55 2006 (all-mers/all-mers.c)
 */

