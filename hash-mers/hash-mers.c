/* hash-mers.c: 
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

/* We treat a one-column table of uint32 as
 * a bitset.
 * 
 * A mer is a column of n-mers.
 * 
 * For n that is small enough, this program
 * will scan a set of n-mers, set a bit in a
 * bitset for each one found, and write the 
 * bitset.
 * 
 * Two mers are equal if they both contain only
 * a, c, g, or t (case is ignored).
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"


void
begin (int argc, const char * argv[])
{
  const char * in_col_name = "mer0";
  size_t in_col = 5;
  const char * n_mers_spec = "13";
  int n_mers = 13;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-column", 0, &in_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_END, }
    };

  size_t infile;
  size_t outfile;
  size_t bitset_rows;
  size_t count = 0;

  opts_parse (&argc, opts, argc, argv,
              "hash-mers [-m col] [-n n-mers] < table > bitset");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  infile = Infile ("-");
  File_fix (infile, 2, 0);
  in_col = Field_pos (infile, Sym (in_col_name));

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint32"), Sym ("bits"));

  bitset_rows = ((1UL << (2 * n_mers)) >> 5);
  if (!bitset_rows)
    Fatal ("bitset too large or small");

  File_fix (outfile, bitset_rows, 0);

  
  while (N_ahead (infile))
    {
      t_taql_uint64 mer0;
      size_t hash_value;

      mer0 = as_uInt64 (Peek (infile, 0, in_col));
      if (hash_mer (&hash_value, mer0, n_mers))
        {
          size_t row = hash_value / 32;
          size_t bit = hash_value % 32;
          t_taql_uint32 old_bits;

          old_bits = as_uInt32 (Peek (outfile, row, 0));
          if (!(old_bits & (1 << bit)))
            {
              ++count;
              Poke (outfile, row, 0, uInt32 (old_bits | (1 << bit)));
            }
        }
      Advance (infile, 1);
    }

  fprintf (stderr, "count was %lu\n", (unsigned long)count);

  Advance (outfile, bitset_rows);

  Close (outfile);
  Close (infile);
}


/* arch-tag: Thomas Lord Mon Nov  6 13:37:31 2006 (hash-mers/hash-mers.c)
 */

