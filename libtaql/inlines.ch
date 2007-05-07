/* inlines.c: 
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



/* sym  
 */

static inline t_taql_sym
taql_sym_nil (void)
{
  t_taql_sym a;
  memset ((void *)&a, 0, sizeof (a));
  return a;
}


static inline int
taql_sym_cmp (t_taql_sym s1, t_taql_sym s2)
{
  return strncmp (s1._str, s2._str, 8);
}


static inline t_taql_sym
taql__sym (const char * file, size_t line, const char * s)
{
  t_taql_sym a;
  int x;

  for (x = 0; (x < 8) && s[x]; ++x)
    a._str[x] = s[x];

  if (s[x])
    {
      taql__fatal (file, line, "sym too long");
    }

  for (; x < 8; ++x)
    a._str[x] = 0;
  
  return a;
}

static inline void
taql__unpack_sym (char * s, t_taql_sym a)
{
  memmove ((void *)s, a._str, 8);
  s[8] = 0;
}


static inline int
taql__sym_ref (const char * file, size_t line,
               t_taql_sym a, int x)
{
  if ((x < 0) || (x >= 8))
    taql__fatal (file, line, "sym index range error");
  return a._str[x];
}


static inline t_taql_sym
taql__sym_adjoin (const char * file,
                    size_t line,
                    t_taql_sym a,
                    char c)
{
  int x;

  for (x = 0; x < 8; ++x)
    {
      if (!a._str[x])
        {
          a._str[x] = c;
          return a;
        }
    }

  taql__fatal (file, line, "astr overflow");
  return a;
}



static inline void
taql__schema_fix (const char * file,
                  size_t line,
                  struct taql__schema * s)
{
  s->_schema_fixed = 1;
}


static inline int
taql__schema_is_fixed (const char * file,
                       size_t line,
                       struct taql__schema * s)
{
  return s->_schema_fixed;
}



static inline size_t
taql__schema_sizeof (const char * file,
                     size_t line,
                     struct taql__schema * s)
{
  return s->_sizeof_schema;
}



static inline size_t
taql__schema_n_fields (const char * file,
                       size_t line,
                       struct taql__schema * s)
{
  return s->_n_fields;
}


static inline size_t
taql__schema_n_params (const char * file,
                       size_t line,
                       struct taql__schema * s)
{
  return s->_n_params;
}


static inline t_taql_sym
taql__schema_param_name (const char * file,
                         size_t line,
                         struct taql__schema * s,
                         size_t n)
{
  if (n >= s->_n_params)
    taql__fatal (file, line, "param number range error");
  
  return s->_params[n]._name;
}


static inline t_taql_boxed
taql__schema_param_value (const char * file,
                          size_t line,
                          struct taql__schema * s,
                          size_t n)
{
  if (n >= s->_n_params)
    taql__fatal (file, line, "param number range error");
  
  return s->_params[n]._value;
}


static inline const char *
taql__schema_comment (const char * file,
                      size_t line,
                      struct taql__schema * s)
{
  return s->_comment;
}


static inline void
taql__schema_set_comment (const char * file,
                          size_t line,
                          struct taql__schema * s,
                          const char * c)
{
  size_t len;

  len = strlen (c);

  if ((len + 1) > sizeof (s->_comment))
    taql__fatal (file, len, "excessive comment length");

  memcpy ((void *)s->_comment, (void *)c, len);
  s->_comment[len + 1] = 0;
  s->_comment_len = len;
}


static inline enum taql_type_tag
taql__schema_field_type (const char * file,
                         size_t line,
                         struct taql__schema * s,
                         size_t field)
{
  if (field >= s->_n_fields)
    taql__fatal (file, line, "field number range error");
  return s->_fields[field]._type;
}


static inline t_taql_sym
taql__schema_field_name (const char * file,
                         size_t line,
                         struct taql__schema * s,
                         size_t field)
{
  if (field >= s->_n_fields)
    taql__fatal (file, line, "field number range error");
  return s->_fields[field]._name;
}


static inline size_t
taql__schema_col_offsets (const char * file, size_t line,
                          enum taql_type_tag * type,
                          size_t * bit_offset,
                          struct taql__schema * s,
                          size_t col)
{
  if (col >= s->_n_fields)
    taql__fatal (file, line, "row underflow");
  *type = s->_fields[col]._type;
  *bit_offset = s->_fields[col]._bit_offset;
  return s->_fields[col]._byte_offset;
}




static inline void
taql__memtable_fix (const char * file,
                    size_t line,
                    struct taql__memtable * m)
{
  taql__schema_fix (file, line, &m->_schema);
}


static inline int
taql__memtable_is_fixed (const char * file,
                         size_t line,
                         struct taql__memtable * m)
{
  return taql__schema_is_fixed (file, line, &m->_schema);
}




static inline size_t
taql__memtable_sizeof_record (const char * file,
                              size_t line,
                              struct taql__memtable * m)
{
  return taql__schema_sizeof (file, line, &m->_schema);
}


static inline size_t
taql__memtable_n_fields (const char * file,
                         size_t line,
                         struct taql__memtable * m)
{
  return taql__schema_n_fields (file, line, &m->_schema);
}


static inline size_t
taql__memtable_n_params (const char * file,
                         size_t line,
                         struct taql__memtable * m)
{
  return taql__schema_n_params (file, line, &m->_schema);
}


static inline t_taql_sym
taql__memtable_param_name (const char * file,
                           size_t line,
                           struct taql__memtable * m,
                           size_t n)
{
  return taql__schema_param_name (file, line, &m->_schema, n);
}


static inline t_taql_boxed
taql__memtable_param_value (const char * file,
                            size_t line,
                            struct taql__memtable * m,
                            size_t n)
{
  return taql__schema_param_value (file, line, &m->_schema, n);
}


static inline const char *
taql__memtable_comment (const char * file,
                        size_t line,
                        struct taql__memtable * m)
{
  return taql__schema_comment (file, line, &m->_schema);
}


static inline void
taql__memtable_set_comment (const char * file,
                            size_t line,
                            struct taql__memtable * m,
                            const char * c)
{
  return taql__schema_set_comment (file, line, &m->_schema, c);
}


static inline enum taql_type_tag
taql__memtable_field_type (const char * file,
                           size_t line,
                           struct taql__memtable * m,
                           size_t field)
{
  return taql__schema_field_type (file, line, &m->_schema, field);
}


static inline t_taql_sym
taql__memtable_field_name (const char * file,
                           size_t line,
                           struct taql__memtable * m,
                           size_t field)
{
  return taql__schema_field_name (file, line, &m->_schema, field);
}


static inline size_t
taql__memtable_cursor (const char * file,
                       size_t line,
                       struct taql__memtable * m)
{
  return m->_cursor;
}


static inline void *
taql__memtable_buffer (const char * file,
                       size_t line,
                       struct taql__memtable * m)
{
  return m->_mem;
}


static inline size_t
taql__memtable_buffer_size (const char * file,
                            size_t line,
                            struct taql__memtable * m)
{
  return m->_memsize;
}


static inline size_t
taql__memtable_fillptr (const char * file,
                        size_t line,
                        struct taql__memtable * m)
{
  return m->_fillptr;
}


static inline size_t
taql__memtable_n_ahead (const char * file,
                        size_t line,
                        struct taql__memtable * m)
{
  return (m->_n_rows - m->_cursor);
}

static inline size_t
taql__memtable_col_offsets (const char * file, size_t line,
                            enum taql_type_tag * type,
                            size_t * bit_offset,
                            struct taql__memtable * m,
                            size_t col)
{
  return taql__schema_col_offsets (file, line,
                                   type,
                                   bit_offset,
                                   &m->_schema,
                                   col);
}




static inline struct taql__file *
taql__file_table_ref (const char * file,
                      size_t line,
                      size_t stream)
{
  struct taql__file * answer;

  if (stream >= taql__file_table_size)
    taql__fatal (file, line, "bogus file number");

  answer = &taql__file_table[stream];

  if (answer->_next_free_file != stream)
    taql__fatal (file, line, "bogus file number");

  return answer;
}



static inline size_t
taql__file_cursor (const char * file,
                   size_t line,
                   size_t stream)
{
  struct taql__file * f;
  f = taql__file_table_ref (file, line, stream);
  return f->_file_record_offset + taql__memtable_cursor (file, line, &f->_memtable);
}


static inline void *
taql__file_row_mem (const char * file,
                    size_t line,
                    struct taql__file * f,
                    size_t row_offset)
{
  void * mem = taql__memtable_buffer (file, line, &f->_memtable);
  size_t bound = taql__memtable_n_ahead (file, line, &f->_memtable);
  size_t cursor = taql__memtable_cursor (file, line, &f->_memtable);
  size_t where = cursor + row_offset;
  size_t row_size = taql__memtable_sizeof_record (file, line, &f->_memtable);

  if (row_offset >= bound)
    taql__fatal (file, line, "buffer underflow");

  return (void *)((where * row_size) + (char *)mem);
}


static inline void *
taql__file_row_addr (const char * file,
                     size_t line,
                     size_t stream,
                     size_t row_offset)
{
  return taql__file_row_mem (file, line,
                             taql__file_table_ref (file, line, stream),
                             row_offset);
}


static inline size_t
taql__file_col_offs (const char * file, size_t line,
                     enum taql_type_tag * type,
                     size_t * bit_offset,
                     struct taql__file * f,
                     size_t col)
{
  return taql__memtable_col_offsets (file, line,
                                     type,
                                     bit_offset,
                                     &f->_memtable,
                                     col);
}


static inline size_t
taql__file_col_offsets (const char * file, size_t line,
                        enum taql_type_tag * type,
                        size_t * bit_offset,
                        size_t stream,
                        size_t col)
{
  return taql__file_col_offs (file, line,
                              type,
                              bit_offset,
                              taql__file_table_ref (file, line, stream),
                              col);
}
                                     

static inline t_taql_boxed
taql__file_peek_at (const char * file, size_t line,
                    struct taql__file * f,
                    size_t row,
                    size_t col)
{
  void * rowmem = taql__file_row_mem (file, line, f, row);
  size_t bit_offset = 0;
  enum taql_type_tag type = taql_t_nil;
  size_t byte_offset = taql__file_col_offs (file, line, &type, &bit_offset, f, col);
  void * mem = (void *)(byte_offset + (char *)rowmem);

  return taql__unpack_boxed (file, line, mem, bit_offset, type);
}


static inline t_taql_boxed
taql__file_peek (const char * file, size_t line,
                 size_t stream,
                 size_t row,
                 size_t col)
{
  return taql__file_peek_at (file, line,
                             taql__file_table_ref (file, line, stream),
                             row,
                             col);
}


static inline void
taql__file_poke_at (const char * file, size_t line,
                    struct taql__file * f,
                    size_t row,
                    size_t col,
                    t_taql_boxed b)
{
  void * rowmem = taql__file_row_mem (file, line, f, row);
  size_t bit_offset = 0;
  enum taql_type_tag type = taql_t_nil;
  size_t byte_offset = taql__file_col_offs (file, line, &type, &bit_offset, f, col);
  void * mem = (void *)(byte_offset + (char *)rowmem);

  taql__pack_boxed (file, line, mem, bit_offset, type, b);
}


static inline void
taql__file_poke (const char * file, size_t line,
                 size_t stream,
                 size_t row,
                 size_t col,
                 t_taql_boxed b)
{
  return taql__file_poke_at (file, line,
                             taql__file_table_ref (file, line, stream),
                             row,
                             col,
                             b);
}


static inline size_t
taql__file_n_fields (const char * file,
                     size_t line,
                     size_t stream)
{
  return taql__memtable_n_fields (file, line,
                                  &taql__file_table_ref (file,
                                                         line,
                                                         stream)->_memtable);
}




static inline t_taql_sym
taql__file_field_name (const char * file,
                       size_t line,
                       size_t stream,
                       size_t n)
{
  return taql__memtable_field_name (file, line,
                                    &taql__file_table_ref (file,
                                                           line,
                                                           stream)->_memtable,
                                    n);
}


static inline enum taql_type_tag
taql__file_field_type (const char * file,
                       size_t line,
                       size_t stream,
                       size_t n)
{
  return taql__memtable_field_type (file, line,
                                    &taql__file_table_ref (file,
                                                           line,
                                                           stream)->_memtable,
                                    n);
}

static inline size_t
taql__file_n_params (const char * file,
                     size_t line,
                     size_t stream)
{
  return taql__memtable_n_params (file, line,
                                  &taql__file_table_ref (file,
                                                         line,
                                                         stream)->_memtable);
}


static inline t_taql_sym
taql__file_param_name (const char * file,
                       size_t line,
                       size_t stream,
                       size_t n)
{
  return taql__memtable_param_name (file, line,
                                    &taql__file_table_ref (file,
                                                           line,
                                                           stream)->_memtable,
                                    n);
}


static inline t_taql_boxed
taql__file_param_value (const char * file,
                        size_t line,
                        size_t stream,
                        size_t n)
{
  return taql__memtable_param_value (file, line,
                                     &taql__file_table_ref (file,
                                                            line,
                                                            stream)->_memtable,
                                     n);
}


static inline const char *
taql__file_comment (const char * file,
                    size_t line,
                    size_t stream)
{
  return taql__memtable_comment (file, line,
                                 &taql__file_table_ref (file,
                                                        line,
                                                        stream)->_memtable);
}


static inline void
taql__file_set_comment (const char * file,
                        size_t line,
                        size_t stream,
                        const char * c)
{
  return taql__memtable_set_comment (file, line,
                                     &taql__file_table_ref (file,
                                                            line,
                                                            stream)->_memtable,
                                     c);
}






/* arch-tag: Thomas Lord Fri Oct 27 20:06:48 2006 (libtaql/inlines.c)
 */

