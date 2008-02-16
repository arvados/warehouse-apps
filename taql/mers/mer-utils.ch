/* mer-utils.ch: 
 *
 ****************************************************************
 * Copyright (C) 2006 Harvard University
 * Authors: Thomas Lord, Tom Clegg
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


enum base_pair
{
  bp_undefined = 0,
  bp_A = 1,
  bp_C = 2,
  bp_M = 3,
  bp_G = 4,
  bp_R = 5,
  bp_S = 6,
  bp_V = 7,
  bp_T = 8,
  bp_W = 9,
  bp_Y = 10,
  bp_H = 11,
  bp_K = 12,
  bp_D = 13,
  bp_B = 14,
  bp_N = 15,
};

#define bp_complement(BP) \
  ((BP) == bp_undefined \
   ? bp_undefined \
   : (  (((BP) & bp_A) ? bp_T : 0) \
      | (((BP) & bp_C) ? bp_G : 0) \
      | (((BP) & bp_G) ? bp_C : 0) \
      | (((BP) & bp_T) ? bp_A : 0)))

static int bp_complements[16] = 
{
  bp_complement (0), bp_complement (1), bp_complement (2), bp_complement (3), 
  bp_complement (4), bp_complement (5), bp_complement (6), bp_complement (7), 
  bp_complement (8), bp_complement (9), bp_complement (10), bp_complement (11), 
  bp_complement (12), bp_complement (13), bp_complement (14), bp_complement (15)
};


static int bp_possibilities_count[16] = { 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4 };

static int bp_in_2bits[16] = { -1, 0, 1, -1, 2, -1, -1, -1, 3, -1, -1, -1, -1, -1, -1, -1 };

static int acgt_to_bp[4] = { 1, 2, 4, 8 };


static inline t_taql_uint64 
ascii_to_bp (char c)
{
  switch (c)
    {
    default: 
      {
        Fatal ("illegal base pair character");
        return 0;               /* not reached */
      }
    case 'A': case 'a': return 1;
    case 'C': case 'c': return 2;
    case 'M': case 'm': return 3;
    case 'G': case 'g': return 4;
    case 'R': case 'r': return 5;
    case 'S': case 's': return 6;
    case 'V': case 'v': return 7;
    case 'T': case 't': return 8;
    case 'W': case 'w': return 9;
    case 'Y': case 'y': return 10;
    case 'H': case 'h': return 11;
    case 'K': case 'k': return 12;
    case 'D': case 'd': return 13;
    case 'B': case 'b': return 14;
    case 'N': case 'n': return 15;
    }
}



t_taql_uint64
ascii_to_mer (const char * str)
{
  t_taql_uint64 mer;
  int pos;
  const char * p;

  if (!strcmp(str,".")) return 0;
  
  mer = 0;
  pos = 0;

  for (p = str; *p; ++p)
    {
      t_taql_uint64 bp = ascii_to_bp (*p);
      if (pos >= 64)
        Fatal ("mer too long");
      mer |= (bp << pos);
      pos += 4;
    }
  return mer;
}


/* mer_to_ascii 
 * 
 * outbuf must be at least 17 characters large -- 
 * enough for up-to 16 bp followed by a terminating NUL.
 */
void
mer_to_ascii (char * outbuf, t_taql_uint64 mer)
{
  int x;

  for (x = 0; x < 16; ++x)
    {
      static const char * names = "?ACMGRSVTWYHKDBN";
      int digit = (0xf & (mer >> (x * 4)));
      char it = names[digit];

      if (!digit)
        break;
      else
        outbuf[x] = it;
    }
  if (!x)
    {
      outbuf[x++] = '.';
    }
  outbuf[x] = 0;
}


int
hash_mer (size_t * hash_value,
          t_taql_uint64 mer0,
          int n_mers)
{
  size_t answer;
  int x;

  /* This hash function succeeds and computes a hash
   * value only for mers that contain no ambiguous 
   * base pairs (otherwise, it indicates failure by
   * returning 0).
   * 
   * The function *assumes* that (2 * sizeof(size_t)) <= sizeof (t_taql_uint64)
   * 
   * The hash value computed (for values where it succeeds)
   * is a perfect, dense hash formed by compressing base pairs to
   * two bits:
   * 
   *      example:	encoded:		hashed:
   *
   *      A C G T	16# 8 4 2 1		2#11 10 01 00
   * 
   */

  answer = 0;
  for (x = 0; x < n_mers; ++x)
    {
      unsigned int bp = (0xf & (mer0 >> (x * 4)));
      int bits_for_hash = bp_in_2bits[bp];

      if (bits_for_hash < 0)
        return 0;

      answer |= (bits_for_hash << (x * 2));
    }

  *hash_value = answer;
  return 1;
}

int
hash_mer_2 (size_t * hash_value,
            t_taql_uint64 mer0,
            t_taql_uint64 mer1,
            int n_mers)
{
  size_t a0;
  size_t a1;


  /* This hash function succeeds and computes a hash
   * value only for *pairs* of mers that contain no ambiguous 
   * base pairs (otherwise, it indicates failure by
   * returning 0).
   * 
   * The function *assumes* that (2 * sizeof(size_t)) <= sizeof (t_taql_uint64)
   * 
   * The hash value computed (for values where it succeeds)
   * is a lossy, dense hash formed by combining values from
   * hash_mer.
   * 
   * NOTE: The *quality* of this hash function has not been investigated.
   */

  if (   !hash_mer (&a0, mer0, n_mers)
      || !hash_mer (&a1, mer1, n_mers))
    {
      return 0;
    }
  else
    {
      *hash_value = (a0
                     ^ (  ((a1 & 0xaaaaaaaa) >> 1)
                        | ((a1 & 0x55555555) << 1)));
    }

  return 1;
}


int
mers_eqv (t_taql_uint64 a, t_taql_uint64 b, int n_mers)
{
  t_taql_uint64 mask = ((1ULL << (n_mers * 4)) - 1);

  /* For uses in existing code, this function could be just
   * "a == b" -- it is vestigial from a time when another
   * bp encoding was used.
   * 
   * For the sake of future code, this function still does
   * something useful:  it compares only the first n_mers
   * base pairs of the two mers.
   */

  a &= mask;
  b &= mask;

  return a == b;
}

static t_taql_uint64
mer_reverse_complement (t_taql_uint64 mer, size_t mer_size)
{
  size_t x;
  t_taql_uint64 ret = 0xffffffffffffffffULL;

  /* How handy:
   * 
   *  at  00 11
   *  cg  01 10
   *  gc  10 01
   *  ta  11 00
   */
  
  for (x = 0; x < mer_size; ++x)
    {
      if (mer & 0x8ULL)
	{
	  ret = (ret << 4) | (mer & 0xfULL);
	}
      else
	{
	  ret = (ret << 4) | ((mer & 0xfULL) ^ 0x3ULL);
	}
      mer = mer >> 4;
    }

  return ret;
}


t_taql_uint64
reverse_complement_mer (t_taql_uint64 mer_in)
{
  size_t x;
  t_taql_uint64 mer_out = 0;

  for (x = 0; (x < 16) && (mer_in & 0xf); ++x)
    {
      mer_out = (mer_out << 4) | bp_complements [mer_in & 0xf];
      mer_in = mer_in >> 4;
    }
  return mer_out;
}



/* arch-tag: Thomas Lord Mon Nov  6 15:39:22 2006 (mers/mer-utils.ch)
 */

