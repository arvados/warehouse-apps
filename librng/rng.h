/* rng.h:
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

#ifndef INCLUDE__LIBRNG__RANDOMS_H
#define INCLUDE__LIBRNG__RANDOMS_H


#if defined(RNG_USE_NATIVE_RANDOM)

#define rng_bit rng__bit
#define rng_byte rng__byte
#define rng_u16 rng__u16
#define rng_u32 rng__u32
#define rng_u64 rng__u64


#else

#include <sys/types.h>

extern unsigned char * rng__bytes;
extern size_t rng__head_0;
extern size_t rng__head_1;
extern size_t rng__head_limit;


#define rng_byte() ((unsigned long) \
                    (   (   (rng__head_0 == rng__head_limit) \
                        || (rng__head_1 == rng__head_limit)) \
                    ? rng__slow_byte () \
                    : (rng__bytes[rng__head_0++] ^ rng__bytes[rng__head_1++])))


#define rng_u16() (  (rng_byte() << 8) \
                   | rng_byte())

#define rng_u32() (  (rng_byte() << 24) \
                   | (rng_byte() << 16) \
                   | (rng_byte() << 8) \
                   | rng_byte())



extern void rng__reset_for_u64 (void);

static inline unsigned long long
rng_u64 (void)
{
  unsigned long long answer;

  while (   ((rng__head_0 + 16) >= rng__head_limit)
         || ((rng__head_1 + 16) >= rng__head_limit))
    rng__reset_for_u64 ();

  rng__head_0 = ((rng__head_0 + 8) & ~0x7LL);
  rng__head_1 = ((rng__head_1 + 8) & ~0x7LL);

  answer =  (  *(unsigned long long *)(rng__bytes + rng__head_0)
             ^ *(unsigned long long *)(rng__bytes + rng__head_1));
  rng__head_0 += 8;
  rng__head_1 += 8;
  return answer;
}

#if 0
#define rng_u64() (  ((unsigned long long)rng_byte() << 56) \
                   | ((unsigned long long)rng_byte() << 48) \
                   | ((unsigned long long)rng_byte() << 40) \
                   | ((unsigned long long)rng_byte() << 32) \
                   | ((unsigned long long)rng_byte() << 24) \
                   | ((unsigned long long)rng_byte() << 16) \
                   | ((unsigned long long)rng_byte() << 8) \
                   | (unsigned long long)rng_byte())
#endif

#define rng_bit() (rng_byte() & 1)


#endif



#define RNG_DEAL_STACKSIZE              (256)
#define RNG_DEAL_RESOLUTION_POW2        (17)
#define RNG_DEAL_RESOLUTION             (1 << RNG_DEAL_RESOLUTION_POW2)
#define RNG_BUFFER_SIZE			(256)

struct rng_deal
{
  int buffered;
  long long buffer[RNG_BUFFER_SIZE];

  struct rng_deal_subproblem
    {
      long long from;
      long long to;
      long long to_deal;
    } stack[RNG_DEAL_STACKSIZE];

  int sp;
};
typedef struct rng_deal * t_rng_deal;



/* automatically generated __STDC__ prototypes */
extern void rng_init (char * randoms_file, unsigned int seed);
extern unsigned long rng__bit (void);
extern unsigned long rng__byte (void);
extern unsigned long rng__u16 (void);
extern unsigned long rng__u32 (void);
extern unsigned long long rng__u64 (void);
extern void rng_init (char * randoms_file, unsigned int seed);
extern void rng__reset_for_u64 (void);
extern unsigned int rng__slow_byte (void);
extern unsigned long long rng_u64_in (unsigned long long range);
extern unsigned long long rng_u64_normal_in (unsigned long long range);
extern unsigned int rng_u16_in (unsigned int range);
extern unsigned int rng_u16_normal_in (unsigned int range);
extern t_rng_deal rng_begin_card_picks (long long deck_size,
                                        long long deal_size);
extern void rng_reset_card_picks (t_rng_deal deal,
                                  long long deck_size,
                                  long long deal_size);
extern long long rng_next_card_pick (t_rng_deal deal);
extern void rng_finish_deal (t_rng_deal deal);
#endif  /* INCLUDE__LIBRNG__RANDOMS_H */

/* arch-tag: Thomas Lord Sat Aug 19 13:55:07 2006 (librndutils/rng.h)
 */

