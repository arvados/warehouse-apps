/* config.h:
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

#ifndef INCLUDE__LIBTAQL__CONFIG_H
#define INCLUDE__LIBTAQL__CONFIG_H


typedef char t_taql_int8;
typedef unsigned char t_taql_uint8;
typedef int t_taql_int32;
typedef unsigned int t_taql_uint32;
typedef long long t_taql_int64;
typedef unsigned long long t_taql_uint64;
typedef float t_taql_sfloat;
typedef double t_taql_dfloat;



struct taql__sym
{
  char _str[8];
};
typedef struct taql__sym t_taql_sym;

typedef int t_taql_infile;
typedef int t_taql_outfile;


#define taql__neg_op(X) (-(X))
#define taql__inc_op(X) (1 + (X))
#define taql__dec_op(X) ((X) - 1)
#define taql__lnot_op(X) (!(X))
#define taql__bnot_op(X) (~(X))



#endif  /* INCLUDE__LIBTAQL__CONFIG_H */

/* arch-tag: Thomas Lord Fri Oct 27 16:43:49 2006 (libtaql/config.h)
 */

