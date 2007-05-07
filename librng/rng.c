/* rng.c: 
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


#include <stdlib.h>
#include "librng/rng.h"


/* __STDC__ prototypes for static functions */
static unsigned int rng__u16_in (unsigned int range,
                                 unsigned int mask);




#if defined(RNG_USE_NATIVE_RANDOM)

void
rng_init (char * randoms_file, unsigned int seed)
{
  srandom (seed);
}

unsigned long
rng__bit (void)
{
  return random () & 1;
}


unsigned long
rng__byte (void)
{
  return (unsigned long)random () & 0xff;
}


unsigned long
rng__u16 (void)
{
  return ((unsigned long)random () & 0xffff);
}


unsigned long
rng__u32 (void)
{
  return ((unsigned long)random () << 8) | rng__byte ();
}


unsigned long long
rng__u64 (void)
{
  return (  ((unsigned long long)rng__u32 () << 32)
          | (unsigned long long)rng__u32 ());
}



#else

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/fcntl.h>
#include <unistd.h>
#include <string.h>
#include "libcmd/panic.h"
#include "librng/rng.h"


unsigned char * rng__bytes = 0;
size_t rng__head_0 = 0;
size_t rng__head_1 = 0;
size_t rng__head_limit = 0;


void
rng_init (char * randoms_file, unsigned int seed)
{
  struct stat buf;
  int fd;

  if (rng__bytes)
    return;

  srandom (seed);

  if (!randoms_file)
    {
      randoms_file = getenv ("RNG_RANDOMS_FILE");
      if (!randoms_file)
        {
          randoms_file = CFG_PREFIX "/lib/librng/160megs";
        }
    }

  fd = open (randoms_file, O_RDONLY, 0);
  if (fd < 0)
    panic ("unable to open random data source");

  if (fstat (fd, &buf))
    panic ("unable to stat random data source");

  rng__bytes = (unsigned char *)mmap (0,
                                      (size_t)buf.st_size,
                                      PROT_READ,
                                      MAP_SHARED,
                                      fd,
                                      0);
  if (!rng__bytes)
    panic ("unable to mmap random data source");

  if (close (fd))
    panic ("unable to close random data source");

  rng__head_limit = (size_t)buf.st_size;

  do
    {
      rng__head_0 = (random() % rng__head_limit);
      rng__head_1 = (random() % rng__head_limit);
    }
  while (rng__head_0 == rng__head_1);
}


void
rng__reset_for_u64 (void)
{
  do
    {
      rng__head_0 = (random() % rng__head_limit);
      rng__head_1 = (random() % rng__head_limit);
    }
  while (rng__head_0 == rng__head_1);
}


unsigned int
rng__slow_byte (void)
{
  if (rng__head_0 == rng__head_limit)
    {
      do
        {
          rng__head_0 = (random() % rng__head_limit);
        }
      while (rng__head_0 == rng__head_1);
    }
  else
    {
      do
        {
          rng__head_1 = (random() % rng__head_limit);
        }
      while (rng__head_0 == rng__head_1);
    }

  return rng_byte ();
}

#endif

static inline unsigned long long
rng__u64_in (unsigned long long range,
            unsigned long long mask)
{
  while (1)
    {
      unsigned long long x = rng_u64 ();

      x &= mask;

      if (x < range)
        return x;
    }
}


unsigned long long
rng_u64_in (unsigned long long range)
{
  unsigned long long mask;

  mask = range;
  mask = (mask | (mask >> 1));
  mask = (mask | (mask >> 2));
  mask = (mask | (mask >> 4));
  mask = (mask | (mask >> 8));
  mask = (mask | (mask >> 16));
  mask = (mask | (mask >> 32));

  return rng__u64_in (range, mask);
}


unsigned long long
rng_u64_normal_in (unsigned long long range)
{
  unsigned long long mask;
  unsigned long long sum;
  unsigned long long approx;
  unsigned long long remainder;
  unsigned long long answer;
  int x;

  mask = range;
  mask = (mask | (mask >> 1));
  mask = (mask | (mask >> 2));
  mask = (mask | (mask >> 4));
  mask = (mask | (mask >> 8));
  mask = (mask | (mask >> 16));
  mask = (mask | (mask >> 32));

#define RNG_N_NORMAL_TRIALS (256)

  sum = 0;
  for (x = 0; x < RNG_N_NORMAL_TRIALS; ++x)
    {
      sum += rng__u64_in (range, mask);
    }

  approx = (sum / RNG_N_NORMAL_TRIALS);

  remainder = (sum - (approx * RNG_N_NORMAL_TRIALS));

  if (rng_bit ())
    {
      if (remainder > (sum / 2))
        answer = approx + 1;
      else
        answer = approx;
    }
  else
    {
      if (remainder >= (sum / 2))
        answer = approx + 1;
      else
        answer = approx;
    }

  return answer;
}



static unsigned int
rng__u16_in (unsigned int range,
             unsigned int mask)
{
  while (1)
    {
      unsigned int x = rng_u16 ();

      x &= mask;

      if (x < range)
        return x;
    }
}


unsigned int
rng_u16_in (unsigned int range)
{
  unsigned int mask;

  mask = range;
  mask = (mask | (mask >> 1));
  mask = (mask | (mask >> 2));
  mask = (mask | (mask >> 4));
  mask = (mask | (mask >> 8));

  return rng__u16_in (range, mask);
}


unsigned int
rng_u16_normal_in (unsigned int range)
{
  unsigned int mask;
  unsigned int sum;
  unsigned int approx;
  unsigned int remainder;
  unsigned int answer;
  int x;

  mask = range;
  mask = (mask | (mask >> 1));
  mask = (mask | (mask >> 2));
  mask = (mask | (mask >> 4));
  mask = (mask | (mask >> 8));


  sum = 0;
  for (x = 0; x < RNG_N_NORMAL_TRIALS; ++x)
    {
      sum += rng__u16_in (range, mask);
    }

  approx = (sum / RNG_N_NORMAL_TRIALS);

  remainder = (sum - (approx * RNG_N_NORMAL_TRIALS));

  if (rng_bit ())
    {
      if (remainder > (sum / 2))
        answer = approx + 1;
      else
        answer = approx;
    }
  else
    {
      if (remainder >= (sum / 2))
        answer = approx + 1;
      else
        answer = approx;
    }

  return answer;
}



t_rng_deal
rng_begin_card_picks (long long deck_size,
                      long long deal_size)
{
  t_rng_deal deal;

  deal = (t_rng_deal)malloc (sizeof (*deal));

  deal->buffered = 0;
  deal->sp = 0;
  deal->stack[0].from = 0;
  deal->stack[0].to = deck_size * RNG_DEAL_RESOLUTION;
  deal->stack[0].to_deal = deal_size;
  return deal;
}


void
rng_reset_card_picks (t_rng_deal deal,
                      long long deck_size,
                      long long deal_size)
{
  deal->buffered = 0;
  deal->sp = 0;
  deal->stack[0].from = 0;
  deal->stack[0].to = deck_size * RNG_DEAL_RESOLUTION;
  deal->stack[0].to_deal = deal_size;
}


#define rng_deal_tos_to_deal(D) \
  ((D)->stack[(D)->sp].to_deal)

#define rng_deal_pop(D) \
  (((D)->sp)--)

#define rng_deal_push(D) \
  (++((D)->sp))

#define rng_deal_dec_tos_to_deal(D) \
  (((D)->stack[(D)->sp].to_deal)--)

#define rng_deal_clear_tos_to_deal(D) \
  (((D)->stack[(D)->sp].to_deal) = 0)

#define rng_deal_set_tos_to_deal(D, V) \
  (((D)->stack[(D)->sp].to_deal) = (V))

#define rng_deal_tos_from(D) \
  ((D)->stack[(D)->sp].from)

#define rng_deal_set_tos_from(D, V) \
  (((D)->stack[(D)->sp].from) = (V))

#define rng_deal_tos_to(D) \
  ((D)->stack[(D)->sp].to)

#define rng_deal_set_tos_to(D, V) \
  (((D)->stack[(D)->sp].to) = (V))

#define rng_deal_index_to_card(C) \
  ( (C) / RNG_DEAL_RESOLUTION )

#define rng_deal_tos_from_card(D) \
  rng_deal_index_to_card (rng_deal_tos_from (D))

#define rng_deal_tos_to_card(D) \
  rng_deal_index_to_card (rng_deal_tos_to (D))

#define rng_deal_n_buffered(D) \
  ((D)->buffered)

#define rng_deal_buffer(D, V) \
  ((D)->buffer[ RNG_BUFFER_SIZE - ++((D)->buffered) ] = (V))

#define rng_deal_from_buffer(D) \
  ((D)->buffer[ RNG_BUFFER_SIZE - (((D)->buffered)--) ])


static int
cmp_ull (const void * ap, const void * bp)
{
  unsigned long long a = *(unsigned long long *)ap;
  unsigned long long b = *(unsigned long long *)bp;

  if (a < b)
    return -1;
  else if (b < a)
    return 1;
  else
    return 0;
}


   
long long
rng_next_card_pick (t_rng_deal deal)
{
 tail_call:

  if (rng_deal_n_buffered (deal))
    {
      return rng_deal_from_buffer (deal);
    }

  while (rng_deal_tos_to_deal (deal) == 0)
    {
      if (!rng_deal_pop (deal))
        return -1;
    }

  if (rng_deal_tos_to_deal (deal) == 1)
    {
      long long from;
      long long to;
      long long range;
      long long rnd;
      long long answer;


      from = rng_deal_tos_from (deal);
      to = rng_deal_tos_to (deal);
      range = to - from;
      rnd = rng_u64_in (range);
      answer = ((from + rnd) / RNG_DEAL_RESOLUTION);

      rng_deal_dec_tos_to_deal (deal);

      return answer;
    }
  else if (   rng_deal_tos_from_card (deal)
           == (rng_deal_index_to_card (rng_deal_tos_to (deal) - 1)))
    {
      rng_deal_dec_tos_to_deal (deal);
      return rng_deal_tos_from_card (deal);
    }
  else if (rng_deal_tos_to_deal (deal) < RNG_BUFFER_SIZE)
    {
      long long n_needed;
      long long from;
      long long to;
      long long range;
      int x;

      n_needed = rng_deal_tos_to_deal (deal);
      from = rng_deal_tos_from (deal);
      to = rng_deal_tos_to (deal);
      range = to - from;

      for (x = 0; x < n_needed; ++x)
        {
          long long rnd;

          rnd = rng_u64_in (range);
          
          rng_deal_buffer (deal, (from + rnd) / RNG_DEAL_RESOLUTION);
        }

      qsort ((void *)(deal->buffer + (RNG_BUFFER_SIZE - deal->buffered)),
             deal->buffered,
             sizeof (unsigned long long),
             cmp_ull);
      rng_deal_clear_tos_to_deal (deal);
      return rng_deal_from_buffer (deal);
    }
  else
    {
      long long to_deal;
      long long left_to_deal;
      long long right_to_deal;
      long long from;
      long long to;
      long long median;

      to_deal = rng_deal_tos_to_deal (deal);
      
      if ((to_deal & 1) && rng_bit ())
        left_to_deal = (to_deal + 1) / 2;
      else
        left_to_deal = (to_deal / 2);

      right_to_deal = (to_deal - left_to_deal);


      from = rng_deal_tos_from (deal);
      to = rng_deal_tos_to (deal);

      if ((to - from) == 2)
        {
          median = from + 1;
        }
      else if ((to - from) >= RNG_DEAL_RESOLUTION)
        {
          median = from + 1 + (long long)rng_u64_normal_in (to - from - 2);
        }
      else
        {
          long long inflated_range;
          long long inflated_rnd;
          long long unbiased_inflated_rnd;
          long long rnd;

          inflated_range = (to - from - 2) * RNG_DEAL_RESOLUTION;
          inflated_rnd = (long long)rng_u64_normal_in (inflated_range);
          unbiased_inflated_rnd = inflated_rnd + (RNG_DEAL_RESOLUTION / 2);
          rnd = (unbiased_inflated_rnd / RNG_DEAL_RESOLUTION);
          median = from + 1 + rnd;
        }

      rng_deal_set_tos_from (deal, median);
      rng_deal_set_tos_to_deal (deal, right_to_deal);
      rng_deal_push (deal);
      rng_deal_set_tos_from (deal, from);
      rng_deal_set_tos_to (deal, median);
      rng_deal_set_tos_to_deal (deal, left_to_deal);
      
      goto tail_call;
    }
}

void
rng_finish_deal (t_rng_deal deal)
{
  free ((void *)deal);
}




/* arch-tag: Thomas Lord Sat Aug 19 13:54:12 2006 (librndutils/rng.c)
 */

