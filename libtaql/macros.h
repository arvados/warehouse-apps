/* macros.h:
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

#ifndef INCLUDE__LIBTAQL__MACROS_H
#define INCLUDE__LIBTAQL__MACROS_H


#define Taql t_taql_boxed

#define Sym(STR) \
  taql_box_sym (taql__sym (__FILE__, __LINE__, STR))

#define Int4(V) \
  taql_box_int4 ((t_taql_int32)(V))

#define uInt4(V) \
  taql_box_uint4 ((t_taql_uint32)(V))

#define Int8(V) \
  taql_box_int8 ((t_taql_int32)(V))

#define uInt8(V) \
  taql_box_uint8 ((t_taql_uint32)(V))

#define Int32(V) \
  taql_box_int32 ((t_taql_int32)(V))

#define uInt32(V) \
  taql_box_uint32 ((t_taql_uint32)(V))

#define uInt64(V) \
  taql_box_uint64 ((t_taql_int64)(V))

#define Sfloat(V) \
  taql_box_sfloat ((t_taql_sfloat)(V))

#define Outfile(NAME) \
  taql__open_outfile (__FILE__, __LINE__, NAME)

#define Infile(NAME) \
  taql__open_infile (__FILE__, __LINE__, NAME)

#define Add_field(STR, TYPE, NAME) \
  taql__file_add_field (__FILE__, __LINE__, \
                        STR, \
                        taql__unbox_to_type_tag (__FILE__, __LINE__, TYPE), \
                        taql__unbox_sym (__FILE__, __LINE__, NAME))

#define Add_param(STR, NAME, VALUE) \
  taql__file_add_param (__FILE__, __LINE__, \
                        STR, \
                        taql__unbox_sym (__FILE__, __LINE__, NAME), \
                        VALUE)

#define Set_comment(STR, CMNT) \
  taql__file_set_comment (__FILE__, __LINE__, STR, CMNT)

#define File_fix(STR, N_AHEAD, BUFSIZ) \
  taql__file_fix_headers (__FILE__, __LINE__, STR, N_AHEAD, BUFSIZ)

#define Poke(STR, ROW, COL, VAL) \
  taql__file_poke (__FILE__, __LINE__, STR, ROW, COL, \
                   taql__cast_to (__FILE__, __LINE__, VAL, \
                                  taql__file_field_type (__FILE__, __LINE__, STR, COL)))

#define Peek(STR, ROW, COL) \
  taql__file_peek (__FILE__, __LINE__, STR, ROW, COL)

#define Advance(STR, N_ROWS) \
  taql__file_advance_cursor (__FILE__, __LINE__, STR, N_ROWS)

#define Close(STR) \
  taql__file_close (__FILE__, __LINE__, STR)

#define N_ahead(STR) \
  taql__file_n_ahead (__FILE__, __LINE__, STR)

#define N_fields(STR) \
  taql__file_n_fields (__FILE__, __LINE__, STR)

#define N_params(STR) \
  taql__file_n_params (__FILE__, __LINE__, STR)

#define Param_value(STR, N) \
  taql__file_param_value (__FILE__, __LINE__, STR, N)

#define Field_name(STR, N) \
  taql_box_sym (taql__file_field_name (__FILE__, __LINE__, STR, N))

#define Field_type(STR, N) \
  taql_box_sym (taql__sym (__FILE__, __LINE__, (taql__type_tag_name (__FILE__, __LINE__, taql__file_field_type (__FILE__, __LINE__, STR, N)))))

#define Param_name(STR, N) \
  taql_box_sym (taql__file_param_name (__FILE__, __LINE__, STR, N))

#define Comment(STR) \
  taql__file_comment (__FILE__, __LINE__, STR)

#define Fprint(STDIO, B) \
  taql__fprint (__FILE__, __LINE__, STDIO, B)

#define Fatal(STR) \
  taql__fatal (__FILE__, __LINE__, STR)

#define as_Int32(B) \
  taql__asa_int32 (__FILE__, __LINE__, B)

#define as_Int8(B) \
  taql__asa_int32 (__FILE__, __LINE__, B)

#define as_uInt32(B) \
  taql__asa_uint32 (__FILE__, __LINE__, B)

#define as_uInt64(B) \
  taql__asa_uint64 (__FILE__, __LINE__, B)

#define Add_to_comment(STR, CHR) \
  taql__file_add_to_comment (__FILE__, __LINE__, STR, CHR)

#define Lex(TXT) \
  taql__lex (__FILE__, __LINE__, TXT)

#define Sym_ref(B,N) \
  taql__sym_ref (__FILE__, __LINE__, \
                 taql__unbox_sym (__FILE__, __LINE__, B), \
                 N)

#define Eq(A, B) \
  taql__eq (__FILE__, __LINE__, A, B)

#define Field_pos(STR, NAME) \
  taql__file_field_pos (__FILE__, __LINE__, STR, taql__unbox_sym (__FILE__, __LINE__, NAME))

#define Recno(STR) \
  taql__file_recno (__FILE__, __LINE__, STR)


/* automatically generated __STDC__ prototypes */
#endif  /* INCLUDE__LIBTAQL__MACROS_H */

/* arch-tag: Thomas Lord Sat Oct 28 11:30:18 2006 (libtaql/macros.h)
 */
