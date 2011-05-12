/* rng-gen.c: 
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


#include <stdio.h>
#include <stdlib.h>
#include "libcmd/opts.h"
#include "librng/rng.h"


int
main (int argc, const char * argv[])
{
  const char * normal_irange_spec = 0;
  const char * irange_spec = 0;
  unsigned long long irange;
  struct opts opts[] = 
    {
      { OPTS_ARG, "-r", "--range", 0, &irange_spec },
      { OPTS_ARG, "-n", "--normal-range", 0, &normal_irange_spec },
      { OPTS_END, 0, }
    };

  opts_parse (&argc, opts, argc, argv, "rng-gen [options]");

  if (irange_spec)
    {
      irange = (unsigned long long) atoll (irange_spec);
    }

  if (normal_irange_spec)
    {
      irange = (unsigned long long) atoll (normal_irange_spec);
    }


  rng_init (0, 0);


  while (1)
    {
      if (normal_irange_spec)
        {
          {
            if (irange < (1 << 16))
              {
                unsigned int x;
                
                x = rng_u16_normal_in (irange);
                printf ("%d\n",  x);
              }
            else
              {
                unsigned long long x;
                
                x = rng_u64_normal_in (irange);
                printf ("%llu\n",  x);
              }
          }
        }
      else if (irange_spec)
        {
          unsigned long long x;

          x = rng_u64_in (irange);
          printf ("%llu\n",  x);
        }
      else
        {
          unsigned long long x;

          x = rng_u64 ();
          printf ("%llu\n",  x);
        }
    }
}



/* arch-tag: Thomas Lord Sat Aug 19 15:05:51 2006 (rng-tools/rng.c)
 */
