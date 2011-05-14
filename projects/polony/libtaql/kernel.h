/* kernel.h:
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



#ifndef INCLUDE__LIBTAQL__KERNEL_H
#define INCLUDE__LIBTAQL__KERNEL_H


struct taql__field_type
{
  t_taql_sym _name;
  enum taql_type_tag _type;
  size_t _byte_offset;
  size_t _bit_offset;
};


struct taql__param_binding
{
  t_taql_sym _name;
  t_taql_boxed _value;
};


struct taql__schema
{
  size_t _n_fields;
  struct taql__field_type * _fields;
  size_t _sizeof_schema;
  size_t _n_params;
  struct taql__param_binding * _params;
  size_t _comment_len;
  char _comment[8192];
  int _schema_fixed;
};


struct taql__memtable
{
  struct taql__schema _schema;

  size_t _n_rows;
  size_t _cursor;

  void * _mem;
  size_t _memsize;
  size_t _fillptr;
};


struct taql__file
{
  struct taql__memtable _memtable;
 
  size_t _n_ahead;
  size_t _file_byte_offset;
  size_t _file_record_offset;
  int _stream;
  int _is_output_p;

  size_t _next_free_file;
};


extern struct taql__file * taql__file_table;
extern size_t taql__file_table_size;
extern ssize_t taql__free_file;




/* automatically generated __STDC__ prototypes */
extern void taql__fmt_sym (const char * file,
                           size_t line,
                           char * buf,
                           size_t bufsize,
                           t_taql_sym a);
extern t_taql_boxed taql__lex (const char * file,
                               size_t line,
                               const char * lexeme);
extern void taql__init_schema (const char * file,
                               size_t line,
                               struct taql__schema * s);
extern void taql__uninit_schema (const char * file,
                                 size_t line,
                                 struct taql__schema * s);
extern void taql__schema_add_field (const char * file,
                                    size_t line,
                                    struct taql__schema * s,
                                    enum taql_type_tag type,
                                    t_taql_sym name);
extern void taql__schema_add_param (const char * file,
                                    size_t line,
                                    struct taql__schema * s,
                                    t_taql_sym name,
                                    t_taql_boxed value);
extern void taql__schema_add_to_comment (const char * file, size_t line,
                                         struct taql__schema * s,
                                         int c);
extern size_t taql__schema_field_pos (const char * file, size_t line,
                                      size_t stream,
                                      struct taql__schema * s,
                                      t_taql_sym name);
extern void taql__init_memtable (const char * file,
                                 size_t line,
                                 struct taql__memtable * mt);
extern void taql__uninit_memtable (const char * file,
                                   size_t line,
                                   struct taql__memtable * mt);
extern void taql__memtable_set_memsize (const char * file,
                                        size_t line,
                                        struct taql__memtable * mt,
                                        size_t buffer_size);
extern void taql__memtable_add_field (const char * file,
                                      size_t line,
                                      struct taql__memtable * m,
                                      enum taql_type_tag type,
                                      t_taql_sym name);
extern void taql__memtable_add_param (const char * file,
                                      size_t line,
                                      struct taql__memtable * m,
                                      t_taql_sym name,
                                      t_taql_boxed value);
extern void taql__memtable_clear_fill (const char * file,
                                       size_t line,
                                       struct taql__memtable * m);
extern void taql__memtable_fill_n (const char * file,
                                   size_t line,
                                   struct taql__memtable * m,
                                   size_t amt);
extern void taql__memtable_shift (const char * file,
                                  size_t line,
                                  struct taql__memtable * m,
                                  int clear_fill_p);
extern void taql__memtable_advance_cursor (const char * file,
                                           size_t line,
                                           struct taql__memtable * m,
                                           size_t n_rows);
extern void taql__memtable_add_to_comment (const char * file, size_t line,
                                           struct taql__memtable * m,
                                           int c);
extern size_t taql__memtable_field_pos (const char * file, size_t line,
                                        size_t stream,
                                        struct taql__memtable * m,
                                        t_taql_sym name);
extern size_t taql__open_outfile (const char * file,
                                  size_t line,
                                  const char * outfile_spec);
extern size_t taql__open_infile (const char * file,
                                 size_t line,
                                 const char * outfile_spec);
extern void taql__file_close (const char * file,
                              size_t line,
                              size_t stream);
extern void taql__file_add_field (const char * file,
                                  size_t line,
                                  size_t stream,
                                  enum taql_type_tag type,
                                  t_taql_sym name);
extern void taql__file_add_param (const char * file,
                                  size_t line,
                                  size_t stream,
                                  t_taql_sym name,
                                  t_taql_boxed value);
extern void taql__file_fix_headers (const char * file,
                                    size_t line,
                                    size_t stream,
                                    size_t n_ahead,
                                    size_t buffer_suggested);
extern void taql__file_fix_outputting_header (const char * file,
                                              size_t line,
                                              size_t stream,
                                              size_t n_ahead,
                                              size_t buffer_suggested);
extern void taql__file_fix_from_header (const char * file,
                                        size_t line,
                                        size_t stream,
                                        size_t n_ahead,
                                        size_t buffer_suggested);
extern void taql__file_fix (const char * file,
                            size_t line,
                            size_t stream,
                            size_t n_ahead,
                            size_t buffer_suggested);
extern size_t taql__file_n_ahead (const char * file,
                                  size_t line,
                                  size_t stream);
extern size_t taql__file_advance_cursor (const char * file,
                                         size_t line,
                                         size_t stream,
                                         size_t n_rows);
extern void taql__file_add_to_comment (const char * file, size_t line,
                                       size_t stream,
                                       int c);
extern size_t taql__file_field_pos (const char * file, size_t line,
                                    size_t stream,
                                    t_taql_sym name);
extern size_t taql__file_recno (const char * file, size_t line, size_t stream);
extern void taql__fprint (char * file, size_t line, FILE * stream, t_taql_boxed b);
extern enum taql_type_tag taql__unbox_to_type_tag (const char * file, size_t line, t_taql_boxed b);
#endif  /* INCLUDE__LIBTAQL__KERNEL_H */

/* arch-tag: Thomas Lord Fri Oct 27 20:10:30 2006 (kernel.h)
 */
