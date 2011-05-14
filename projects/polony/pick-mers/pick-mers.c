/* pick-mers.c: 
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

/* This filters a list of candidate mers from
 * some sequence:
 * 
 *    # field "mer0" "uint64"
 *    # field "pos0" "uint32"
 * 
 * using two mer bitsets (only mers found in the 
 * the bitset).  The output is:
 * 
 *    # field "mer0" "uint64"
 *    # field "pos0" "uint32"
 *    # field "in_a?" "uint8"
 *    # field "in_b?" "uint8"
 */

#include "libcmd/opts.h"
#include "libtaql/taql.h"
#include "taql/mers/mer-utils.ch"


void
begin (int argc, const char * argv[])
{
  int argx;
  size_t bitset_a_infile;
  size_t bitset_b_infile;
  size_t mer_infile;
  const char * mer_in_col_name = "mer0";
  size_t mer_in_col;
  const char * pos_in_col_name = "pos0";
  size_t pos_in_col;
  const char * n_mers_spec = "13";
  size_t n_mers;
  size_t n_bitset_rows;
  size_t outfile;
  size_t count;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-col", 0, &mer_in_col_name },
      { OPTS_ARG, "-p", "--pos-col", 0, &pos_in_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_END, }
    };
  
  opts_parse (&argx, opts, argc, argv,
              "pick-mers [-m col] [-n n-mers] a-bitset b-bitset < table > table");

  if ((argc - argx) != 2)
    Fatal ("usage: pick-mers [-m col] [-n n-mers] a-bitset b-bitset < table > table");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  n_bitset_rows = ((1UL << (2 * n_mers)) >> 5);
  if (!n_bitset_rows)
    Fatal ("bitset too large or small");

  bitset_a_infile = Infile (argv[argx]);
  bitset_b_infile = Infile (argv[argx + 1]);
  File_fix (bitset_a_infile, n_bitset_rows, 0);
  File_fix (bitset_b_infile, n_bitset_rows, 0);


  mer_infile = Infile ("-");
  File_fix (mer_infile, 1, 0);
  mer_in_col = Field_pos (mer_infile, Sym (mer_in_col_name));
  pos_in_col = Field_pos (mer_infile, Sym (pos_in_col_name));
  

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint64"), Sym ("mer0"));
  Add_field (outfile, Sym ("uint32"), Sym ("pos0"));
  Add_field (outfile, Sym ("uint8"), Sym ("in_a?"));
  Add_field (outfile, Sym ("uint8"), Sym ("in_b?"));
  File_fix (outfile, 1, 0);
  
  count = 0;
  while (N_ahead (mer_infile) >= 1)
    {
      t_taql_uint64 mer0;
      size_t hash_value;

      mer0 = as_uInt64 (Peek (mer_infile, 0, mer_in_col));
      if (hash_mer (&hash_value, mer0, n_mers))
        {
          size_t row = hash_value / 32;
          size_t bit = hash_value % 32;
          int in_a = ((1UL << bit) & as_uInt32 (Peek (bitset_a_infile, row, 0)));
          int in_b = ((1UL << bit) & as_uInt32 (Peek (bitset_b_infile, row, 0)));

          if (in_a || in_b)
            {
              t_taql_uint32 pos0 = as_uInt32 (Peek (mer_infile, 0, pos_in_col));

              ++count;
              Poke (outfile, 0, 0, uInt64 (mer0));
              Poke (outfile, 0, 1, uInt64 (pos0));
              Poke (outfile, 0, 2, uInt8 (!!in_a));
              Poke (outfile, 0, 3, uInt8 (!!in_b));
              Advance (outfile, 1);
            }
        }
      Advance (mer_infile, 1);
    }

  fprintf (stderr, "count is %lu\n", (unsigned long)count);

  Close (outfile);
  Close (mer_infile);
  Close (bitset_a_infile);
  Close (bitset_b_infile);
}


/* arch-tag: Thomas Lord Mon Nov  6 14:26:04 2006 (pick-mers/pick-mers.c)
 */

