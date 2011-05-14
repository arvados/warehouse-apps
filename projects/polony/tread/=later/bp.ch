/* bp.ch: 
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


static inline int
bp_letter_to_int4 (int c)
{
  switch (c & 0x7f)
    {
    case 'A': return 0;
    case 'C': return 1;
    case 'G': return 2;
    case 'T': return 3;
    case 'a': return 4;
    case 'c': return 5;
    case 'g': return 6;
    case 't': return 7;
    case 'n': return 8;
    case 'N': return 9;
    case 0: return 15;
    default: Fatal ("bogus base pair"); return 0;
    }
}


static inline int
bp_int4_to_letter (int bp)
{
  switch (bp)
    {
    case 0: return 'A';
    case 1: return 'C';
    case 2: return 'G';
    case 3: return 'T';
    case 4: return 'a';
    case 5: return 'c';
    case 6: return 'g';
    case 7: return 't';
    case 8: return 'n';
    case 9: return 'N';
    case 15: return 0;
    default: Fatal ("bogus base pair"); return 0;
    }
}


/* arch-tag: Thomas Lord Mon Oct 30 16:35:36 2006 (taql/bp.ch)
 */

