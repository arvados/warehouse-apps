/* rng-partition.c: 
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


#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "librng/rng.h"
#include "libcmd/panic.h"
#include "libcmd/must-malloc.h"


int
main (int argc, char * argv[])
{
  long long n_cards;
  long long n_samples;
  t_rng_deal deal;

  rng_init (0, 0);

  if (argc != 3)
    panic ("usage: rng-partition N_CARDS N_SAMPLES");

  n_cards = atoll(argv[1]);
  n_samples = atoll(argv[2]);

  deal = rng_begin_card_picks (n_cards, n_samples);

  while (1)
    {
      long long x;

      x = rng_next_card_pick (deal);

      if (x < 0)
        break;

      printf ("%lld\n", x);
    }

  return 0;
}



/* arch-tag: Thomas Lord Sat Aug 19 21:31:03 2006 (rng-tools/rng-partition.c)
 */
