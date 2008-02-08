/* mer-nfa.c: 
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


#include "libcmd/opts.h"
#include "libtaql/taql.h"
#include "taql/mers/mer-utils.ch"


/* 
 * output: sample#, pos0, pos1, ..., flags (amig + snps)
 */

#define MAX_N_MER_POSITIONS	(4)

static const char * mer_col_names[MAX_N_MER_POSITIONS] = { "mer0", "mer1", "mer2", "mer3" };
static const char * pos_col_names[MAX_N_MER_POSITIONS] = { "pos0", "pos1", "pos2", "pos3" };

/* How many mers in each sample?
 */
static size_t n_mer_positions = 0;

/* Size of each mer in the sample:
 */
static size_t mer_size[MAX_N_MER_POSITIONS];
static size_t max_mer_size = 0;

/* Gap sizes.   gap_X[N] is the size of the
 * gap following mer N.
 */
static size_t gap_min[MAX_N_MER_POSITIONS - 1];
static size_t gap_max[MAX_N_MER_POSITIONS - 1];

/* Range of sizes for a complete match
 */
static size_t maximum_span = 0;
static size_t span_lower_bound = 0;

/* Fuzzy matching for SNPs?
 */
static int permit_snps = 0;

/* Also match against the complement of the
 * reference?
 */
static int match_literal = 1;
static int match_complement = 0;

/* Print even same-ending matches of the
 * same sample?
 */
static int show_all = 0;

struct sample
{
  /* The sample itself:
   */
  t_taql_uint64 mer[MAX_N_MER_POSITIONS];

  /* NFA state information.
   *
   * There are two sets here: one ("[0]") for direct 
   * comparison to the reference and the other ("[1]") 
   * for comparison to the reference complement.
   */
  struct
    {
      /* Last time the NFA state for a given MER was 
       * legitimately entered, if any.
       */
      size_t last_entered_pos[MAX_N_MER_POSITIONS - 1];
      /* Flags describing that last match.
       * 
       * Bit 16 is 1 if last_entered_pos[N] is valid (the
       * state has been reached).
       * 
       * Bits 0..15 contain 1s in any position that the
       * last match assumed a SNP, 0s elsewhere.
       */
      t_taql_uint32 flags[MAX_N_MER_POSITIONS - 1];
    } state[2];
};


/* Linked lists of 'struct sample' (using 
 * integer references, not pointers).
 */
struct sample_list
{
  /* The index of the sample at this list node.
   */
  size_t sample_id;

  /* The next list node.   If 'next_hash' is 0,
   * then this node is the end of the list.
   * If 'next_hash' is N+1, then N is the index
   * of the next list node.
   */
  size_t next_hash;             /* list index + 1 */

  /* These lists are used in a hash table.   All
   * samples which have same-hash-value mers in
   * the same position are stored in a list.
   * 
   * Each sample is stored in the hash table redundantly:
   * once for the mer as it actually occurs in the
   * input, then several times again for each SNP variation
   * on the mer (if the flag 'permit_snps' is not 0).
   *
   * If a list entry was created by hashing a SNP mer,
   * this is the basepair position, within the mer,
   * of the SNP.   Otherwise, 'snp_position' is -1.
   */
  t_taql_int8 snp_position;

  /* if snp_position is not -1, then snp_bp is the 
   * base-pair substitute that was made at snp_position.
   */
  t_taql_int8 snp_bp;
};

struct sample_hash_table
{
  size_t head;
};

size_t n_samples = 0;

/* 'nfa' is an array of 'struct sample' with one
 * entry for each input sample.
 */
static struct sample * nfa = 0;


/* For each mer position (c.f., 'n_mer_positions') there is a
 * hash table.    All samples with the same hash value for 
 * the mer at a given position are stored in the same hash
 * bucket:
 */
static size_t sample_hash_table_size = 0; /* this must be a power of 2! */
static struct sample_hash_table * sample_hash_tables[MAX_N_MER_POSITIONS] = {0,};

/* Hash buckets are stored in 'struct sample_list' lists.
 * These variables hold storage for those lists.
 */
static struct sample_list * sample_list_tables[MAX_N_MER_POSITIONS] = {0,};
static size_t sample_list_table_n_entries[MAX_N_MER_POSITIONS] = { 0, };

/* The program operates on three files:
 */
static const char * reference_file_name = "-";
static size_t reference_file = 0;
static const char * sample_file_name = "/dev/null";
static size_t sample_file = 0;
static const char * output_file_name = "-";
static size_t output_file = 0;

/* From the reference file, the program needs
 * to read just one column which contains a
 * mer from the reference (e.g., 'all-mers' output).
 */
static size_t reference_mer_in_col;

/* From the samples, the program reads one mer
 * column for each of 'n_mer_positions' mers.
 */
static size_t sample_mer_in_col[MAX_N_MER_POSITIONS];


/* The output file contains one column for sample ids
 * of matches, 'n_mer_positions' columns laying out 
 * where the match occured, and a column of flag bits
 * describing the SNP and complement positions, if any,
 * of the match.
 */
static size_t sample_out_col;
static size_t pos_out_col[MAX_N_MER_POSITIONS];
static size_t flags_out_col;




/* Regarding the reference genome as a
 * list of mers, one per reference base
 * position, we can ask whether the mer at
 * a given reference position matches (exactly
 * or not) any mer in the sample set.
 * 
 * The hash tables help answer that question
 * but we need to know what hash values to
 * probe the table with and how to compare 
 * mers to the entries in each bucket.
 * 
 * For each reference mer:
 * 
 * If the reference mer contains only unambiguous
 * base pair letters (e.g., no "N"s) then we'll 
 * probe only exactly for it, and perhaps for its
 * complement.
 * 
 * If the reference contains more than one
 * non-base pair letter, it can't match anything
 * at all (within our one-SNP tolerance).
 * 
 * If the reference mer contains one non-BP 
 * letter, then we probe for four variations
 * of the mer.  (If complementing, each probe
 * involves two comparisons rather than one 
 * per hash bucket.)
 * 
 * There are two kinds of probes.   Hash table
 * entries are either for a sample mer exactly,
 * or for a one-SNP variations on the sample 
 * mer.   Each hash table entry is labeled so we
 * know which are exact and which are one-SNP.
 * 
 * If we are probing for an exact reference mer,
 * that probe is permitted to match 1-SNP varations
 * on sample mers.   On the other hand, if we are
 * probing for a variation on an "N"-containing
 * reference mer, since that variations is already
 * considered to contain a SNP, the probe can only
 * match exact ("0 SNP") sample-mer hash table
 * entries.
 * 
 * This structure is used to describe the set of
 * probes that a given reference mer implies:
 */

struct reference_candidates
{
  int n_variations;             /* 0, 1, or 4 */
  struct reference_candidate
    {
      t_taql_uint64 probe_mer;
      size_t hash_index;
      int snp_position;         /* -1 means no SNP */
    } side[2][4];
  /* side[0] is for sample mers as-is.
   * side[1] is for complements of sample mers.
   */
};




/* We scan the reference genome, one base pair position 
 * at a time, considering the mers that start at that 
 * position.
 * 
 * Some of those mers match transitions in the sample set 
 * NFA.   If the transition starts in the "start" state
 * of the NFA (i.e., the mer matches a position-0 mer in
 * the samples) then the NFA transition is taken.  if the
 * mer matches some later transition in the NFA, that later
 * transition is taken if the previous mer transition for
 * the same sample was taken recently enough that we are within
 * a valid gap range.
 * 
 * Finally, when we find that a transition has been taken for
 * the last mer in a particular sample, we know we matched that
 * sample -- so we can look back at "recent" mer matches and
 * reconstruct exactly how it matched.
 * 
 * For that last step, looking back and reconstructing matches
 * that we know have recently occured, we keep a queue of recent
 * transitions.  We don't need to save transitions from longer
 * ago than implied by the maximum gap sizes and mer sizes, but
 * other than that we have to keep them.
 * 
 * Unfortunately, matters are slightly complicated by the 
 * fact that while the expected-case size of the queue
 * of recent transitions is very small, the worst-case
 * upper bound is n_samples * (1 + max_mer_size * 4)
 * (or something close and equally ridiculous).
 */

struct taken_transition
{
  int side;
  int mer_pos;
  size_t pos;
  t_taql_uint64 mer;
  t_taql_uint32 match_flags;
  size_t sample;
};

static struct taken_transition * taken_transitions = 0;
static size_t size_taken_transitions = 0;
static size_t n_taken_transitions = 0;
static size_t consumed_n_taken_transitions = 0;


/* When a hash probe notes a transition for a mer in
 * the last position, a search of the transition 
 * queue is conducted to reassemble the actual 
 * match (if any -- false positives are still possible).
 * 
 * struct output_record is used to hold the accumulating
 * state of that queue search and, if the search is
 * successful, is used to generate a record for the
 * output file.
 */
struct output_record
{
  size_t positions[MAX_N_MER_POSITIONS];
  t_taql_uint32 flags;
  t_taql_uint32 sample;
};



/* __STDC__ prototypes for static functions */
static void process_command_line_arguments (int argc, const char * argv[]);
static void finalize_files (void);
static void read_samples_building_nfa (void);
static void build_hash_table (void);
static size_t round_up_to_power_of_2 (size_t x);
static void add_to_hash_table (int mer_pos,
                               t_taql_uint64 mer,
                               size_t sample,
                               int snp_position,
                               int snp_bp);
static void reference_candidates (struct reference_candidates * ret,
                                  t_taql_uint64 mer,
                                  size_t mer_size,
                                  size_t hash_table_size);
static int find_non_bp (t_taql_uint64 mer, size_t mer_size);
static void store_variations (struct reference_candidates * ret,
                              int pos,
                              t_taql_uint64 mer,
                              size_t mer_size,
                              int snp_position,
                              size_t hash_table_size);
static void store_variation (struct reference_candidates * ret,
                             int pos,
                             int side,
                             t_taql_uint64 mer,
                             size_t mer_size,
                             int snp_position,
                             size_t hash_table_size);
static t_taql_uint64 complement (t_taql_uint64 mer, size_t mer_size);
static size_t canonicalize_mer (t_taql_uint64 mer,
                                size_t mer_size);
static size_t mer_hash_index (t_taql_uint64 mer,
                              size_t mer_size,
                              size_t hash_table_size);
static void scan_reference_running_nfa (void);
static void do_probe (int side,
                      struct reference_candidate * c,
                      int mer_position,
                      size_t reference_pos);
static int mers_match_p (t_taql_uint64 probe_mer,
                         t_taql_uint64 sample_mer,
                         size_t mer_size);
static void note_plausible_transition (int side,
                                       int mer_pos,
                                       size_t pos,
                                       t_taql_uint64 mer,
                                       int snp_pos,
                                       size_t sample);
static void note_actual_transition (int side,
                                    int mer_pos,
                                    size_t pos,
                                    t_taql_uint64 mer,
                                    int snp_pos,
                                    size_t sample);
static void enqueue_transition (int side,
                                int mer_pos,
                                size_t pos,
                                t_taql_uint64 mer,
                                t_taql_uint32 flags,
                                size_t sample);
static int report_transition (struct output_record * outrec,
                              int side,
                              size_t pos,
                              size_t sample,
                              int mer_pos,
                              t_taql_uint32 flags,
                              size_t qpos,
                              size_t earliest_start_bp_pos,
                              size_t end_start_bp_pos);



void
begin (int argc, const char * argv[])
{
  process_command_line_arguments (argc, argv);
  {
    read_samples_building_nfa ();
    build_hash_table ();
    scan_reference_running_nfa ();
  }
  finalize_files ();
}


/* __STDC__ prototypes for static functions */



static void
process_command_line_arguments (int argc, const char * argv[])
{
  int argx;
  int user_wants_help = 0;
  int user_wants_version = 0;
  const char * mer_size_spec[MAX_N_MER_POSITIONS] = { 0, };
  const char * gap_min_spec[MAX_N_MER_POSITIONS - 1] = { 0, };
  const char * gap_max_spec[MAX_N_MER_POSITIONS - 1] = { 0, };
  int x;
  

  struct opts opts[] = 
    {
      { OPTS_ARG, "-r", "--reference INPUT", 0, &reference_file_name },
      { OPTS_ARG, "-s", "--samples INPUT", 0, &sample_file_name },
      { OPTS_ARG, "-o", "--output OUTPUT", 0, &output_file_name },
      { OPTS_ARG, 0, "--m0", 0, &mer_size_spec[0] },
      { OPTS_ARG, 0, "--m1", 0, &mer_size_spec[1] },
      { OPTS_ARG, 0, "--m2", 0, &mer_size_spec[2] },
      { OPTS_ARG, 0, "--m3", 0, &mer_size_spec[3] },
      { OPTS_ARG, 0, "--gmin0", 0, &gap_min_spec[0] },
      { OPTS_ARG, 0, "--gmin1", 0, &gap_min_spec[1] },
      { OPTS_ARG, 0, "--gmin2", 0, &gap_min_spec[2] },
      { OPTS_ARG, 0, "--gmax0", 0, &gap_max_spec[0] },
      { OPTS_ARG, 0, "--gmax1", 0, &gap_max_spec[1] },
      { OPTS_ARG, 0, "--gmax2", 0, &gap_max_spec[2] },
      { OPTS_FLAG, 0, "--snps", &permit_snps, 0 },
      { OPTS_FLAG, 0, "--complement", &match_complement, 0 },
      { OPTS_FLAG, 0, "--all", &show_all, 0 },
      { OPTS_FLAG, 0, "--version", &user_wants_version, 0 },
      { OPTS_FLAG, "-h", "--help", &user_wants_help, 0 },
      { OPTS_END, }
    };
  
  opts_parse (&argx, opts, argc, argv, "mer-nfa --help");

  if (argx != argc)
    Fatal ("usage: mer-nfa --help");

  if (user_wants_version || user_wants_help)
    {
      printf ("mer-nfa -- development snapshot (no version number)");
      if (user_wants_help)
        {
          printf ("usage: mer-nfa [OPTIONS]\n");
          printf ("\n");
          printf ("  --version                    program version info\n");
          printf ("  --help                       this message\n");
          printf ("\n");
          printf ("  -r|--reference INPUT         reference input file\n");
          printf ("  -s|--samples INPUT           samples input file\n");
          printf ("  -o|--output OUTPUT           output file\n");
          printf ("  --m0|--m1|--m2|--m3 N        mer size\n");
          printf ("  --gmin0|--gmin1|--gmin2 N    min gap size\n");
          printf ("  --gmax0|--gmax1|--gmax2 N    max gap size\n");
          printf ("  --snps                       permit 1 SNP per mer\n");
          printf ("  --complement                 also match reference complement\n");
          exit (0);
        }
    }


  for (n_mer_positions = 0;
       (n_mer_positions < MAX_N_MER_POSITIONS) && (mer_size_spec[n_mer_positions]);
       ++n_mer_positions)
    {
      mer_size[n_mer_positions] = atoi (mer_size_spec[n_mer_positions]);
      if ((0 >= mer_size[n_mer_positions]) || (16 < mer_size[n_mer_positions]))
        {
          fprintf (stderr, "mer-nfa: bogus mer position specification\n");
          exit (2);
        }
      if (mer_size[n_mer_positions] > max_mer_size)
        max_mer_size = mer_size[n_mer_positions];
    }

  {
    int x;

    for (x = 0; x < (n_mer_positions - 1); ++x)
      {
        if (!gap_min_spec[x] || !gap_max_spec[x])
          {
          bad_gap:
            fprintf (stderr, "mer-nfa: bogus gap specification\n");
            exit (2);
          }
        gap_min[x] = atoi (gap_min_spec[x]);
        gap_max[x] = atoi (gap_max_spec[x]);
        if ((gap_min[x] < 0) || (gap_max[x] < gap_min[x]))
          goto bad_gap;
      }
  }

  {
    int x;
    
    maximum_span = 0;
    span_lower_bound = 0;

    for (x = 0; x < n_mer_positions; ++x)
      {
        maximum_span += mer_size[x];
        span_lower_bound += mer_size[x];
        if (x < (n_mer_positions - 1))
          {
            maximum_span += gap_max[x];
            span_lower_bound += gap_min[x];
          }
      }
    --span_lower_bound;
  }

  reference_file = Infile (reference_file_name);
  File_fix (reference_file, 1, 0);
  reference_mer_in_col = Field_pos (reference_file, Sym ("mer0"));

  sample_file = Infile (sample_file_name);
  File_fix (sample_file, 1, 0);

  output_file = Outfile (output_file_name);
  Add_field (output_file, Sym ("uint32"), Sym ("sample"));
  Add_field (output_file, Sym ("uint32"), Sym ("flags"));
  sample_out_col = 0;
  flags_out_col = 1;

  for (x = 0; x < n_mer_positions; ++x)
    {
      Add_field (output_file, Sym ("uint32"), Sym (pos_col_names[x]));
      pos_out_col[x] = 2 + x;
      sample_mer_in_col[x] = Field_pos (sample_file, Sym (mer_col_names[x]));
    }

  File_fix (output_file, 1, 0);
}



static void
finalize_files (void)
{
  Close (reference_file);
  Close (output_file);
}




static void
read_samples_building_nfa (void)
{
  while (N_ahead (sample_file))
    {
      size_t new_n_samples = n_samples + N_ahead (sample_file);
      size_t new_nfa_size = new_n_samples * sizeof (struct sample);
      size_t offset = 0;

      nfa = (struct sample *)realloc ((void *)nfa, new_nfa_size);
      if (!nfa)
        Fatal ("out of memory");

      offset = 0;
      while (n_samples < new_n_samples)
        {
          int x;
          for (x = 0; x < n_mer_positions; ++x)
            {
              nfa[n_samples].mer[x] = as_uInt64 (Peek (sample_file, offset, sample_mer_in_col[x]));
              nfa[n_samples].state[0].flags[x] = 0;
              nfa[n_samples].state[1].flags[x] = 0;
            }
          ++n_samples;
          ++offset;
        }
      Advance (sample_file, N_ahead (sample_file));
    }
  Close (sample_file);
}




static void
build_hash_table (void)
{
  const size_t max_snp_variations_per_mer = max_mer_size * 3;
  const size_t max_hash_entries_per_mer = (1 + max_snp_variations_per_mer);
  const size_t max_hash_entries_per_table = n_samples * max_hash_entries_per_mer;
  int x;
  size_t hash_sizeof;

  sample_hash_table_size = round_up_to_power_of_2 (2 * max_hash_entries_per_table);
  if (sample_hash_table_size < 2048)
    sample_hash_table_size += 4096;
  hash_sizeof = sample_hash_table_size * sizeof (struct sample_hash_table);

  for (x = 0; x < n_mer_positions; ++x)
    {
      size_t s;
      size_t list_sizeof;
      size_t list_table_size;

      if (!permit_snps)
        {
          /* In fact, we'll only have one hash entry per sample
           * in each table -- so we only need 'n_samples' bucket
           * entries.
           */
          list_table_size = n_samples;
        }
      else
        {
          /* We'll being hashing each mer but also 3 SNP variations
           * for each base pair position in the mer.  We'll
           * need that many hash bucket entries for each of 
           * n_samples:
           */
          list_table_size = n_samples * (1 + 4 * mer_size[x]);
        }
      
      list_sizeof = list_table_size * sizeof (struct sample_list);

      /* Allocate the hash table and buckets for a given
       * mer position:
       */
      sample_hash_tables[x] = (struct sample_hash_table *)malloc (hash_sizeof);
      sample_list_tables[x] = (struct sample_list *)malloc (list_sizeof);
      if (!sample_hash_tables[x] || !sample_list_tables[x])
        Fatal ("out of memory");
      memset ((void *)sample_hash_tables[x], 0, hash_sizeof);
      memset ((void *)sample_list_tables[x], 0, list_sizeof);

      /* Time to hash the samples:
       */
      for (s = 0; s < n_samples; ++s)
        {
          t_taql_uint64 sample_mer = nfa[s].mer[x];
          
          add_to_hash_table (x, sample_mer, s, -1, 0); /* -1 means "no SNP here" */

          if (permit_snps)
            {
              int y;

              for (y = 0; y < mer_size[x]; ++y)
                {
                  int shift = y * 4;
                  t_taql_uint64 snped_bp;
                  t_taql_uint64 mask;
                  int z;

                  snped_bp = (0xf & (sample_mer >> shift));
                  mask = (0xfULL << shift);

                  for (z = 0; z < 4; ++z)
                    {
                      t_taql_uint64 old_bp = (0xf & (sample_mer >> shift));
                      t_taql_uint64 new_bp = acgt_to_bp[z];

                      if (old_bp != new_bp)
                        {
                          t_taql_uint64 snp_mer = ((sample_mer & ~mask) | (new_bp << shift));
                          add_to_hash_table (x, snp_mer, s, y, (int)new_bp); /* 'y' is the SNP position */
                        }
                    }
                }
            }
        }
    }
}

static size_t
round_up_to_power_of_2 (size_t x)
{
  int q;

  for (q = 1; q < (8 * sizeof (x)); q *= 2)
    {
      x |= (x >> q);
    }

  return x + 1;
}


static void
add_to_hash_table (int mer_pos,
                   t_taql_uint64 mer,
                   size_t sample,
                   int snp_position,
                   int subst_bp)
{
  size_t list_index;
  size_t hash_index;

  /* "Allocate" a new hash bucket entry (a 'struct sample_list'):
   */
  list_index = sample_list_table_n_entries[mer_pos];
  ++sample_list_table_n_entries[mer_pos];

  /* Compute a hash value for this mer from the sample.
   *
   * It's possible that the mer contains some non-base-pair
   * letters (e.g., "CCTNG" contains "N").   In that
   * case, 'hash_mer' will return 0.
   * 
   * We just quietly discard such samples.  In theory, we
   * could treat them each as standing for 2, 3 or 4 
   * samples (depending on the non-bp letter) and, later,
   * permit only exact (not SNP) matches of those variations.
   * That doesn't seem particularly worth the effort at
   * the moment.
   */
#warning "doesn't handle ambiguous base pairs in samples!"
  /* the block "time to hash the samples", above, also needs work
   * if we're to handle ambiguous base pairs in samples.
   */
  if (0 <= find_non_bp (mer, mer_size[mer_pos]))
    return;
  
  hash_index = mer_hash_index (mer, mer_size[mer_pos], sample_hash_table_size);

  sample_list_tables[mer_pos][list_index].sample_id = sample;
  sample_list_tables[mer_pos][list_index].next_hash = sample_hash_tables[mer_pos][hash_index].head;
  /* Reminder:
   * 
   * List indexes in the 'head' field of a hash table entry or the
   * 'next_hash' field of a 'struct sample_list' are incremented
   * by 1, with the value 0 standing for 'nil' (aka end-of-list).
   */
  sample_hash_tables[mer_pos][hash_index].head = 1 + list_index;
  sample_list_tables[mer_pos][list_index].snp_position = (t_taql_int8)snp_position;
  sample_list_tables[mer_pos][list_index].snp_bp = (t_taql_int8)subst_bp;
}




/* For each mer from the reference, reference_candidates 
 * produces a list of needed hash table probes.
 * 
 * If the reference mer contains no ambiguous base
 * pairs, we only need to do one hash probe (which will
 * find all exact matching mers and all SNP'ed matches).
 * 
 * if the reference mer does contain ambiguous base
 * pairs, we probe for each possibility, but these
 * disambiguations count as a SNP and so must exactly
 * match some sample mer.
 */
static void
reference_candidates (struct reference_candidates * ret,
                      t_taql_uint64 mer,
                      size_t mer_size,
                      size_t hash_table_size)
{
  int pos_of_non_bp = find_non_bp (mer, mer_size);

  if (pos_of_non_bp == -1)
    {
      ret->n_variations = 1;
      store_variations (ret, 0, mer, mer_size, -1, hash_table_size);
    }
  else if (pos_of_non_bp >= 0)
    {
      const int shift_amt = (4 * pos_of_non_bp);
      const size_t masked_mer = (mer & ~(((t_taql_uint64)0xfULL) << (4 * pos_of_non_bp)));
      int substitute_bp_in_acgt;

      ret->n_variations = 0;
      for (substitute_bp_in_acgt = 0; substitute_bp_in_acgt < 4; ++substitute_bp_in_acgt)
        {
          const t_taql_uint64 substitute_bp
            = acgt_to_bp[substitute_bp_in_acgt]; 
          const t_taql_uint64 shifted_substitute_bp
            = (((t_taql_uint64)substitute_bp) << shift_amt);

          if (mer & shifted_substitute_bp)
            {
              t_taql_uint64 substitute_mer = masked_mer | shifted_substitute_bp;

              store_variations (ret,
                                substitute_bp_in_acgt,
                                substitute_mer, mer_size,
                                pos_of_non_bp,
                                hash_table_size);
              ++ret->n_variations;
            }
        }
    }
  else
    {
      ret->n_variations = 0;
    }
}


static int
find_non_bp (t_taql_uint64 mer, size_t mer_size)
{
  size_t x;
  int answer = -1;
  t_taql_uint64 m = mer;

  for (x = 0; x < mer_size; ++x)
    {
      if (bp_possibilities_count[(m & 0xf)] != 1)
        {
          if (answer == -1)
            answer = x;
          else
            return -2;
        }
      m >>= 4;
    }
  return answer;
}


static void
store_variations (struct reference_candidates * ret,
                  int pos,
                  t_taql_uint64 mer,
                  size_t mer_size,
                  int snp_position,
                  size_t hash_table_size)
{
  if (match_literal)
    store_variation (ret, pos, 0, mer, mer_size, snp_position, hash_table_size);
  if (match_complement)
    store_variation (ret, pos, 1, complement (mer, mer_size), mer_size, snp_position, hash_table_size);
}


static void
store_variation (struct reference_candidates * ret,
                 int pos,
                 int side,
                 t_taql_uint64 mer,
                 size_t mer_size,
                 int snp_position,
                 size_t hash_table_size)
{
  ret->side[side][pos].probe_mer = mer;
  ret->side[side][pos].hash_index = mer_hash_index (mer, mer_size, hash_table_size);
  ret->side[side][pos].snp_position = snp_position;
}


static t_taql_uint64
complement (t_taql_uint64 mer, size_t mer_size)
{
  return mer_reverse_complement (mer, mer_size);
}


/* Compress a 64-bit, 4 bits per base pair position mer
 * into a 32-bit, 2 bits per base pair position.
 * 
 * This function will abort the program if the
 * mer contains anything other than:
 * 
 *    A == 0   C == 2  G == 4   T == 8
 * 
 */

static size_t 
canonicalize_mer (t_taql_uint64 mer,
                  size_t mer_size)
{
  size_t answer;

  if (!hash_mer (&answer, mer, (int)mer_size))
    {
      Fatal ("ambiguous mer passed to canonicalize_mer");
    }

  return answer;
}


static size_t
mer_hash_index (t_taql_uint64 mer,
                size_t mer_size,
                size_t hash_table_size)
{
  t_taql_uint32 hashable_bits = canonicalize_mer (mer, mer_size);

  /* Remember: hash_table_size is a power of 2.
   */

  if (hash_table_size >= (1 << (mer_size * 2)))
    {
      return hashable_bits & (hash_table_size - 1); 
    }
  else
    {
      /* Thanks to Thomas Wang of the Enterprise Java
       * Lab at HP for publishing the hash function adopted
       * here.   He mentions it is based on a function
       * published by Robert Jenkins.
       * 
       * (I've taken it a bit on faith: I haven't tested
       * it! -- edit this comment if you test the thing.)
       */
      
      t_taql_uint32 mixed_bits = hashable_bits;
      
      mixed_bits = mixed_bits + ~(mixed_bits << 15); /* mixed_bits = mixed_bits - (mixed_bits << 15) - 1; */
      mixed_bits = mixed_bits ^ (mixed_bits >> 10);
      mixed_bits = mixed_bits + (mixed_bits << 3);
      mixed_bits = mixed_bits ^ (mixed_bits >> 6);
      mixed_bits = mixed_bits * 16389; /* mixed_bits = (mixed_bits + (mixed_bits << 2)) + (mixed_bits << 14); */
      mixed_bits = mixed_bits ^ (mixed_bits >> 16);
      
      return mixed_bits & (hash_table_size - 1);
    }
}





static void
scan_reference_running_nfa (void)
{
  size_t pos = 0;               /* position within the reference */

  while (N_ahead (reference_file))
    {
      int x;
      t_taql_uint64 mer;        /* the next mer from the reference */
      size_t this_pos;          /* the reference position for 'mer' */


      /* Consume one mer from the reference.
       */
      mer = as_uInt64 (Peek (reference_file, 0, reference_mer_in_col));
      Advance (reference_file, 1);
      this_pos = pos;
      ++pos;

      /* FIXME
       *
       * Help understand performance characteristics.
       * This is scaffolding code and should be removed.
       * 
       * How long does it take to match our input set
       * against 1M reference bp positions?  See for
       * yourself:
       */
      if (!(this_pos % 1000000))
        {
          fprintf (stderr, ".");
        }

      /* Each input mer from the reference might
       * match one or more sample mers at any of 
       * n_mer_positions positions.
       * 
       * There is one hash table for each mer
       * position:  iterate over those hash tables,
       * seeing if the reference mer matches anything:
       */
      for (x = 0; x < n_mer_positions; ++x)
        {
          struct reference_candidates candidates;
          int v;

          /* Compute the list of hash probes we need to do:
           */
          reference_candidates (&candidates, mer, mer_size[x], sample_hash_table_size);
                                

          for (v = 0; v < candidates.n_variations; ++v)
            {
              if (match_literal)
                do_probe (0, &candidates.side[0][v], x, this_pos);
              if (match_complement)
                do_probe (1, &candidates.side[1][v], x, this_pos);
            }
        }
    }
}


static void
do_probe (int side,
          struct reference_candidate * c,
          int mer_position,
          size_t reference_pos)
{
  const t_taql_uint64 probe_mer = c->probe_mer;
  const size_t hash_index = c->hash_index;
  int reference_snp_position = c->snp_position;
  size_t list_pos;

  list_pos = sample_hash_tables[mer_position][hash_index].head;

  while (list_pos)
    {
      const size_t list_index = list_pos - 1;
      const size_t sample = sample_list_tables[mer_position][list_index].sample_id;
      const size_t next_list_pos = sample_list_tables[mer_position][list_index].next_hash;
      const int sample_snp_position = sample_list_tables[mer_position][list_index].snp_position;
      const t_taql_uint64 sample_subst_bp = sample_list_tables[mer_position][list_index].snp_bp;
      const t_taql_uint64 sample_mer = nfa[sample].mer[mer_position];
      
      if (reference_snp_position >= 0)
        {
          /* reference mer has a SNP in it so the sample mer must not
           * if they are to match.
           */
          if (   (sample_snp_position < 0)
              && mers_match_p (probe_mer, sample_mer, mer_size[mer_position]))
            {
              note_plausible_transition (side, mer_position, reference_pos, probe_mer, reference_snp_position, sample);
            }
        }
      else if (sample_snp_position < 0)
        {
          /* neither mer has a snp it it -- do they match?
           */
          if (mers_match_p (probe_mer, sample_mer, mer_size[mer_position]))
            note_plausible_transition (side, mer_position, reference_pos, probe_mer, -1, sample);
        }
      else
        {
          /* The reference mer (probe_mer) is an unmodified, unambiguous
           * mer from the reference.
           * 
           * The sample mer (sample_mer) is an unmodified, unambiguous
           * mer from the samples.
           * 
           * The catch is that the hash table tells us that we might
           * have a match taking into account a SNP at sample_snp_position
           * and so we have to make the comparison accordingly.
           */

          const t_taql_uint64 mask = ~(0xfULL << (sample_snp_position * 4));
          const t_taql_uint64 masked_sample_mer = ((sample_mer & mask) | (sample_subst_bp << (sample_snp_position * 4)));

          if (mers_match_p (probe_mer, masked_sample_mer, mer_size[mer_position]))
            note_plausible_transition (side,
                                       mer_position, reference_pos,
                                       probe_mer, -1,
                                       sample);


          /* The code above will sometimes report SNP matches redundantly.
           */
        }

      list_pos = next_list_pos;
    }
}

static int
mers_match_p (t_taql_uint64 probe_mer,
              t_taql_uint64 sample_mer,
              size_t mer_size)
{
  size_t compressed_probe_mer;
  size_t compressed_sample_mer;

  if (!hash_mer (&compressed_probe_mer, probe_mer, mer_size))
    return 0;

  if (!hash_mer (&compressed_sample_mer, sample_mer, mer_size))
    return 0;

  return (compressed_probe_mer == compressed_sample_mer);
}


static void
note_plausible_transition (int side,
                           int mer_pos,
                           size_t pos,
                           t_taql_uint64 mer,
                           int snp_pos,
                           size_t sample)
{
  if (mer_pos == 0)
    note_actual_transition (side, mer_pos, pos, mer, snp_pos, sample);
  else
    {
      struct sample * sample_nfa = &nfa[sample];
      t_taql_uint32 prev_state_flags = sample_nfa->state[side].flags[mer_pos - 1];

      if (prev_state_flags)
        {
          size_t prev_state_entered = sample_nfa->state[side].last_entered_pos[mer_pos - 1];
          size_t prev_state_distance = (pos - prev_state_entered);
          /* size_t min_distance = mer_size[mer_pos - 1] + gap_min[mer_pos - 1]; */
          size_t max_distance = mer_size[mer_pos - 1] + gap_max[mer_pos - 1];

          if ((prev_state_distance <= max_distance)
              /* && (min_distance <= prev_state_distance) */)
            {
              note_actual_transition (side, mer_pos, pos, mer, snp_pos, sample);
            }
        }
    }
}


static void
note_actual_transition (int side,
                        int mer_pos,
                        size_t pos,
                        t_taql_uint64 mer,
                        int snp_pos,
                        size_t sample)
{
  nfa[sample].state[side].last_entered_pos[mer_pos] = pos;

  if (snp_pos < 0)
    nfa[sample].state[side].flags[mer_pos] = (1<<16);
  else
    nfa[sample].state[side].flags[mer_pos] = ((1<<16) | (1 << snp_pos));

  if (mer_pos < (n_mer_positions - 1))
    {
      enqueue_transition (side, mer_pos, pos, mer, snp_pos, sample);
    }
  else
    {
      struct output_record outrec = {0, };
      size_t end_pos = pos + mer_size[mer_pos];
      size_t earliest_start = (end_pos < maximum_span ? 0 : (end_pos - maximum_span));
      size_t end_start = (end_pos < span_lower_bound ? 0 : (end_pos - span_lower_bound));

      outrec.sample = sample;

      (void)report_transition  (&outrec,
                                side, pos, sample, 0,
                                (  (side << n_mer_positions)
                                 | ((snp_pos < 0) ? 0 : (1 << mer_pos))),
                                consumed_n_taken_transitions,
                                earliest_start,
                                end_start);
    }
}




static void
enqueue_transition (int side,
                    int mer_pos,
                    size_t pos,
                    t_taql_uint64 mer,
                    t_taql_uint32 flags,
                    size_t sample)
{
  if ((pos + mer_size[n_mer_positions - 1]) > maximum_span)
    {
      while (   (consumed_n_taken_transitions < n_taken_transitions)
             && (  taken_transitions[consumed_n_taken_transitions].pos
                 < (pos + mer_size[n_mer_positions - 1] - maximum_span)))
        {
          ++consumed_n_taken_transitions;
        }
    }

  if (n_taken_transitions == size_taken_transitions)
    {
      if (consumed_n_taken_transitions)
        {
          memmove ((void *)taken_transitions,
                   (void *)&taken_transitions[consumed_n_taken_transitions],
                   sizeof (struct taken_transition) * (size_taken_transitions - consumed_n_taken_transitions));
          n_taken_transitions -= consumed_n_taken_transitions;
          consumed_n_taken_transitions = 0;
        }
      else
        {
          size_taken_transitions = (!size_taken_transitions
                                    ? 1024
                                    : (2 * size_taken_transitions));
          taken_transitions = ((struct taken_transition *)
                               realloc ((void *)taken_transitions,
                                        sizeof (struct taken_transition) * size_taken_transitions));
          if (!taken_transitions)
            Fatal ("out of memory");
        }
    }

  taken_transitions[n_taken_transitions].side = side;
  taken_transitions[n_taken_transitions].mer_pos = mer_pos;
  taken_transitions[n_taken_transitions].pos = pos;
  taken_transitions[n_taken_transitions].mer = mer;
  taken_transitions[n_taken_transitions].match_flags = flags;
  taken_transitions[n_taken_transitions].sample = sample;
  ++n_taken_transitions;
}


static int
report_transition (struct output_record * outrec,
                   int side,
                   size_t pos,
                   size_t sample,
                   int mer_pos,
                   t_taql_uint32 flags,
                   size_t qpos,
                   size_t earliest_start_bp_pos,
                   size_t end_start_bp_pos)
{
  int did_any = 0;

 tail_recursive_call:
  
  if (mer_pos == (n_mer_positions - 1))
    {
      if (pos < earliest_start_bp_pos || pos >= end_start_bp_pos)
	{
	  return 0;
	}
      int x;

      outrec->positions[mer_pos] = pos;

      Poke (output_file, 0, sample_out_col, uInt32 (sample));
      Poke (output_file, 0, flags_out_col, uInt32 (flags));

      for (x = 0; x < n_mer_positions; ++x)
        {
          Poke (output_file, 0, pos_out_col[x], uInt32 (outrec->positions[x]));
        }

      Advance (output_file, 1);
      return 1;
    }
  else
    {
      if (   (taken_transitions[qpos].sample == sample)
          && (taken_transitions[qpos].mer_pos == mer_pos)
          && (taken_transitions[qpos].pos >= earliest_start_bp_pos)
          && (taken_transitions[qpos].pos < end_start_bp_pos))
        {
          size_t gap_starts = taken_transitions[qpos].pos + mer_size[mer_pos];
          size_t earliest_next_start = gap_starts + gap_min[mer_pos];
          size_t end_next_start = gap_starts + gap_max[mer_pos] + 1;
          struct output_record recursive_outrec = *outrec;

          recursive_outrec.flags |= flags;
          recursive_outrec.positions[mer_pos] = taken_transitions[qpos].pos;

          did_any |= report_transition (&recursive_outrec, side, pos, sample,
                                        mer_pos + 1,
                                        flags | taken_transitions[qpos].match_flags,
                                        qpos + 1,
                                        earliest_next_start,
                                        end_next_start);
          if (did_any && !show_all)
            return 1;
        }

      qpos += 1;
      if (qpos < n_taken_transitions)
        goto tail_recursive_call;

      return did_any;
    }
}




/* arch-tag: Thomas Lord Tue Nov 21 10:22:45 2006 (mer-nfa/mer-nfa.c)
 */
