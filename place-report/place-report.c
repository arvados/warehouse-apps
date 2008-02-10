/* place-report.c: 
 *
 ****************************************************************
 * Copyright (C) 2007 Harvard University
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

/* a number of mers ("-N") have been placed.
 * placement ("-p") input has fields inrec, pos0, pos1, ..., posM
 * reference ("-r") input has field mer0.
 * sample ("-s") input has fields mer0, mer1, ..., merM
 *
 * n_mers ("-n") is the length of the mers.
 *
 * output ("-o") has fields inrec, pos0, pos1, ..., posM, gapmer0, gapmer1.
 *
 * if desired ("--output-gap0"), some gap contents are output as well:
 * gapmer0 == first part of first gap (0..16 symbols long)
 * gapmer1 == next part of first gap (0..16 symbols long)
 *
 * The "gap" is the reference data between positions {pos0+n_mers} and
 * {pos1}
 * 
 */


#include "libtaql/taql.h"
#include "libcmd/opts.h"
#include "taql/mers/mer-utils.ch"

#define MERCOUNT_MAX	(4)


static const char * placement_file_name = "-";
static size_t placement_file = 0;
static const char * reference_file_name = "/dev/null";
static size_t reference_file = 0;
static size_t reference_file_rows;
static const char * sample_file_name = "/dev/null";
static size_t sample_file = 0;
static const char * output_file_name = "-";
static size_t output_file = 0;

static const char * mercount_spec = "2";
static int mercount;
static const char * n_mers_spec = "16";
static int n_mers;
static const char * gap_min_spec = "0";
static size_t gap_min;
static const char * gap_max_spec = "0";
static size_t gap_max;
static const char * gap_pos_spec = "0";
static size_t gap_pos;
static t_taql_uint64 placepos_per_refpos;

static const char * placement_inrec_col_name = "sample";
static size_t placement_inrec_col;
static const char * placement_pos_col_name[MERCOUNT_MAX] = { "pos0", "pos1", "pos2", "pos3" };
static size_t placement_pos_col[MERCOUNT_MAX];
static int two_inrecs_per_sample = 0;

static size_t reference_mer_col;

static const char * sample_mer_col_name[MERCOUNT_MAX] =
  { "mer0", "mer1", "mer2", "mer3" };
static size_t sample_mer_col[MERCOUNT_MAX];

static size_t output_inrec_col;
static size_t output_pos_col[MERCOUNT_MAX];
static size_t output_gapmer0_col;
static size_t output_gapmer1_col;
static size_t output_premer0_col;
static size_t output_refmer_col;
static size_t output_samplemer_col[MERCOUNT_MAX] = { -1, -1, -1, -1 };
static size_t output_side_col;
static const char * output_snppos_col_name[MERCOUNT_MAX] = { "snppos0", "snppos1", "snppos2", "snppos3" };
static size_t output_snppos_col[MERCOUNT_MAX];

static const char * bp_after_match_spec = "8";
static size_t bp_after_match;
static size_t mers_after_match;
static int all_sample_fields = 0;
static int output_gap_contents = 0;
static int output_prefix_contents = 0;
static size_t output_sample_fields_col;

t_taql_uint64
peek_reference (t_taql_uint64 pos,
		size_t len,
		size_t gappos,
		size_t gapsize)
{
  t_taql_uint64 mer = 0;
  size_t x;
  int shift = 0;

  /* FIXME: I assume n_mers in reference file == n_mers in samples file */

  for (x = 0; x < len; ++x)
    {
      if (x == gappos)
	{
	  pos += gapsize;
	}
      if (pos / n_mers >= reference_file_rows)
	{
	  return mer;
	}
      t_taql_uint64 mer_here;
      mer_here = as_uInt64 (Peek (reference_file, pos / n_mers, reference_mer_col));
      mer_here = mer_here >> (4 * (pos % n_mers));
      mer = (mer & ~(0xfull << shift))
	| ((mer_here & 0xfull) << shift);
      shift += 4;
      ++pos;
    }

  return mer;
}


/* Count how many [of the first n_mers] positions differ between two mers.
 *
 * The last SNP position (0..n_mers-1) is returned in *snppos_ret.
 * *snppos_ret is -1 if the mers are identical.
 */

unsigned int
count_snps (t_taql_uint64 samplemer,
	    t_taql_uint64 refmer,
	    int *snppos_ret)
{
  int snpcount = 0;
  int x;

  if (snppos_ret) *snppos_ret = -1;

  for (x = 0; x < n_mers * 4; x += 4)
    {
      if (((samplemer >> x) & 0xf)
	  !=
	  ((refmer >> x) & 0xf))
	{
	  if (snppos_ret) *snppos_ret = x/4;
	  ++snpcount;
	}
    }
  return snpcount;
}

void
begin (int argc, const char * argv[])
{
  int argx;
  size_t c;
  char mer_col_name[8];
  size_t x;
  size_t m;

  struct opts opts[] = 
    {
      { OPTS_ARG, "-p", "--placements INPUT", 0, &placement_file_name },
      { OPTS_ARG, "-r", "--reference INPUT", 0, &reference_file_name },
      { OPTS_ARG, "-s", "--samples INPUT", 0, &sample_file_name },
      { OPTS_ARG, "-o", "--output OUTPUT", 0, &output_file_name },
      { OPTS_ARG, "-i", "--inrec-col", 0, &placement_inrec_col_name },
      { OPTS_ARG, 0, "--mer0-col", 0, &sample_mer_col_name[0] },
      { OPTS_ARG, 0, "--mer1-col", 0, &sample_mer_col_name[1] },
      { OPTS_ARG, 0, "--mer2-col", 0, &sample_mer_col_name[2] },
      { OPTS_ARG, 0, "--mer3-col", 0, &sample_mer_col_name[3] },
      { OPTS_ARG, "-n", "--n-mers", 0, &n_mers_spec },
      { OPTS_ARG, "-N", "--mercount", 0, &mercount_spec },
      { OPTS_ARG, 0, "--gap-min", 0, &gap_min_spec },
      { OPTS_ARG, 0, "--gap-max", 0, &gap_max_spec },
      { OPTS_ARG, 0, "--gap-pos", 0, &gap_pos_spec },
      { OPTS_FLAG, 0, "--two-inrecs-per-sample", &two_inrecs_per_sample, 0 },
      { OPTS_ARG, 0, "--bp-after-match", 0, &bp_after_match_spec },
      { OPTS_FLAG, 0, "--all-sample-fields", &all_sample_fields, 0 },
      { OPTS_FLAG, 0, "--output-gap0", &output_gap_contents, 0 },
      { OPTS_FLAG, 0, "--output-prefix", &output_prefix_contents, 0 },
      { OPTS_END, }
    };
  
  opts_parse (&argx, opts, argc, argv,
              "place-report -n n-mers -r reference -s samples -p placements [-o output] ...");

  if ((argc - argx) != 0)
    Fatal ("usage: place-report -n n-mers -r reference -s samples -p placements [-o output] ...");

  n_mers = atoi (n_mers_spec);
  if ((n_mers <= 0) || (n_mers > 16))
    Fatal ("bogus mer size");

  mercount = atoi (mercount_spec);
  if ((mercount <= 0) || (mercount > MERCOUNT_MAX))
    Fatal ("bogus mercount");

  gap_min = atoi (gap_min_spec);
  if (gap_min < 0)
    Fatal ("bogus gap_min");

  gap_max = atoi (gap_max_spec);
  if (gap_max < gap_min)
    Fatal ("bogus gap_max");

  gap_pos = atoi (gap_pos_spec);
  if (gap_pos < 0 || gap_pos >= n_mers)
    Fatal ("bogus gap_pos");

  bp_after_match = atoi (bp_after_match_spec);
  if (bp_after_match < 0)
    Fatal ("bogus bp_after_match");
  if (bp_after_match == 0)
    mers_after_match = 0;
  else
    mers_after_match = ((bp_after_match-1)>>4)+1;

  placepos_per_refpos = 1 + gap_max - gap_min;

  placement_file = Infile (placement_file_name);
  File_fix (placement_file, 1, 0);
  placement_inrec_col = Field_pos (placement_file, Sym (placement_inrec_col_name));
  for (m = 0; m < mercount; ++m)
    {
      placement_pos_col[m] = Field_pos (placement_file, Sym (placement_pos_col_name[m]));
    }

  reference_file = Infile (reference_file_name);
  File_fix (reference_file, 0, 0);
  reference_mer_col = Field_pos (reference_file, Sym ("mer0"));
  reference_file_rows = N_ahead (reference_file);

  sample_file = Infile (sample_file_name);
  File_fix (sample_file, 0, 0);
  for (m = 0; m < mercount; ++m)
    {
      sample_mer_col[m] = Field_pos (sample_file, Sym (sample_mer_col_name[m]));
    }

  output_file = Outfile (output_file_name);
  for (c = 0; c < N_fields (placement_file); ++c)
    {
      Add_field (output_file,
		 Field_type (placement_file, c),
		 Field_name (placement_file, c));
    }
  output_inrec_col = placement_inrec_col;
  for (m = 0; m < mercount; ++m)
    {
      output_pos_col[m] = placement_pos_col[m];
    }
  if (output_gap_contents)
    {
      Add_field (output_file, Sym ("uint64"), Sym ("mer0gap"));
      Add_field (output_file, Sym ("uint64"), Sym ("mer1gap"));
      output_gapmer0_col = c++;
      output_gapmer1_col = c++;
    }
  if (output_prefix_contents)
    {
      Add_field (output_file, Sym ("uint64"), Sym ("mer0pre"));
      output_premer0_col = c++;
    }

  output_refmer_col = c;
  for (x = 0; x < mercount + mers_after_match; ++x)
    {
      snprintf (mer_col_name, sizeof(mer_col_name), "mer%dref", x);
      Add_field (output_file, Sym ("uint64"), Sym (mer_col_name));
      ++c;
    }

  if (all_sample_fields)
    {
      output_sample_fields_col = c;
      for (x = 0; x < N_fields (sample_file); ++x, ++c)
	{
	  Add_field (output_file,
		     Field_type (sample_file, x),
		     Field_name (sample_file, x));

	  for (m = 0; m < mercount; ++m)
	    {
	      if (Eq (Field_name (sample_file, x),
		      Sym (sample_mer_col_name[m])))
		output_samplemer_col[m] = c;
	    }
	}
    }
  else
    {
      for (m = 0; m < mercount; ++m)
	{
	  Add_field (output_file, Sym ("uint64"), Sym (sample_mer_col_name[m]));
	  output_samplemer_col[m] = c++;
	}
    }
  Add_field (output_file, Sym ("int8"), Sym ("side"));
  output_side_col = c++;
  for (m = 0; m < mercount; ++m)
    {
      Add_field (output_file, Sym ("int8"), Sym (output_snppos_col_name[m]));
      output_snppos_col[m] = c++;
    }

  File_fix (output_file, 1, 0);
  
  while (N_ahead (placement_file) >= 1)
    {
      t_taql_uint64 samplemer[MERCOUNT_MAX];
      t_taql_uint64 refmer[MERCOUNT_MAX];
      t_taql_uint64 gapmer0;
      t_taql_uint64 gapmer1;
      t_taql_uint64 placepos[MERCOUNT_MAX];
      t_taql_uint64 pos[MERCOUNT_MAX];
      t_taql_uint64 smallgapsize[MERCOUNT_MAX];
      t_taql_uint64 inrec = as_uInt64 (Peek (placement_file, 0, placement_inrec_col));
      t_taql_uint64 sample_row = two_inrecs_per_sample ? (inrec >> 1) : inrec;
      size_t refbps, refmers;
      int snppos[MERCOUNT_MAX];
      int side;

      for (m = 0; m < mercount; ++m)
	{
	  placepos[m] = as_uInt64 (Peek (placement_file, 0, placement_pos_col[m]));
	  pos[m] = placepos[m] / placepos_per_refpos;
	  smallgapsize[m] = gap_min + (placepos[m] % placepos_per_refpos);
	}

      if (!output_gap_contents)
	{
	  ;
	}
      else if (gap_max > 0)
	{
	  /* gapmer0 and gapmer1 are the reference data in the small gap (in the middle of mer0 and mer1) */
	  Poke (output_file, 0, output_gapmer0_col, uInt64 (peek_reference (pos[0]+gap_pos, smallgapsize[0], 0, 0)));
	  Poke (output_file, 0, output_gapmer1_col, uInt64 (peek_reference (pos[1]+gap_pos, smallgapsize[1], 0, 0)));
	}
      else
	{
	  /* gapmer0 and gapmer1 are the first 32 nucleotides between refmer0 and refmer1 */
	  t_taql_uint64 gappos0 = pos[0] + n_mers + smallgapsize[0];
	  t_taql_uint64 gappos1 = pos[0] + n_mers + smallgapsize[0] + 16;
	  size_t gapsize0;
	  size_t gapsize1 = 0;
	  gapsize0 = pos[1] - pos[0] - n_mers;
	  if (gapsize0 > 16)
	    {
	      gapsize1 = gapsize0 - 16;
	      if (gapsize1 > 16)
		{
		  gapsize1 = 16;
		}
	      gapsize0 = 16;
	    }
	  gapmer0 = peek_reference (gappos0, gapsize0, 0, 0);
	  gapmer1 = peek_reference (gappos1, gapsize1, 0, 0);
	  Poke (output_file, 0, output_gapmer0_col, uInt64 (gapmer0));
	  Poke (output_file, 0, output_gapmer1_col, uInt64 (gapmer1));
	}

      for (c = 0; c < N_fields (placement_file); ++c)
	{
	  Poke (output_file, 0, c, Peek (placement_file, 0, c));
	}
      for (m = 0; m < mercount; ++m)
	{
	  Poke (output_file, 0, placement_pos_col[m], uInt64 (pos[m]));
	  refmer[m] = peek_reference (pos[m], n_mers, gap_pos, smallgapsize[m]);
	  samplemer[m] = as_uInt64 (Peek (sample_file, sample_row, sample_mer_col[m]));
	}

      side = -2;
      if (two_inrecs_per_sample)
	{
	  side = inrec & 1;
	  Poke (output_file, 0, output_inrec_col, uInt64 (sample_row));
	  for (m = 0; m < mercount; ++m)
	    {
	      if (1 < count_snps (samplemer[m],
				  side
				  ? mer_reverse_complement (refmer[mercount-m], n_mers)
				  : refmer[m],
				  &snppos[m]))
		{
		  side = -2;
		}
	    }
	}
      else if (side < 0)
	{
	  for (m = 0; m < mercount; ++m)
	    {
	      if (1 < count_snps (samplemer[m], refmer[m], &snppos[m]))
		{
		  side = -2;
		  break;
		}
	    }
	  if (m == mercount)
	    {
	      side = 0;
	    }
	  else
	    {
	      for (m = 0; m < mercount; ++m)
		{
		  if (1 < count_snps (samplemer[m],
				      mer_reverse_complement (refmer[mercount-m], n_mers),
				      &snppos[m]))
		    {
		      side = -2;
		      break;
		    }
		}
	      if (m == mercount)
		{
		  side = 1;
		}
	    }
	}
      if (side < 0)
	{
	  for (m = 0; m < mercount; ++m)
	    {
	      snppos[m] = -2;
	    }
	}

      if (output_prefix_contents)
	{
	  t_taql_uint64 prepos = (pos[0]<8)?0:(pos[0]-8);
	  Poke (output_file, 0, output_premer0_col, uInt64 (peek_reference (prepos, pos[0]-prepos, 0, 0)));
	}
      for (m = 0; m < mercount; ++m)
	{
	  Poke (output_file, 0, output_refmer_col+m, uInt64 (refmer[m]));
	}
      for (refmers = 0, refbps = bp_after_match;
	   refmers < mers_after_match;
	   ++refmers, refbps -= 16)
	{
	  Poke (output_file, 0, output_refmer_col + refmers + mercount,
		uInt64 (peek_reference (pos[mercount] + n_mers + smallgapsize[mercount] + (refmers * 16), (refbps>16)?16:refbps, 0, 0)));
	}
      if (all_sample_fields)
	{
	  for (c = 0; c < N_fields (sample_file); ++c)
	    {
	      Poke (output_file, 0, c + output_sample_fields_col, Peek (sample_file, sample_row, c));
	    }
	}
      for (m = 0; m < mercount; m++)
	{
	  Poke (output_file, 0, output_samplemer_col[m], uInt64 (samplemer[m]));
	}
      Poke (output_file, 0, output_side_col, Int8 (side));
      for (m = 0; m < mercount; m++)
	{
	  Poke (output_file, 0, output_snppos_col[m], Int8 (snppos[m]));
	}

      Advance (output_file, 1);
      Advance (placement_file, 1);
    }

  Close (output_file);
  Close (sample_file);
  Close (reference_file);
  Close (placement_file);
}


/* arch-tag: Tom Clegg Tue Jan 16 17:52:45 PST 2007 (place-report/place-report.c)
 */
