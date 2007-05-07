/* kernel.c: 
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



/* __STDC__ prototypes for static functions */
static t_taql_boxed taql__lex_numeric (const char * file,
                                       size_t line,
                                       const char * lexeme);
static t_taql_uint64 my_atoull (const char * buf);
static t_taql_boxed taql__lex_sym (const char * file,
                                   size_t line,
                                   const char * lexeme);
static size_t taql__layout_row (const char * file,
                                size_t line,
                                struct taql__field_type * fields,
                                size_t n_fields);
static size_t taql__allocate_file (void);
static void taql__unallocate_file (const char * file, size_t line, size_t stream);
static void write__retry (const char * file,
                          size_t line,
                          int fd,
                          const char * buf,
                          size_t amt);
static ssize_t read__retry (const char * file,
                            size_t line,
                            int fd,
                            char * buf,
                            size_t amt);
static void taql__write_output_file_header (const char * file,
                                            size_t line,
                                            struct taql__file * f);
static int lex__match (size_t * pos,
                       char * buf,
                       size_t len,
                       char * lexeme);
static int lex__skip_blanks (size_t * pos, char * buf, size_t len);
static int lex__lexeme (char * lexeme,
                        size_t * pos,
                        char * buf,
                        size_t len);
static void taql__file_extend_buffer (const char * file,
                                      size_t line,
                                      struct taql__file * f);
static void taql__file_extend_output_buffer (const char * file,
                                             size_t line,
                                             struct taql__file * f);
static void taql__file_extend_input_buffer (const char * file,
                                            size_t line,
                                            struct taql__file * f);
static void taql__file_extend_with (const char * file,
                                    size_t line,
                                    struct taql__file * f,
                                    const char * input,
                                    size_t amt);



void
taql__fmt_sym (const char * file,
                 size_t line,
                 char * buf,
                 size_t bufsize,
                 t_taql_sym a)
{
  int x;
  if (bufsize < 64)
    {
      fputs ("output error\n", stderr);
      exit (2);
    }

  buf[0] = '"';
  for (x = 0; x < 8; ++x)
    {
      buf[x + 1] = a._str[x];
      if (!a._str[x])
        break;
    }
  buf[x + 1] = '"';
  ++x;
  buf[x + 1] = 0;
}




t_taql_boxed
taql__lex (const char * file,
           size_t line,
           const char * lexeme)
{
  while (isspace (*lexeme))
    ++lexeme;

  switch (*lexeme)
    {
    default:
      taql__fatal (file, line, "bogus input lexeme");
      return taql_box_int32 (0); 

    case '-':
    case '+':
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
      return taql__lex_numeric (file, line, lexeme);

    case '"':
      return taql__lex_sym (file, line, lexeme);
    }
}


static t_taql_boxed
taql__lex_numeric (const char * file,
                   size_t line,
                   const char * lexeme)
{
  const char * n_start;
  const char * n_end;
  int saw_decimal;
  int saw_exponential;
  int is_inexact;
  int negated = 0;
  enum taql_type_tag type;
  char buf[256];

  n_start = lexeme;
  n_end = n_start;
  saw_decimal = 0;
  saw_exponential = 0;
  is_inexact = 0;
  negated = 0;
  type = taql_t_uint64;

  if (*n_end == '-')
    {
      negated = 1;
      type = taql_t_int64;
      ++n_end;
    }

  if (*n_end == '+')
    {
      ++n_end;
      ++n_start;
    }

  while (1)
    {
      switch (*n_end)
        {
        default: type_error:
          taql__fatal (file, line, "bogus numeric input lexeme");
          return taql_box_int32 (0); 

        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
          ++n_end;
          break;

        case '.':
          if (saw_decimal)
            goto type_error;
          saw_decimal = 1;
          is_inexact = 1;
	  type = taql_t_dfloat;
          ++n_end;
          break;

        case 'e':
          if (saw_exponential)
            goto type_error;
          saw_exponential = 1;
          saw_decimal = 0;
          is_inexact = 1;
          type = taql_t_dfloat;
          ++n_end;
          if (*n_end == '+')
            ++n_end;
          else if (*n_end == '-')
            {
              ++n_end;
            }
          break;
        case '#':
          {
            ++n_end;
            if (!taql__lex_typename (&type, n_end))
              goto type_error;
            goto done_scanning;
          }
        case '\0':
          goto done_scanning;
        }
    }

 done_scanning:
  if ((n_end - n_start) > (sizeof (buf) - 1))
    goto type_error;

  memmove (buf, n_start, (n_end - n_start));
  buf[(n_end - n_start)] = 0;

  switch (type)
    {
    default: goto type_error;

    case taql_t_int8:
      return taql_box_int8 ((t_taql_int32)atoi (buf));
    case taql_t_uint8:
      if (negated) goto type_error;
      return taql_box_uint8 ((t_taql_uint32)atoi (buf));
    case taql_t_int32:
      return taql_box_int32 ((t_taql_int32)atoi (buf));
    case taql_t_uint32:
      if (negated) goto type_error;
      return taql_box_uint32 ((t_taql_uint32)atoll (buf));
    case taql_t_int64:
      return taql_box_int64 ((t_taql_int64)atoll (buf));
    case taql_t_uint64:
      if (negated) goto type_error;
      return taql_box_uint64 ((t_taql_uint64)my_atoull (buf));
    case taql_t_sfloat:
      if (negated) goto type_error;
      return taql_box_sfloat ((t_taql_sfloat)atof (buf));
    case taql_t_dfloat:
      return taql_box_dfloat ((t_taql_dfloat)atof (buf));
    }
}

static t_taql_uint64
my_atoull (const char * buf)
{
  t_taql_uint64 x = 0;

  while (*buf)
    {
      x = (x * 10) + (*buf - '0');
      ++buf;
    }

  return x;
}


static t_taql_boxed
taql__lex_sym (const char * file,
               size_t line,
               const char * lexeme)
{
  int x;
  t_taql_sym sym;

  if (!(*lexeme == '"'))
    {
    type_error:
      taql__fatal (file, line, "bogus input lexeme");
      return taql_box_int32 (0);
    }

  ++lexeme;

  sym = taql_sym_nil ();

  x = 0;

  while (1)
    {
      char c;

      if (x == 8)
        goto type_error;
      else
        ++x;

      switch (*lexeme)
        {
        default:
          c = *lexeme;
          ++lexeme;
          break;

        case '"':
          {
            return taql_box_sym (sym);
          }

        case '\\':
          ++lexeme;
          switch (*lexeme)
            {
            default:
              goto type_error;

            case 'n':
              c = '\n';
              ++lexeme;
              break;
            case 'f':
              c = '\f';
              ++lexeme;
              break;
            case 'r':
              c = '\r';
              ++lexeme;
              break;
            case '0':
              {
                int q;
                ++lexeme;
                c = 0;
                q = 0;
                while (q < 3)
                  {
                    switch (*lexeme)
                      {
                      case '0': case '1': case '2': case '3':
                      case '4': case '5': case '6': case '7':
                        c <<= 3;
                        c |= (*lexeme - '0');
                        ++q;
                        ++lexeme;
                        break;
                      default:
                        goto done_octal;
                      }
                  }
              done_octal:
                break;
              }
            };
          break;
        }

      sym = taql__sym_adjoin (file, line, sym, c);
    }
}



void
taql__init_schema (const char * file,
                   size_t line,
                   struct taql__schema * s)
{
  s->_sizeof_schema = 0;
  s->_n_fields = 0;
  s->_fields = 0;
  s->_n_params = 0;
  s->_params = 0;
  s->_comment_len = 0;
  s->_schema_fixed = 0;
}


void
taql__uninit_schema (const char * file,
                     size_t line,
                     struct taql__schema * s)
{
  free (s->_fields);
  taql__init_schema (file, line, s);
}


void
taql__schema_add_field (const char * file,
                        size_t line,
                        struct taql__schema * s,
                        enum taql_type_tag type,
                        t_taql_sym name)
{
  size_t new_n_fields;
  struct taql__field_type * new_fields;
  size_t new_sizeof_schema;

  if (s->_schema_fixed)
    {
      taql__fatal (file, line, "late schema change");
    }

  new_n_fields = s->_n_fields + 1;

  new_fields = ((struct taql__field_type *)
                realloc ((void *)s->_fields, new_n_fields * sizeof (struct taql__field_type)));
  if (!new_fields)
    taql__fatal (file, line, "out of memory");

  new_fields[s->_n_fields]._name = name;
  new_fields[s->_n_fields]._type = type;

  /* new_fields[s->_n_fields]._byte_offset = <set by taql__layout_row> */
  /* new_fields[s->_n_fields]._bit_offset = <set by taql__layout_row> */
  new_sizeof_schema = taql__layout_row (file, line, new_fields, new_n_fields);
  
  s->_n_fields = new_n_fields;
  s->_fields = new_fields;
  s->_sizeof_schema = new_sizeof_schema;
}


static size_t
taql__layout_row (const char * file,
                  size_t line,
                  struct taql__field_type * fields,
                  size_t n_fields)
{
  size_t x;
  size_t byte_offset;
  size_t bit_offset;

  byte_offset = 0;
  bit_offset = 0;
  for (x = 0; x < n_fields; ++x)
    {
      size_t bits_left_in_byte = 8 - bit_offset;
      size_t field_bits = taql__bitsof (file, line, fields[x]._type);
      size_t field_alignment = ((field_bits <= 8)
                                ? 0
                                : ((field_bits >> 3) - 1));

      if (!field_bits)
        {
          taql__fatal (file, line, "type error in schema (non-storable type)");
        }

      if (bit_offset && (bits_left_in_byte < field_bits))
        {
          byte_offset += 1;
          bit_offset = 0;
          bits_left_in_byte = 8;
        }

      byte_offset = ((byte_offset + field_alignment) & ~field_alignment);
      
      fields[x]._byte_offset = byte_offset;
      fields[x]._bit_offset = bit_offset;

      byte_offset += (field_bits >> 3);
      bit_offset += (field_bits & 0x7);
      byte_offset += (bit_offset >> 3);
      bit_offset &= 0x7;
    }

  if (bit_offset)
    {
      bit_offset = 0;
      byte_offset += 1;
    }

  if (n_fields)
    {
      size_t first_field_bits = taql__bitsof (file, line, fields[0]._type);
      size_t first_field_alignment = ((first_field_bits <= 8)
                                      ? 0
                                      : ((first_field_bits >> 3) - 1));

      byte_offset = ((byte_offset + first_field_alignment) & ~first_field_alignment);
    }

  return byte_offset;
}


void
taql__schema_add_param (const char * file,
                        size_t line,
                        struct taql__schema * s,
                        t_taql_sym name,
                        t_taql_boxed value)
{
  size_t new_n_params;
  struct taql__param_binding * new_params;

  if (s->_schema_fixed)
    {
      taql__fatal (file, line, "late schema change");
    }

  new_n_params = s->_n_params + 1;

  new_params = ((struct taql__param_binding *)
                 realloc ((void *)s->_params, new_n_params * sizeof (struct taql__param_binding)));
  if (!new_params)
    taql__fatal (file, line, "out of memory");

  new_params[s->_n_params]._name = name;
  new_params[s->_n_params]._value = value;

  s->_n_params = new_n_params;
  s->_params = new_params;
}


void
taql__schema_add_to_comment (const char * file, size_t line,
                             struct taql__schema * s,
                             int c)
{
  if ((s->_comment_len + 2) > sizeof (s->_comment))
    taql__fatal (file, line, "file comment too long");

  s->_comment[s->_comment_len] = c;
  ++s->_comment_len;
}

size_t
taql__schema_field_pos (const char * file, size_t line,
                        size_t stream,
                        struct taql__schema * s,
                        t_taql_sym name)
{
  size_t x;

  for (x = 0; x < s->_n_fields; ++x)
    {
      if (!taql_sym_cmp (name, s->_fields[x]._name))
        return x;
    }

  taql__fatal (file, line, "no such field in table");
  return 0;
}




void
taql__init_memtable (const char * file,
                     size_t line,
                     struct taql__memtable * mt)
{
  taql__init_schema (file, line, &mt->_schema);
  mt->_cursor = 0;
  mt->_n_rows = 0;
  mt->_fillptr = 0;
  mt->_memsize = 0;
  mt->_mem = 0;
}


void
taql__uninit_memtable (const char * file,
                       size_t line,
                       struct taql__memtable * mt)
{
  taql__uninit_schema (file, line, &mt->_schema);
  taql__init_memtable (file, line, mt);
}


void
taql__memtable_set_memsize (const char * file,
                            size_t line,
                            struct taql__memtable * mt,
                            size_t buffer_size)
{
  size_t new_memsize;
  void * new_mem;
  size_t new_fillptr;
  size_t sizeof_record;
  size_t new_n_rows;
  size_t new_cursor;
  
  new_memsize = buffer_size;
  new_mem = realloc (mt->_mem, new_memsize);
  if (!new_mem)
    taql__fatal (file, line, "out of memory");

  if (mt->_fillptr < new_memsize)
    new_fillptr = mt->_fillptr;
  else
    new_fillptr = new_memsize;

  sizeof_record = taql__schema_sizeof (file, line, &mt->_schema);

  if (new_memsize >= (sizeof_record * mt->_n_rows))
    {
      new_n_rows = mt->_n_rows;
    }
  else
    {
      new_n_rows = (new_memsize / sizeof_record);
    }

  if (mt->_cursor <= new_n_rows)
    new_cursor = mt->_cursor;
  else
    new_cursor = new_n_rows;


  mt->_cursor = new_cursor;
  mt->_n_rows = new_n_rows;
  mt->_fillptr = new_fillptr;
  mt->_memsize = new_memsize;
  mt->_mem = new_mem;
}


void
taql__memtable_add_field (const char * file,
                          size_t line,
                          struct taql__memtable * m,
                          enum taql_type_tag type,
                          t_taql_sym name)
{
  return taql__schema_add_field (file, line, &m->_schema, type, name);
}

void
taql__memtable_add_param (const char * file,
                          size_t line,
                          struct taql__memtable * m,
                          t_taql_sym name,
                          t_taql_boxed value)
{
  return taql__schema_add_param (file, line, &m->_schema, name, value);
}
     
     

void
taql__memtable_clear_fill (const char * file,
                           size_t line,
                           struct taql__memtable * m)
{
  memset (m->_mem, 0, m->_memsize);
  m->_fillptr = m->_memsize;
  m->_cursor = 0;
  m->_n_rows = (  m->_memsize
                   / taql__schema_sizeof (file, line, &m->_schema));
}


void
taql__memtable_fill_n (const char * file,
                       size_t line,
                       struct taql__memtable * m,
                       size_t amt)
{
  size_t new_fillptr = m->_fillptr + amt;
  size_t new_n_rows = (new_fillptr / taql__schema_sizeof (file, line, &m->_schema));

  if ((new_fillptr < m->_fillptr) || (new_fillptr > m->_memsize))
    taql__fatal (file, line, "buffer overflow");

  m->_fillptr = new_fillptr;
  m->_n_rows = new_n_rows;
}


void
taql__memtable_shift (const char * file,
                      size_t line,
                      struct taql__memtable * m,
                      int clear_fill_p)
{
  void * buf = m->_mem;
  size_t rec_size = taql__schema_sizeof (file, line, &m->_schema);
  size_t cursor_byte_offset = (m->_cursor * rec_size);
  void * move_from = (void *)(cursor_byte_offset + (char *)buf);
  size_t move_amt = (m->_fillptr - cursor_byte_offset);


  memmove (buf, move_from, move_amt);

  
  m->_fillptr -= cursor_byte_offset;
  m->_n_rows -= m->_cursor;
  m->_cursor = 0;

  if (clear_fill_p)
    {
      void * start_at = (void *)(m->_fillptr + (char *)buf);
      size_t clear_amt = (m->_memsize - m->_fillptr);

      memset (start_at, 0, clear_amt);
      m->_fillptr = m->_memsize;
      m->_n_rows = (  m->_memsize
                       / taql__schema_sizeof (file, line, &m->_schema));
    }
}


void
taql__memtable_advance_cursor (const char * file,
                               size_t line,
                               struct taql__memtable * m,
                               size_t n_rows)
{
  size_t new_cursor = m->_cursor + n_rows;

  if (new_cursor > m->_n_rows)
    taql__fatal (file, line, "buffer underflow (advance_cursor)");

  m->_cursor = new_cursor;
}


void
taql__memtable_add_to_comment (const char * file, size_t line,
                               struct taql__memtable * m,
                               int c)
{
  taql__schema_add_to_comment (file, line, &m->_schema, c);
}


size_t
taql__memtable_field_pos (const char * file, size_t line,
                          size_t stream,
                          struct taql__memtable * m,
                          t_taql_sym name)
{
  return taql__schema_field_pos (file, line, stream, &m->_schema, name);
}





struct taql__file * taql__file_table = 0;
size_t taql__file_table_size = 0;
ssize_t taql__free_file = -1;


size_t
taql__open_outfile (const char * file,
                    size_t line,
                    const char * outfile_spec)
{
  int stream = 0;
  size_t file_no;

  if (!strcmp (outfile_spec, "-"))
    {
      stream = 1;
    }
  else if (!strcmp (outfile_spec, "/dev/null"))
    {
      stream = -1;
    }
  else
    {
      stream = open (outfile_spec, O_WRONLY | O_CREAT | O_TRUNC, 0666);
      if (stream < 0)
        {
          fputs ("could not open output file (", stderr);
          fputs (outfile_spec, stderr);
          fputs (")\n", stderr);
          exit (2);
        }
    }

  file_no = taql__allocate_file ();
  taql__file_table[file_no]._is_output_p = 1;
  taql__file_table[file_no]._stream = stream;
  taql__file_table[file_no]._n_ahead = 0;
  taql__file_table[file_no]._file_byte_offset = 0;
  taql__file_table[file_no]._file_record_offset = 0;
  taql__init_memtable (file, line, &taql__file_table[file_no]._memtable);
  return file_no;
}


size_t
taql__open_infile (const char * file,
                   size_t line,
                   const char * outfile_spec)
{
  int stream = 0;
  size_t file_no;

  if (!strcmp (outfile_spec, "-"))
    {
      stream = 0;
    }
  else if (!strcmp (outfile_spec, "/dev/null"))
    {
      stream = -1;
    }
  else
    {
      stream = open (outfile_spec, O_RDONLY, 0);
      if (stream < 0)
        {
          fputs ("could not open input file (", stderr);
          fputs (outfile_spec, stderr);
          fputs (")\n", stderr);
          exit (2);
        }
    }

  file_no = taql__allocate_file ();
  taql__file_table[file_no]._is_output_p = 0;
  taql__file_table[file_no]._stream = stream;
  taql__file_table[file_no]._n_ahead = 0;
  taql__file_table[file_no]._file_byte_offset = 0;
  taql__file_table[file_no]._file_record_offset = 0;
  taql__init_memtable (file, line, &taql__file_table[file_no]._memtable);
  return file_no;
}

void
taql__file_close (const char * file,
                  size_t line,
                  size_t stream)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);

  if (f->_is_output_p)
    taql__file_extend_buffer (file, line, f);

  if (f->_stream >= 0)
    {
      if (close (f->_stream))
        taql__fatal (file, line, "file close error");
    }

  taql__uninit_memtable (file, line, &f->_memtable);
  taql__unallocate_file (file, line, stream);
}




static size_t
taql__allocate_file (void)
{
  size_t answer;

 start_over:

  if (taql__free_file >= 0)
    {
      answer = taql__free_file;
      taql__free_file = taql__file_table[answer]._next_free_file;
    }
  else
    {
      size_t new_file_table_size = (taql__file_table_size
                                    ? (2 * taql__file_table_size)
                                    : 256);
      struct taql__file * new_table;
      size_t x;

      if (taql__file_table_size && ((new_file_table_size / 2) != taql__file_table_size))
        {
        waaayy:
          fputs ("waaayyy too many open files (amazing you were able to do this!)\n", stderr);
          exit (2);
        }

      new_table = (struct taql__file *)malloc (new_file_table_size * sizeof (struct taql__file));
      if (!new_table)
        goto waaayy;

      memcpy (new_table, taql__file_table, sizeof (struct taql__file) * taql__file_table_size);
      for (x = taql__file_table_size; x < (new_file_table_size - 1); ++x)
        {
          new_table[x]._next_free_file = x + 1;
        }
      new_table[x]._next_free_file = -1;
      taql__free_file = taql__file_table_size;
      taql__file_table_size = new_file_table_size;
      free ((void *)taql__file_table);
      taql__file_table = new_table;
      goto start_over;
    }

  memset ((void *)&taql__file_table[answer], 0, sizeof (taql__file_table[answer]));
  taql__file_table[answer]._next_free_file = answer;
  
  return answer;
}

static void
taql__unallocate_file (const char * file, size_t line, size_t stream)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);

  memset ((void *)f, 0, sizeof (*f));
  f->_next_free_file = taql__free_file;
  taql__free_file = stream;
}


void
taql__file_add_field (const char * file,
                      size_t line,
                      size_t stream,
                      enum taql_type_tag type,
                      t_taql_sym name)
{
  (void)taql__memtable_add_field (file,
                                  line,
                                  &(taql__file_table_ref (file, line, stream)->_memtable),
                                  type,
                                  name);
}


void
taql__file_add_param (const char * file,
                      size_t line,
                      size_t stream,
                      t_taql_sym name,
                      t_taql_boxed value)
{
  (void)taql__memtable_add_param (file,
                                  line,
                                  &(taql__file_table_ref (file, line, stream)->_memtable),
                                  name,
                                  value);
}





void
taql__file_fix_headers (const char * file,
                        size_t line,
                        size_t stream,
                        size_t n_ahead,
                        size_t buffer_suggested)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);
  if (f->_is_output_p)
    taql__file_fix_outputting_header (file, line,
                                      stream,
                                      n_ahead,
                                      buffer_suggested);
  else
    taql__file_fix_from_header (file, line,
                                stream,
                                n_ahead,
                                buffer_suggested); 
}


void
taql__file_fix_outputting_header (const char * file,
                                  size_t line,
                                  size_t stream,
                                  size_t n_ahead,
                                  size_t buffer_suggested)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);

  taql__file_fix (file, line, stream, n_ahead, buffer_suggested);
  taql__write_output_file_header (file, line, f);
}



void
taql__file_fix_from_header (const char * file,
                            size_t line,
                            size_t stream,
                            size_t n_ahead,
                            size_t buffer_suggested)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);
  struct taql__memtable * m = &f->_memtable;
  char buf[1 << 13];
  size_t amt_read;
  size_t pos;
  int has_comment;

  if (taql__memtable_is_fixed (file, line, m))
    taql__fatal (file, line, "fixing fixed file");

  if (taql__memtable_n_fields (file, line, m))
    taql__fatal (file, line, "fixing file with fields from headers");

  amt_read = read__retry (file, line, f->_stream, buf, sizeof (buf));
  pos = 0;

  if (!lex__match (&pos, buf, amt_read, "#: taql-0.1\n"))
    taql__fatal (file, line, "input missing magic number");


  has_comment = 0;

  while (pos < amt_read)
    {
      if (lex__match (&pos, buf, amt_read, "#.\n"))
        break;

      if (lex__match (&pos, buf, amt_read, "#-\n# "))
        {
          has_comment = 1;
          break;
        }

      if (!lex__match (&pos, buf, amt_read, "#"))
        {
        bogus_header:
          taql__fatal (file, line, "bogus input header");
        }

      (void)lex__skip_blanks (&pos, buf, amt_read);

      if (lex__match (&pos, buf, amt_read, "\n"))
        continue;

      if (lex__match (&pos, buf, amt_read, "field"))
        {
          char name_lexeme[257];
          char type_lexeme[257];
          t_taql_boxed name;
          t_taql_boxed type;
          
          if (!lex__skip_blanks (&pos, buf, amt_read))
            goto bogus_header;

          if (!lex__lexeme (name_lexeme, &pos, buf, amt_read))
            goto bogus_header;

          if (!lex__skip_blanks (&pos, buf, amt_read))
            goto bogus_header;

          if (!lex__lexeme (type_lexeme, &pos, buf, amt_read))
            goto bogus_header;

          (void)lex__skip_blanks (&pos, buf, amt_read);

          if (!lex__match (&pos, buf, amt_read, "\n"))
            goto bogus_header;

          name = taql__lex (file, line, name_lexeme);
          type = taql__lex (file, line, type_lexeme);

          taql__file_add_field (file, line,
                                stream,
                                taql__unbox_to_type_tag (file, line, type),
                                taql__unbox_sym (file, line, name));
        }
      else if (lex__match (&pos, buf, amt_read, "param"))
        {
          char name_lexeme[257];
          char value_lexeme[257];
          t_taql_boxed name;
          t_taql_boxed value;
          
          if (!lex__skip_blanks (&pos, buf, amt_read))
            goto bogus_header;

          if (!lex__lexeme (name_lexeme, &pos, buf, amt_read))
            goto bogus_header;

          if (!lex__skip_blanks (&pos, buf, amt_read))
            goto bogus_header;

          if (!lex__lexeme (value_lexeme, &pos, buf, amt_read))
            goto bogus_header;

          (void)lex__skip_blanks (&pos, buf, amt_read);

          if (!lex__match (&pos, buf, amt_read, "\n"))
            goto bogus_header;

          name = taql__lex (file, line, name_lexeme);
          value = taql__lex (file, line, value_lexeme);

          taql__file_add_param (file, line,
                                stream,
                                taql__unbox_sym (file, line, name),
                                value);
        }
      else
        goto bogus_header;
    }

  if (has_comment)
    {
      size_t starts;
      size_t ends;

      starts = ends = pos;

      while (pos < amt_read)
        {
          if (buf[pos] != '\n')
            {
              buf[ends] = buf[pos];
              ++ends;
              ++pos;
            }
          else
            {
              ++pos;
              if (lex__match (&pos, buf, amt_read, "# "))
                {
                  buf[ends] = '\n';
                  ++ends;
                  continue;
                }
              else if (lex__match (&pos, buf, amt_read, "#.\n"))
                {
                  buf[ends] = 0;
                  ++ends;
                  taql__memtable_set_comment (file, line, &f->_memtable, buf + starts);
                  break;
                }
              else 
                goto bogus_header;
            }
        }
    }

  taql__file_fix (file, line, stream, n_ahead, buffer_suggested);

  taql__file_extend_with (file, line, f, buf + pos, (amt_read - pos));

  (void)taql__file_n_ahead (file, line, stream);
}




void
taql__file_fix (const char * file,
                size_t line,
                size_t stream,
                size_t n_ahead,
                size_t buffer_suggested)
{
  struct taql__file * f;
  size_t sizeof_record;
  size_t buffer_needed;
  size_t buffer_wanted;

  f = taql__file_table_ref (file, line, stream);

  if (taql__memtable_is_fixed (file, line, &f->_memtable))
    taql__fatal (file, line, "fixing fixed file");

  sizeof_record = taql__memtable_sizeof_record (file, line, &f->_memtable);

  if ((n_ahead == 0) && (!f->_is_output_p))
    {
      struct stat stat_buf;

      if (fstat (f->_stream, &stat_buf))
        taql__fatal (file, line, "error calling stat(2)");

      if (!S_ISREG (stat_buf.st_mode))
        taql__fatal (file, line, "regular file expected");

      n_ahead = ((stat_buf.st_size + (sizeof_record - 1)) / sizeof_record);
    }
  
  f->_n_ahead = n_ahead;
  
  
  buffer_needed = (n_ahead * sizeof_record);
  
  if (buffer_suggested >= buffer_needed)
    {
      buffer_wanted = buffer_suggested;
    }
  else
    {
      buffer_wanted = ((buffer_needed < (1UL << 16))
                       ? (buffer_needed * 2)
                       : (buffer_needed * 2));
    }
  
  if (buffer_wanted & ((1 << 13) - 1))
    {
      size_t x;

      x = ((buffer_wanted + ((1 << 13) - 1)) & ~(size_t)((1 << 13) - 1));
      if (x > buffer_wanted)
        buffer_wanted = x;
    }
  
  taql__memtable_set_memsize (file, line, &f->_memtable, buffer_wanted);
  taql__memtable_fix (file, line, &f->_memtable);
  
  if (f->_is_output_p)
    taql__memtable_clear_fill (file, line, &f->_memtable);
}



static void
write__retry (const char * file,
              size_t line,
              int fd,
              const char * buf,
              size_t amt)
{
  size_t total = 0;

  while (total < amt)
    {
      ssize_t got = write (fd, buf + total, (amt - total));

      if (got < 0)
        taql__fatal (file, line, "output error");

      total += got;
    }
}



static ssize_t
read__retry (const char * file,
             size_t line,
             int fd,
             char * buf,
             size_t amt)
{
  size_t total = 0;

  while (total < amt)
    {
      ssize_t did = read (fd, buf + total, (amt - total));

      if (did < 0)
        taql__fatal (file, line, "input error");

      total += did;

      if (did == 0)
        return total;
    }

  return total;
}

static void
taql__write_output_file_header (const char * file,
                                size_t line,
                                struct taql__file * f)
{
  char buffer[8192];
  int bufpos;
  int field;
  int param;

  if (f->_stream < 0)
    return;

  buffer[0] = 0;
  bufpos = 0;

  strcpy (buffer + bufpos, "#: taql-0.1\n");
  bufpos += strlen (buffer + bufpos);

  for (field = 0;
       field < taql__memtable_n_fields (file, line, &f->_memtable);
       ++field)
    {
      if ((sizeof (buffer) - bufpos) < 1024)
        {
          write__retry (file, line, f->_stream, buffer, bufpos);
          buffer[0] = 0;
          bufpos = 0;
        }

      strcpy (buffer + bufpos, "# field ");
      bufpos += strlen (buffer + bufpos);

      taql__fmt (file, line,
                 buffer + bufpos,
                 sizeof (buffer) - bufpos,
                 (taql_box_sym
                  (taql__memtable_field_name (file, line,
                                              &f->_memtable,
                                              field))));
      bufpos += strlen (buffer + bufpos);

      strcpy (buffer + bufpos, " \"");
      bufpos += strlen (buffer + bufpos);

      strcpy (buffer + bufpos,
              taql__type_tag_name (file, line,
                                   taql__memtable_field_type (file, line,
                                                              &f->_memtable,
                                                              field)));
      bufpos += strlen (buffer + bufpos);

      strcpy (buffer + bufpos, "\"\n");
      bufpos += strlen (buffer + bufpos);
    }

  for (param = 0;
       param < taql__memtable_n_params (file, line, &f->_memtable);
       ++param)
    {
      if ((sizeof (buffer) - bufpos) < 1024)
        {
          write__retry (file, line, f->_stream, buffer, bufpos);
          buffer[0] = 0;
          bufpos = 0;
        }

      strcpy (buffer + bufpos, "# param ");
      bufpos += strlen (buffer + bufpos);

      taql__fmt (file, line,
                 buffer + bufpos,
                 sizeof (buffer) - bufpos,
                 (taql_box_sym
                  (taql__memtable_param_name (file, line,
                                              &f->_memtable,
                                              param))));
      bufpos += strlen (buffer + bufpos);

      strcpy (buffer + bufpos, " ");
      bufpos += strlen (buffer + bufpos);

      taql__fmt (file, line,
                 buffer + bufpos,
                 sizeof (buffer) - bufpos,
                 taql__memtable_param_value (file, line, &f->_memtable, param));
      bufpos += strlen (buffer + bufpos);

      strcpy (buffer + bufpos, "\n");
      bufpos += strlen (buffer + bufpos);
    }

  if (*taql__memtable_comment (file, line, &f->_memtable))
    {
      const char * cmnt = taql__memtable_comment (file, line, &f->_memtable);


      write__retry (file, line, f->_stream, buffer, bufpos);
      buffer[0] = 0;
      bufpos = 0;

      write (f->_stream, "#-\n# ", 5);
      while (*cmnt)
        {
          if (*cmnt != '\n')
            write (f->_stream, cmnt, 1);
          else
            write (f->_stream, "\n# ", 3);
          ++cmnt;
        }
      write (f->_stream, "\n", 1);
    }

  strcpy (buffer + bufpos, "#.\n");
  bufpos += strlen (buffer + bufpos);

  write__retry (file, line, f->_stream, buffer, bufpos);

  f->_file_byte_offset = bufpos;
}


static int
lex__match (size_t * pos,
            char * buf,
            size_t len,
            char * lexeme)
{
  size_t p;
  char * l;

  p = *pos;
  l = lexeme;

  while ((p < len) && *l)
    {
      if (buf[p] != *l)
        return 0;
      ++p;
      ++l;
    }

  if (*l)
    return 0;

  *pos = p;
  return 1;
}


static int
lex__skip_blanks (size_t * pos, char * buf, size_t len)
{
  size_t n;

  n = 0;

  while ((*pos < len) &&
         ((buf[*pos] == ' ') || (buf[*pos] == '\t')))
    {
      ++*pos;
      ++n;
    }

  return n;
}


static int
lex__lexeme (char * lexeme,
             size_t * pos,
             char * buf,
             size_t len)
{
  size_t p;
  size_t amt;

  p = *pos;

  if (p >= len)
    return 0;

  if (buf[p] == '"')
    {
      ++p;
      while (p < len)
        {
          if (buf[p] == '\\')
            {
              p += 2;
              if (p >= len)
                return 0;
            }
          else if (buf[p] == '"')
            {
              ++p;
              goto found_extent;
            }
          else
            ++p;
        }
      return 0;
    }
  else
    {
      while ((p < len) && !isspace (buf[p]))
        ++p;
    }


 found_extent:

  if ((p - *pos) >= 255)
    return 0;

  memcpy ((void *)lexeme, (void *)((char *)buf + *pos), (p - *pos));
  lexeme[(p - *pos)] = 0;

  amt = (p - *pos);
  *pos = p;
  return amt;
}






static void
taql__file_extend_buffer (const char * file,
                          size_t line,
                          struct taql__file * f)
{
  if (f->_is_output_p)
    taql__file_extend_output_buffer (file, line, f);
  else
    return taql__file_extend_input_buffer (file, line, f);
}


static void
taql__file_extend_output_buffer (const char * file,
                                 size_t line,
                                 struct taql__file * f)
{
  struct taql__memtable * m = &f->_memtable;
  void * buf;
  void * crsr;

  buf = taql__memtable_buffer (file, line, m);
  
  crsr = ((void *)
          (  (char *)buf

           + (  taql__memtable_sizeof_record (file, line, m)
              * taql__memtable_cursor (file, line, m))));
  

  if (f->_stream >= 0)
    {
      write__retry (file, line, f->_stream, buf, crsr - buf);
    }

  f->_file_byte_offset += (crsr - buf);

  f->_file_record_offset += taql__memtable_cursor (file, line, m);
  taql__memtable_shift (file, line, m, 1);
}


static void
taql__file_extend_input_buffer (const char * file,
                                size_t line,
                                struct taql__file * f)
{
  struct taql__memtable * m = &f->_memtable;

  f->_file_record_offset += taql__memtable_cursor (file, line, m);
  taql__memtable_shift (file, line, m, 0);

  if (f->_stream >= 0)
    {
      void * buf;
      size_t bufsize;
      size_t fillptr;
      size_t room;
      void * where;

      buf = taql__memtable_buffer (file, line, m);
      fillptr = taql__memtable_fillptr (file, line, m);
      bufsize = taql__memtable_buffer_size (file, line, m);
      room = (bufsize - fillptr);
      where = ((char *)buf + fillptr);
  
      if (room)
        {
          size_t got;

          got = read__retry (file, line, f->_stream, where, room);
          taql__memtable_fill_n (file, line, m, got);
          f->_file_byte_offset += got;
        }
    }

}


static void
taql__file_extend_with (const char * file,
                        size_t line,
                        struct taql__file * f,
                        const char * input,
                        size_t amt)
{
  struct taql__memtable * m = &f->_memtable;

  if (f->_is_output_p)
    taql__fatal (file, line, "output file abuse error");

  taql__memtable_shift (file, line, m, 0);

  {
    void * buf;
    size_t bufsize;
    size_t fillptr;
    size_t room;
    void * where;

    buf = taql__memtable_buffer (file, line, m);
    fillptr = taql__memtable_fillptr (file, line, m);
    bufsize = taql__memtable_buffer_size (file, line, m);
    room = (bufsize - fillptr);
    where = ((char *)buf + fillptr);
  
    if (room < amt)
      taql__fatal (file, line, "input buffer overflow");

    memcpy (where, input, amt);
    taql__memtable_fill_n (file, line, m, amt);
  }
}





size_t
taql__file_n_ahead (const char * file,
                    size_t line,
                    size_t stream)
{
  struct taql__file * f;
  size_t have_n_ahead;
  size_t want_n_ahead;

  f = taql__file_table_ref (file, line, stream);

  have_n_ahead = taql__memtable_n_ahead (file, line, &f->_memtable);
  want_n_ahead = f->_n_ahead;

  if (want_n_ahead > have_n_ahead)
    {
      taql__file_extend_buffer (file, line, f);
    }

  return taql__memtable_n_ahead (file, line, &f->_memtable);
}



size_t
taql__file_advance_cursor (const char * file,
                           size_t line,
                           size_t stream,
                           size_t n_rows)
{
  struct taql__file * f;
  struct taql__memtable * m;

  f = taql__file_table_ref (file, line, stream);
  m = &f->_memtable;

  while (1)
    {
      size_t n_ahead = taql__file_n_ahead (file, line, stream);

      if (n_ahead >= n_rows)
        break;

      if (!n_ahead)
        taql__fatal (file, line, "out of input");

      taql__memtable_advance_cursor (file, line, m, n_ahead);
      n_rows -= n_ahead;
    }

  taql__memtable_advance_cursor (file, line, m, n_rows);
  return taql__file_n_ahead (file, line, stream);
}


void
taql__file_add_to_comment (const char * file, size_t line,
                           size_t stream,
                           int c)
{
  taql__memtable_add_to_comment (file, line,
                                 &taql__file_table_ref (file, line,
                                                        stream)->_memtable,
                                 c);
}


size_t
taql__file_field_pos (const char * file, size_t line,
                      size_t stream,
                      t_taql_sym name)
{
  return taql__memtable_field_pos (file, line, stream,
                                   &taql__file_table_ref (file, line,
                                                          stream)->_memtable,
                                   name);
}


size_t
taql__file_recno (const char * file, size_t line, size_t stream)
{
  struct taql__file * f = taql__file_table_ref (file, line, stream);
  struct taql__memtable * m = &f->_memtable;

  return (taql__memtable_cursor (file, line, m) + f->_file_record_offset);
}




/* 
   get/set/advance/close;
   
   input file opener;
   schema parser;
   input file foo;
   */




     
void
taql__fprint (char * file, size_t line, FILE * stream, t_taql_boxed b)
{
  char buf[256];
  taql__fmt (file, line, buf, sizeof (buf), b);
  if (strlen (buf) != fwrite (buf, 1, strlen (buf), stream))
    {
      fputs ("output error\n", stderr);
      exit (2);
    }
}



enum taql_type_tag
taql__unbox_to_type_tag (const char * file, size_t line, t_taql_boxed b)
{
  char buf[9];
  enum taql_type_tag type;

  taql__unpack_sym (buf, taql__unbox_sym (file, line, b));

  if (!taql__lex_typename (&type, buf))
    taql__fatal (file, line, "unrecognized type name");
  
  return type;
}







/* arch-tag: Thomas Lord Thu Oct 26 13:59:30 2006 (libtaql/kernel.c)
 */



