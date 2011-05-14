/* place-mers.c: 
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

/* Input read entirely into memory includes a table of reads:
 * 
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 *     # ... other fields ....
 *
 * An index table to that:
 * 
 *     # field "head" "uint32"
 *     # field "next" "uint32"
 * 
 * Input that is scanned is a set of candidates:
 * 
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 *     # field "pos0" "uint32"
 *     ... other fields ...
 * 
 * Streaming over that input, map into read
 * records and output a list of matches:
 * 
 *     # field "mer0" "uint64"
 *     # field "mer1" "uint64"
 *     # field "mer0a" "uint64"   ; from the samples
 *     # field "mer1a" "uint64"
 *     # field "pos0" "uint32"
 *     ... other fields ...
 * 
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"


int
rawletter (size_t seqfile,
	   size_t seq_mer0_col,
	   int n_mers,
	   size_t pos)
{
  size_t cur_recno = Recno (seqfile);
  size_t rec_pos = cur_recno * n_mers;
  size_t rel_pos = pos - rec_pos;
  size_t pos_rel_rec = rel_pos / n_mers;
  size_t letter_offset = rel_pos % n_mers;
  t_taql_uint64 mer = as_uInt64 (Peek (seqfile, pos_rel_rec, seq_mer0_col));
  int raw_letter = (int)(0xf & (mer >> (letter_offset * 4)));

  return raw_letter;
}


t_taql_uint64
letters (size_t reffile,
	 size_t ref_mer0_col,
	 int n_mers,
	 int pos,
	 int len)
{
  t_taql_uint64 mer = 0;
  int l;
  int x;

  if (pos < 0)
    {
      len += pos;
      pos = 0;
    }

  if (len <= 0)
    {
      return mer;
    }

  for (x = len - 1; x >= 0; --x)
    {
      l = rawletter (reffile, ref_mer0_col, n_mers, pos + x);
      mer = (mer << 4) | (l & 0xf);
    }

  return mer;
}
	 

void
begin (int argc, const char * argv[])
{
  int argx;
  const char * n_mers_spec = "13";
  int n_mers;
  const char * mer0_read_col_name = "mer0";
  size_t mer0_read_col;
  const char * mer1_read_col_name = "mer1";
  size_t mer1_read_col;
  const char * chr0_read_col_name = "chrom0";
  size_t chr0_read_col;
  const char * pos0_read_col_name = "start";
  size_t pos0_read_col;
  const char * head_hashtab_col_name = "head";
  size_t head_hashtab_col;
  const char * next_hashtab_col_name = "next";
  size_t next_hashtab_col;
  const char * mer0_candidate_col_name = "mer0";
  size_t mer0_candidate_col;
  const char * mer1_candidate_col_name = "mer1";
  size_t mer1_candidate_col;
  const char * pos0_candidate_col_name = "pos0";
  size_t pos0_candidate_col;
  const char * gap_candidate_col_name = "gap";
  size_t gap_candidate_col;
  const char * errpos0_candidate_col_name = "errpos0";
  size_t errpos0_candidate_col;
  const char * errpos1_candidate_col_name = "errpos1";
  size_t errpos1_candidate_col;
  const char * mer0_ref_col_name = "mer0";
  size_t mer0_ref_col;
  size_t readfile;
  size_t hashfile;
  size_t reffile;
  size_t seqfile;
  size_t outfile;
  size_t inrec_outfile_col;
  size_t pos0_outfile_col;
  size_t mer0pre_outfile_col;
  size_t mer0ref_outfile_col;
  size_t mer0gap_outfile_col;
  size_t mer1gap_outfile_col;
  size_t mer1ref_outfile_col;
  size_t mer1suf_outfile_col;
  size_t gap_outfile_col;
  size_t errpos0_outfile_col;
  size_t errpos1_outfile_col;
  size_t strand_outfile_col;
  size_t mer0in_outfile_col;
  size_t mer1in_outfile_col;
  size_t chr0in_outfile_col;
  size_t pos0in_outfile_col;
  size_t sample_rows;
  size_t hash_mask;
  struct opts opts[] = 
    {
      { OPTS_ARG, 0, "--mer0-read-column", 0, &mer0_read_col_name },
      { OPTS_ARG, 0, "--mer1-read-column", 0, &mer1_read_col_name },
      { OPTS_ARG, 0, "--chr0-read-column", 0, &chr0_read_col_name },
      { OPTS_ARG, 0, "--pos0-read-column", 0, &pos0_read_col_name },
      { OPTS_ARG, 0, "--mer0-candidate-column", 0, &mer0_candidate_col_name },
      { OPTS_ARG, 0, "--mer1-candidate-column", 0, &mer1_candidate_col_name },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_END, }
    };

  opts_parse (&argx, opts, argc, argv,
              "place-mers [--mer0-read-column col-name] [--mer1-...] [--mer0-candidate-column col-name] [--mer1-...] [-n n-mers] samples.dat samples.index sequence.dat < candidates > matches");

  if (argc - argx != 3)
    Fatal ("usage: place-mers [--mer0-read-column col-name] [--mer0-...] [--mer0-candidate-column col-name] [--mer1-...] [-n n-mers] samples.dat samples.index sequence.dat < candidates > matches");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  readfile = Infile (argv[argx]);
  File_fix (readfile, 0, 0);
  mer0_read_col = Field_pos (readfile, Sym (mer0_read_col_name));
  mer1_read_col = Field_pos (readfile, Sym (mer1_read_col_name));
  chr0_read_col = Field_pos (readfile, Sym (chr0_read_col_name));
  pos0_read_col = Field_pos (readfile, Sym (pos0_read_col_name));

  hashfile = Infile (argv[argx+1]);
  File_fix (hashfile, 0, 0);
  head_hashtab_col = Field_pos (hashfile, Sym (head_hashtab_col_name));
  next_hashtab_col = Field_pos (hashfile, Sym (next_hashtab_col_name));

  reffile = Infile (argv[argx+2]);
  File_fix (reffile, 0, 0);
  mer0_ref_col = Field_pos (reffile, Sym (mer0_ref_col_name));

  seqfile = Infile ("-");
  File_fix (seqfile, 1, 0);
  mer0_candidate_col = Field_pos (seqfile, Sym (mer0_candidate_col_name));
  mer1_candidate_col = Field_pos (seqfile, Sym (mer1_candidate_col_name));
  pos0_candidate_col = Field_pos (seqfile, Sym (pos0_candidate_col_name));
  gap_candidate_col = Field_pos (seqfile, Sym (gap_candidate_col_name));
  errpos0_candidate_col = Field_pos (seqfile, Sym (errpos0_candidate_col_name));
  errpos1_candidate_col = Field_pos (seqfile, Sym (errpos1_candidate_col_name));

  outfile = Outfile ("-");
  Add_field (outfile, Sym ("uint32"), Sym ("inrec"));    inrec_outfile_col = 0;
  Add_field (outfile, Sym ("uint32"), Sym ("pos0"));     pos0_outfile_col = 1;
  Add_field (outfile, Sym ("uint64"), Sym ("mer0pre"));  mer0pre_outfile_col = 2;
  Add_field (outfile, Sym ("uint64"), Sym ("mer0ref"));  mer0ref_outfile_col = 3;
  Add_field (outfile, Sym ("uint64"), Sym ("mer0gap"));  mer0gap_outfile_col = 4;
  Add_field (outfile, Sym ("uint64"), Sym ("mer1gap"));  mer1gap_outfile_col = 5;
  Add_field (outfile, Sym ("uint64"), Sym ("mer1ref"));  mer1ref_outfile_col = 6;
  Add_field (outfile, Sym ("uint64"), Sym ("mer1suf"));  mer1suf_outfile_col = 7;
  Add_field (outfile, Sym ("uint32"), Sym ("gap"));      gap_outfile_col = 8;
  Add_field (outfile, Sym ("int8"), Sym ("errpos0"));    errpos0_outfile_col = 9;
  Add_field (outfile, Sym ("int8"), Sym ("errpos1"));    errpos1_outfile_col = 10;
  Add_field (outfile, Sym ("int8"), Sym ("strand"));     strand_outfile_col = 11;
  Add_field (outfile, Sym ("uint64"), Sym ("mer0in"));   mer0in_outfile_col = 12;
  Add_field (outfile, Sym ("uint64"), Sym ("mer1in"));   mer1in_outfile_col = 13;
  Add_field (outfile, Sym ("sym"), Sym ("chr0in"));      chr0in_outfile_col = 14;
  Add_field (outfile, Sym ("uint32"), Sym ("pos0in"));   pos0in_outfile_col = 15;
  File_fix (outfile, 1, 0);

  sample_rows = N_ahead (readfile);
  {
    size_t x;
    x = sample_rows + 1;
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    hash_mask = x;
  }


  while (N_ahead (seqfile))
    {
      t_taql_uint64 mer0 = as_uInt64 (Peek (seqfile, 0, mer0_candidate_col));
      t_taql_uint64 mer1 = as_uInt64 (Peek (seqfile, 0, mer1_candidate_col));

      size_t hash_value;

      if (hash_mer_2 (&hash_value, mer0, mer1, n_mers))
        {
          size_t row = (hash_value & hash_mask);
          size_t hash_head = (size_t)as_uInt32 (Peek (hashfile, row, head_hashtab_col));
          size_t hash_next = (size_t)as_uInt32 (Peek (hashfile, hash_head, next_hashtab_col));
	  size_t gap = as_uInt32 (Peek (seqfile, 0, gap_candidate_col));
	  size_t errpos0 = as_Int8 (Peek (seqfile, 0, errpos0_candidate_col));
	  size_t errpos1 = as_Int8 (Peek (seqfile, 0, errpos1_candidate_col));

          while (hash_head)
            {
              t_taql_uint64 read_mer0 = as_uInt64 (Peek (readfile,
                                                         hash_head - 1,
                                                         mer0_read_col));
              t_taql_uint64 read_mer1 = as_uInt64 (Peek (readfile,
                                                         hash_head - 1,
                                                         mer1_read_col));


              if (   mers_eqv (mer0, read_mer0, n_mers)
                  && mers_eqv (mer1, read_mer1, n_mers))
                {
                  t_taql_uint32 pos0 = as_uInt32 (Peek (seqfile, 0, pos0_candidate_col));
		  t_taql_boxed read_chr0 = Peek (readfile,
						 hash_head - 1,
						 chr0_read_col);
		  t_taql_boxed read_pos0 = Peek (readfile,
						 hash_head - 1,
						 pos0_read_col);

                  Poke (outfile, 0, inrec_outfile_col, uInt32 ((hash_head - 1) >> 1));
                  Poke (outfile, 0, pos0_outfile_col, uInt32 (pos0));
		  Poke (outfile, 0, mer0pre_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0 - n_mers, n_mers)));
                  Poke (outfile, 0, mer0ref_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0, n_mers)));
		  Poke (outfile, 0, mer0gap_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0 + n_mers, (gap > n_mers) ? n_mers : gap)));
		  Poke (outfile, 0, mer1gap_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0 + n_mers * 2, (gap > n_mers * 2) ? n_mers : gap - n_mers)));
                  Poke (outfile, 0, mer1ref_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0 + n_mers + gap, n_mers)));
		  Poke (outfile, 0, mer1suf_outfile_col, uInt64
			(letters (reffile, mer0_ref_col, n_mers, pos0 + n_mers * 2 + gap, n_mers)));
		  Poke (outfile, 0, gap_outfile_col, uInt32 (gap));
		  Poke (outfile, 0, errpos0_outfile_col, Int8 (errpos0));
		  Poke (outfile, 0, errpos1_outfile_col, Int8 (errpos1));
		  Poke (outfile, 0, strand_outfile_col, Int8 ((hash_head - 1) & 0x1));
                  Poke (outfile, 0, mer0in_outfile_col, uInt64 (mer0));
                  Poke (outfile, 0, mer1in_outfile_col, uInt64 (mer1));
                  Poke (outfile, 0, chr0in_outfile_col, read_chr0);
                  Poke (outfile, 0, pos0in_outfile_col, read_pos0);
                  Advance (outfile, 1);
                }

              hash_head = hash_next;
              hash_next = (size_t)as_uInt32 (Peek (hashfile, hash_head, next_hashtab_col));
            }
        }

      Advance (seqfile, 1);
    }

  Close (outfile);
}


/* arch-tag: Thomas Lord Thu Nov  9 11:32:45 2006 (place-mers/place-mers.c)
 */

