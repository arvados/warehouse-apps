/* snp-mers.c: 
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

/* Input is a list of mers and positions:
 * 
 *     # field "mer0" "uint64"
 *     # field "pos0" "uint32"
 * 
 * Output is similar but discards all mers
 * that contain other than [AaCcGgTt] and adds
 * (preserving position sorting) single-snp mers,
 * filtering away any not found in the read set.
 * Output is:
 *
 *     # field "mer0" "uint64"
 *     # field "pos0" "uint32"
 *     # field "errpos" "uint8"
 *     # field "in_a?" "uint8"
 *     # field "in_b?" "uint8"
 * 
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"



int
maybe_poke (size_t outfile,
            t_taql_uint64 mer0,
            size_t n_mers,
            t_taql_uint32 pos0,
            int errpos,
            size_t bitset_a_infile,
            size_t bitset_b_infile)
{
  size_t hash_value;

  if (hash_mer (&hash_value, mer0, n_mers))
    {
      size_t row = hash_value / 32;
      size_t bit = hash_value % 32;
      int in_a = !!((1UL << bit) & as_uInt32 (Peek (bitset_a_infile, row, 0)));
      int in_b = !!((1UL << bit) & as_uInt32 (Peek (bitset_b_infile, row, 0)));
      
      if (in_a || in_b)
        {
          Poke (outfile, 0, 0, uInt64 (mer0));
          Poke (outfile, 0, 1, uInt32 (pos0));
          Poke (outfile, 0, 2, Int8 (errpos));
          Poke (outfile, 0, 3, Int8 (in_a));
          Poke (outfile, 0, 4, Int8 (in_b));
          Advance (outfile, 1);
          return 1;
        }
      else
        return 0;
    }
  else
    return 0;
}


void
begin (int argc, const char * argv[])
{
  int argx;
  size_t bitset_a_infile;
  size_t bitset_b_infile;
  const char * mer_col_name = "mer0";
  size_t mer_col;
  const char * pos_col_name = "pos0";
  size_t pos_col;
  const char * n_mers_spec = "13";
  int n_mers;
  size_t n_bitset_rows;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-col", 0, &mer_col_name },
      { OPTS_ARG, "-p", "--pos-col", 0, &pos_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
    };
  
  size_t infile;
  size_t outfile;
  size_t count;
  size_t spit;

  opts_parse (&argx, opts, argc, argv,
              "snp-mers [-m col] [-n n-mers] bitset-a bitset-b < table > table");

  if ((argc - argx) != 2)
    Fatal ("usage: snp-mers [-m col] [-n n-mers] a-bitset b-bitset < table > table");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  n_bitset_rows = ((1UL << (2 * n_mers)) >> 5);
  if (!n_bitset_rows)
    Fatal ("bitset too large or small");

  infile = Infile ("-");
  File_fix (infile, 1, 0);
  mer_col = Field_pos (infile, Sym (mer_col_name));
  pos_col = Field_pos (infile, Sym (pos_col_name));

  bitset_a_infile = Infile (argv[argx]);
  bitset_b_infile = Infile (argv[argx + 1]);
  File_fix (bitset_a_infile, n_bitset_rows, 0);
  File_fix (bitset_b_infile, n_bitset_rows, 0);

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint64"), Sym ("mer0"));
  Add_field (outfile, Sym ("uint32"), Sym ("pos0"));
  Add_field (outfile, Sym ("int8"), Sym ("errpos"));
  Add_field (outfile, Sym ("int8"), Sym ("in_a?"));
  Add_field (outfile, Sym ("int8"), Sym ("in_b?"));
  File_fix (outfile, n_mers, 0);
  
  count = 0;
  spit = 0;
  while (N_ahead (infile) >= 1)
    {
      t_taql_uint64 mer0;
      t_taql_uint32 pos0;
      int n_position;

      mer0 = as_uInt64 (Peek (infile, 0, mer_col));
      pos0 = as_uInt32 (Peek (infile, 0, pos_col));

      ++count;
      if (!(count % 1000000))
        {
          fprintf (stderr, "count is %lu (pos is %lu, spit is %lu)\n",
                   (unsigned long)count,
                   (unsigned long)pos0,
                   (unsigned long)spit);
        }

      n_position = -1;

      {
        int x;

        for (x = 0; x < n_mers; ++x)
          {
            if (bp_possibilities_count[(0xf & (mer0 >> (x * 4)))] != 1)
              {
                if (n_position < 0)
                  n_position = x;
                else
                  {
                    n_position = -2;
                    break;
                  }
              }
          }
      }

      if (n_position > -2)
        {
          if (n_position == -1)
            {
              int x;

              /* try the unmodified mer
               */
              if (maybe_poke (outfile, mer0, n_mers, pos0, -1, bitset_a_infile, bitset_b_infile))
                ++spit;

              /* try all the one-snp possibilities
               */
              for (x = 0; x < n_mers; ++x)
                {
                  const t_taql_uint64 bp = (0xf & (mer0 >> (4 * x)));
                  int y;

                  for (y = 0; y < 4; ++y)
                    {
                      const t_taql_uint64 maybe_new_bp = acgt_to_bp[y];

                      if (maybe_new_bp != bp)
                        {
                          const t_taql_uint64 snped_mer
                            = (   (mer0 & ~(0xfULL << (4 * x)))
                               || (maybe_new_bp << (4 * x)));

                          if (maybe_poke (outfile,
                                          snped_mer, n_mers, pos0, x,
                                          bitset_a_infile, bitset_b_infile))
                            {
                              ++spit;
                            }
                        }
                    }
                }
            }
          else
            {
              const t_taql_uint64 ambig_bp
                = (0xf & (mer0 >> (4 * n_position)));
              int y;

              for (y = 0; y < 4; ++y)
                {
                  const t_taql_uint64 maybe_new_bp = acgt_to_bp[y];

                  if (maybe_new_bp & ambig_bp)
                    {
                      const t_taql_uint64 snped_mer
                        = (   (mer0 & ~(0xfULL << (4 * n_position)))
                           || (maybe_new_bp << (4 * n_position)));

                      if (maybe_poke (outfile,
                                      snped_mer, n_mers, pos0, n_position,
                                      bitset_a_infile, bitset_b_infile))
                        {
                          ++spit;
                        }
                    }
                }
            }
        }
      Advance (infile, 1);
    }

  fprintf (stderr, "final count is %lu (spit is %lu)\n",
           (unsigned long)count,
           (unsigned long)spit);
  
  Close (outfile);
  Close (infile);
}


/* arch-tag: Thomas Lord Mon Nov  6 17:48:27 2006 (snp-mers/snp-mers.c)
 */
