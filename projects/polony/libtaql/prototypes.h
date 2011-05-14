/* prototypes.h:
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

#ifndef INCLUDE__LIBTAQL__PROTOTYPES_H
#define INCLUDE__LIBTAQL__PROTOTYPES_H


static t_taql_sym taql_sym_nil (void);
static int taql_sym_cmp (t_taql_sym s1, t_taql_sym s2);
static t_taql_sym taql__sym (const char * file, size_t line, const char * s);
static void taql__unpack_sym (char * s, t_taql_sym a);
static int taql__sym_ref (const char * file, size_t line,
                          t_taql_sym a,
                          int x);
static t_taql_sym taql__sym_adjoin (const char * file,
                                        size_t line,
                                        t_taql_sym a,
                                        char c);





static void taql__schema_fix (const char * file,
                              size_t line,
                              struct taql__schema * s);


static int taql__schema_is_fixed (const char * file,
                                  size_t line,
                                  struct taql__schema * s);

static size_t taql__schema_sizeof (const char * file,
                                   size_t line,
                                   struct taql__schema * s);



static size_t taql__schema_n_fields (const char * file,
                                     size_t line,
                                     struct taql__schema * s);


static size_t taql__schema_n_params (const char * file,
                                     size_t line,
                                     struct taql__schema * s);

static t_taql_sym taql__schema_param_name (const char * file,
                                           size_t line,
                                           struct taql__schema * s,
                                           size_t n);

static t_taql_boxed taql__schema_param_value (const char * file,
                                              size_t line,
                                              struct taql__schema * s,
                                              size_t n);

static const char * taql__schema_comment (const char * file,
                                          size_t line,
                                          struct taql__schema * s);


static void taql__schema_set_comment (const char * file,
                                      size_t line,
                                      struct taql__schema * s,
                                      const char * c);

static enum taql_type_tag taql__schema_field_type (const char * file,
                                                   size_t line,
                                                   struct taql__schema * s,
                                                   size_t field);


static t_taql_sym taql__schema_field_name (const char * file,
                                             size_t line,
                                             struct taql__schema * s,
                                             size_t field);


static size_t taql__schema_col_offsets (const char * file, size_t line,
                                        enum taql_type_tag * type,
                                        size_t * bit_offset,
                                        struct taql__schema * s,
                                        size_t col);


static void taql__memtable_fix (const char * file,
                                size_t line,
                                struct taql__memtable * m);

static int taql__memtable_is_fixed (const char * file,
                                    size_t line,
                                    struct taql__memtable * m);

static size_t taql__memtable_sizeof_record (const char * file,
                                            size_t line,
                                            struct taql__memtable * m);


static size_t taql__memtable_n_fields (const char * file,
                                       size_t line,
                                       struct taql__memtable * m);


static size_t taql__memtable_n_params (const char * file,
                                       size_t line,
                                       struct taql__memtable * m);

static t_taql_sym taql__memtable_param_name (const char * file,
                                             size_t line,
                                             struct taql__memtable * m,
                                             size_t n);

static t_taql_boxed taql__memtable_param_value (const char * file,
                                                size_t line,
                                                struct taql__memtable * m,
                                                size_t n);

static const char * taql__memtable_comment (const char * file,
                                            size_t line,
                                            struct taql__memtable * m);


static void taql__memtable_set_comment (const char * file,
                                        size_t line,
                                        struct taql__memtable * m,
                                        const char * c);

static enum taql_type_tag taql__memtable_field_type (const char * file,
                                                     size_t line,
                                                     struct taql__memtable * m,
                                                     size_t field);


static t_taql_sym taql__memtable_field_name (const char * file,
                                               size_t line,
                                               struct taql__memtable * m,
                                               size_t field);


static size_t taql__memtable_cursor (const char * file,
                                     size_t line,
                                     struct taql__memtable * m);


static void * taql__memtable_buffer (const char * file,
                                     size_t line,
                                     struct taql__memtable * m);


static size_t taql__memtable_buffer_size (const char * file,
                                          size_t line,
                                          struct taql__memtable * m);

static size_t taql__memtable_fillptr (const char * file,
                                      size_t line,
                                      struct taql__memtable * m);

static size_t taql__memtable_n_ahead (const char * file,
                                      size_t line,
                                      struct taql__memtable * m);

static size_t taql__memtable_col_offsets (const char * file, size_t line,
                                          enum taql_type_tag * type,
                                          size_t * bit_offset,
                                          struct taql__memtable * m,
                                          size_t col);



static size_t taql__file_cursor (const char * file,
                                 size_t line,
                                 size_t stream);




static struct taql__file * taql__file_table_ref (const char * file,
                                                 size_t line,
                                                 size_t stream);



static void * taql__file_row_mem (const char * file,
                                  size_t line,
                                  struct taql__file * f,
                                  size_t row_offset);

static void * taql__file_row_addr (const char * file,
                                   size_t line,
                                   size_t stream,
                                   size_t row_offset);
     
static size_t taql__file_col_offs (const char * file, size_t line,
                                   enum taql_type_tag * type,
                                   size_t * bit_offset,
                                   struct taql__file * f,
                                   size_t col);

static size_t taql__file_col_offsets (const char * file, size_t line,
                                      enum taql_type_tag * type,
                                      size_t * bit_offset,
                                      size_t stream,
                                      size_t col);

static t_taql_boxed taql__file_peek_at (const char * file, size_t line,
                                        struct taql__file * f,
                                        size_t row,
                                        size_t col);

static t_taql_boxed taql__file_peek (const char * file, size_t line,
                                     size_t stream,
                                     size_t row,
                                     size_t col);

static void taql__file_poke_at (const char * file, size_t line,
                                struct taql__file * f,
                                size_t row,
                                size_t col,
                                t_taql_boxed b);

static void taql__file_poke (const char * file, size_t line,
                             size_t stream,
                             size_t row,
                             size_t col,
                             t_taql_boxed b);

static size_t taql__file_n_fields (const char * file,
                                   size_t line,
                                   size_t stream);

static t_taql_sym taql__file_param_name (const char * file,
                                         size_t line,
                                         size_t stream,
                                         size_t n);

static size_t taql__file_n_params (const char * file,
                                   size_t line,
                                   size_t stream);

static t_taql_sym taql__file_param_name (const char * file,
                                         size_t line,
                                         size_t stream,
                                         size_t n);

static t_taql_boxed taql__file_param_value (const char * file,
                                            size_t line,
                                            size_t stream,
                                            size_t n);

static const char * taql__file_comment (const char * file,
                                        size_t line,
                                        size_t stream);


static void taql__file_set_comment (const char * file,
                                    size_t line,
                                    size_t stream,
                                    const char * c);




extern void begin (int argc, const char * argv[]);




/* automatically generated __STDC__ prototypes */
#endif  /* INCLUDE__LIBTAQL__PROTOTYPES_H */

/* arch-tag: Thomas Lord Fri Oct 27 20:06:43 2006 (libtaql/prototypes.h)
 */

