/* index-mers.c: 
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

/* Build an in-core index of a table of reads.
 * 
 * Input includes:
 * 
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 *
 * Output is:
 * 
 *     # field "head" "uint32"
 *     # field "next" "uint32"
 * 
 * If the input table has N rows, then the output table
 * has:
 * 
 *    2^K where K is the smallest integer such that
 *     2^K >= 2 * (N + 1)
 * 
 * Fields in the output table have this meaning:
 * 
 * For hash value H,
 * 
 *     output[H]["head"]
 * 
 *       0 means no input row has that hash value
 *     N+1 means that input row N is the earliest row with that hash value
 * 
 *     output[N + 1]["next"]
 * 
 *     M+1 means that row M also has the same hash value
 *       0 means that no further rows have the same hash value
 *
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"


void
begin (int argc, const char * argv[])
{
  const char * mer0_in_col_name = "mer0";
  const char * mer1_in_col_name = "mer1";
  size_t mer0_in_col = 0;
  size_t mer1_in_col = 1;
  const char * n_mers_spec = "13";
  int n_mers = 13;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer0-column", 0, &mer0_in_col_name },
      { OPTS_ARG, "-M", "--mer1-column", 0, &mer1_in_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_END, }
    };

  size_t infile;
  size_t outfile;
  size_t input_rows;
  size_t output_rows;
  size_t hash_mask;
  size_t x;
  size_t hash_first_col;
  size_t next_same_hash_col;

  opts_parse (&argc, opts, argc, argv,
              "index-mers [-m col] [-n n-mers] < table > bitset");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  infile = Infile ("-");
  File_fix (infile, 0, 0);
  input_rows = N_ahead (infile);
  mer0_in_col = Field_pos (infile, Sym (mer0_in_col_name));
  mer1_in_col = Field_pos (infile, Sym (mer1_in_col_name));

  {
    size_t x;
    x = input_rows + 1;
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    hash_mask = x;
    output_rows = (hash_mask + 1);
  }

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint32"), Sym ("head"));
  hash_first_col = 0;
  Add_field (outfile, Sym ("uint32"), Sym ("next"));
  next_same_hash_col = 1;
  File_fix (outfile, output_rows, 0);

  for (x = input_rows; x--; )
    {
      t_taql_uint64 mer0;
      t_taql_uint64 mer1;
      size_t hash_value;

      mer0 = as_uInt64 (Peek (infile, x, mer0_in_col));
      mer1 = as_uInt64 (Peek (infile, x, mer1_in_col));

      if (hash_mer_2 (&hash_value, mer0, mer1, n_mers))
        {
          size_t row = (hash_value & hash_mask);
          size_t hash_head = (size_t)as_uInt32 (Peek (outfile, row, hash_first_col));
          
          Poke (outfile, row, hash_first_col, uInt32 (x + 1));
          Poke (outfile, x + 1, next_same_hash_col, uInt32 (hash_head));
        }
    }

  Advance (outfile, output_rows);

  Close (outfile);
  Close (infile);
}


/* arch-tag: Thomas Lord Thu Nov  9 10:16:43 2006 (index-mers/index-mers.c)
 */

