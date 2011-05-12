/* billy-candidates.c: 
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
 *     # field "errpos" "int8"
 *     # field "in_a?" "int8"
 *     # field "in_b?" "int8"
 * 
 * Second input is the reference sequence that's from.
 * 
 * Parameters include:
 * 
 *     n-mers -- the mer size
 *     gap-low/gap-high
 * 
 * This is a "billy" tool because we're only handling read
 * placement of 2-mer reads, with both mers the same size.
 * 
 * 
 * Output:
 * 
 *     # field "pos0" "uint32"
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 *     # field "gap" "uint8"
 *     # field "errpos0" "int8"
 *     # field "errpos1" "int8"
 * 
 * The output has the property
 * that it includes every candidate match
 * which is consistent with the parameters 
 * (gap-low/gap-high) and the input file ("mers of 
 * interest").
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"


t_taql_uint64
bp_from_ref (size_t seqfile,
             size_t seq_mer0_col,
             int n_mers,
             size_t pos)
{
  size_t cur_recno = Recno (seqfile);
  size_t rec_pos = cur_recno * n_mers;
  size_t rel_pos = pos - rec_pos;
  size_t pos_rel_rec = rel_pos / n_mers;
  size_t letter_offset = rel_pos % n_mers;

  if (pos_rel_rec >= N_ahead (seqfile))
    return -1;

  t_taql_uint64 mer = as_uInt64 (Peek (seqfile, pos_rel_rec, seq_mer0_col));
  int raw_letter = (int)(0xf & (mer >> (letter_offset * 4)));

  return raw_letter;
}


size_t
max_letter_constraint_bound (size_t seqfile,
                             size_t seq_mer0_col,
                             int n_mers,
                             size_t gap_start,
                             t_taql_uint32 gap_max,
			     t_taql_uint32 maxlettersingap)
{
  size_t desired_recno = (gap_start / n_mers);
  size_t actual_recno = Recno (seqfile);
  size_t x;
  t_taql_uint64 bps_seen;

  if (actual_recno != desired_recno)
    {
      if (actual_recno > desired_recno)
        Fatal ("bug");

      Advance (seqfile, (desired_recno - actual_recno));
    }

  bps_seen = 0;

  for (x = 0; x < gap_max; ++x)
    {
      bps_seen |= bp_from_ref (seqfile, seq_mer0_col, n_mers, gap_start + x);

      if (bp_possibilities_count[bps_seen] > maxlettersingap)
        return gap_start + x;
    }
  return gap_start + x;
}



void
begin (int argc, const char * argv[])
{
  int argx;
  const char * mer_col_name = "mer0";
  size_t mer_col;
  const char * pos_col_name = "pos0";
  size_t pos_col;
  const char * errpos_col_name = "errpos";
  size_t errpos_col;
  const char * in_a_col_name = "in_a?";
  size_t in_a_col;
  const char * in_b_col_name = "in_b?";
  size_t in_b_col;
  const char * n_mers_spec = "13";
  int n_mers;
  const char * gap_min_spec = "0";
  t_taql_uint32 gap_min;
  const char * gap_max_spec = "20";
  t_taql_uint32 gap_max;
  const char * maxlettersingap_spec = "2";
  t_taql_uint32 maxlettersingap;
  const char * sequence_file = "/no-sequence-file-specified?";
  size_t seqfile;
  const char * seq_mer0_col_name = "mer0";
  size_t seq_mer0_col;

  struct opts opts[] = 
    {
      { OPTS_ARG, "-m", "--mer-col", 0, &mer_col_name },
      { OPTS_ARG, "-p", "--pos-col", 0, &pos_col_name },
      { OPTS_ARG, "-e", "--errpos-col", 0, &errpos_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_ARG, "-g", "--gap-min", 0, &gap_min_spec },
      { OPTS_ARG, "-G", "--gap-max", 0, &gap_max_spec },
      { OPTS_ARG, "-a", "--a-col", 0, &in_a_col_name },
      { OPTS_ARG, "-b", "--b-col", 0, &in_b_col_name },
      { OPTS_ARG, "-L", "--maxlettersingap", 0, &maxlettersingap_spec },
    };
  
  size_t infile;
  size_t outfile;
  size_t count;

  opts_parse (&argx, opts, argc, argv,
              "billy-candidates [-e errcol] [-m col] [-n n-mers] [-g gap-min] [-G gap-max] [-[ab] a/b-col] reference < table > table");

  if (argx != (argc - 1))
    Fatal ("usage");

  sequence_file = argv[argx];

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  gap_min = atoi (gap_min_spec);
  if (gap_min < 0)
    Fatal ("bogus gap-min");
  
  gap_max = atoi (gap_max_spec);
  if ((gap_max < 0) || (gap_max < gap_min) || (gap_max > (1 << 12)))
    Fatal ("bogus gap-max");

  maxlettersingap = atoi (maxlettersingap_spec);
  if (maxlettersingap < 1 || maxlettersingap > 4)
    Fatal ("bogus maxlettersingap");
  
  
  seqfile = Infile (sequence_file);
  File_fix (seqfile, (gap_max - gap_min), 0);
  seq_mer0_col = Field_pos (seqfile, Sym (seq_mer0_col_name));

  infile = Infile ("-");
  File_fix (infile, (gap_max - gap_min) + 2 * n_mers + 1024, 0);
  mer_col = Field_pos (infile, Sym (mer_col_name));
  pos_col = Field_pos (infile, Sym (pos_col_name));
  errpos_col = Field_pos (infile, Sym (errpos_col_name));
  in_a_col = Field_pos (infile, Sym (in_a_col_name));
  in_b_col = Field_pos (infile, Sym (in_b_col_name));

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint32"), Sym ("pos0"));
  Add_field (outfile, Sym ("uint64"), Sym ("mer0"));
  Add_field (outfile, Sym ("uint64"), Sym ("mer1"));
  Add_field (outfile, Sym ("uint32"), Sym ("gap"));
  Add_field (outfile, Sym ("int8"), Sym ("errpos0"));
  Add_field (outfile, Sym ("int8"), Sym ("errpos1"));
  File_fix (outfile, n_mers, 0);

  count = 0;

  while (N_ahead (infile))
    {
      t_taql_uint64 first_mer = as_uInt64 (Peek (infile, 0, mer_col));
      t_taql_uint32 first_mer_pos = as_uInt32 (Peek (infile, 0, pos_col));
      int first_mer_of_interest = as_Int8 (Peek (infile, 0, in_a_col));
      t_taql_uint32 second_mer_range_start = first_mer_pos + n_mers + gap_min;
      t_taql_uint32 second_mer_range_bound;

      size_t row_offset_bound = N_ahead (infile);
      size_t row_offset;

      if (first_mer_of_interest)
        {
	  if (maxlettersingap < 4)
	    second_mer_range_bound
	      = max_letter_constraint_bound (seqfile,
					     seq_mer0_col,
					     n_mers,
					     second_mer_range_start - gap_min,
					     gap_max,
					     maxlettersingap);
	  else
	    second_mer_range_bound = first_mer_pos + n_mers + gap_max;

          for (row_offset = 1;
               row_offset < row_offset_bound;
               ++row_offset)
            {
              t_taql_uint32 this_mer_pos = as_uInt32 (Peek (infile, row_offset, pos_col));

              if (this_mer_pos < second_mer_range_start)
                continue;

              if (this_mer_pos > second_mer_range_bound)
                break;

              if (!as_Int8 (Peek (infile, row_offset, in_b_col)))
                continue;

              ++count;

              Poke (outfile, 0, 0, uInt32 (first_mer_pos));
              Poke (outfile, 0, 1, uInt64 (first_mer));
              Poke (outfile, 0, 2, Peek (infile, row_offset, mer_col));
              Poke (outfile, 0, 3, uInt32 (this_mer_pos - (first_mer_pos + n_mers)));
              Poke (outfile, 0, 4, Peek (infile, 0, errpos_col));
              Poke (outfile, 0, 5, Peek (infile, row_offset, errpos_col));
              Advance (outfile, 1);
            }
        }
      Advance (infile, 1);
    }

  fprintf (stderr, "candidate count is %lu\n", (unsigned long)count);

  Close (outfile);
  Close (infile);
}


/* arch-tag: Thomas Lord Mon Nov  6 20:17:04 2006 (billy-candidates/billy-candidates.c)
 */
