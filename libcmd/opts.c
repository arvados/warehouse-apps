/* opts.c: 
 *
 ****************************************************************
 * Copyright (C) 2006 Harvard University
 * Authors: Thomas Lord
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
#include <string.h>
#include "libcmd/must-malloc.h"
#include "libcmd/panic.h"
#include "libcmd/opts.h"



void
opts_parse (int * argx_r,
            struct opts * opts,
            int argc,
            const char * argv[],
            char * usage_string)
{
  int argx = 0;

  if (argc >= 0)
    {
      panic_set_errname (argv[0]);
      argx = 1;
    }
  else
    {
      panic_set_errname (0);    /* doesn't normally return */
      exit (2);
      return;
    }

  while ((argx < argc) && (argv[argx][0] == '-'))
    {
      int o;
      int matched;

      matched = 0;

      for (o = 0; opts[o].opt_type != OPTS_END; ++o)
        {
          if (   (   opts[o].short_name
                  && !strcmp (argv[argx], opts[o].short_name))
              || (   opts[o].long_name
                  && !strcmp (argv[argx], opts[o].long_name)))
            {
              matched = 1;
              switch (opts[o].opt_type)
                {
                case OPTS_FLAG:
                  {
                    *opts[o].flag_slot = 1;
                    ++argx;
                    break;
                  }
                case OPTS_ARG:
                  {
                    if ((argx + 1) == argc)
                      goto usage;
                    *opts[o].arg_slot = argv[argx + 1];
                    argx += 2;
                    break;
                  }
                default:
                  {
                    panic ("internal error parsing arguments");
                    exit (2);
                    break;
                  }
                }
              break;
            }
        }

      if (!matched)
        {
          if (!strcmp (argv[argx], "--"))
            break;
          else 
            {
            usage:
              panic (usage_string);
              exit (2);
              return;
            }
        }
    }

  *argx_r = argx;
}





/* arch-tag: Tom Lord Thu Jun 23 10:18:14 2005 (opts.c)
 */
