#include "libtaql/taql.h"
#include "taql/mers/mer-utils.ch"


void
begin (int argc, const char * argv[])
{
  size_t infile;
  size_t n_fields;
  size_t field;
  size_t n_params;
  size_t param;
  const char * comment;
  int mer_field[256] = {0, };

  infile = Infile ("-");
  File_fix (infile, 1, 0);

  puts ("#: taql-0.1/text");

  n_fields = N_fields (infile);
  for (field = 0; field < n_fields; ++field)
    {
      Taql name;
      Taql type;

      fputs ("# field ", stdout);
      name = Field_name (infile, field);
      Fprint (stdout, name);
      fputs (" ", stdout);
      type = Field_type (infile, field);
      Fprint (stdout, type);
      fputc ('\n', stdout);

      if (   Eq (type, Sym ("uint64"))
          && ('m' == Sym_ref(name, 0))
          && ('e' == Sym_ref(name, 1))
          && ('r' == Sym_ref(name, 2))
          && isdigit (Sym_ref(name, 3)))
        {
          mer_field[field] = 1;
        }
    }

  n_params = N_params (infile);
  for (param = 0; param < n_params; ++param)
    {
      fputs ("# param ", stdout);
      Fprint (stdout, Param_name (infile, param));
      fputs (" ", stdout);
      Fprint (stdout, Param_value (infile, param));
      fputc ('\n', stdout);
    }

  comment = Comment (infile);
  if (!comment || !comment[0])
    {
      fputs ("#.\n", stdout);
    }
  else
    {
      const char * c;
      fputs ("#-\n# ", stdout);

      for (c = comment; *c; ++c)
        {
          if (*c == '\n')
            fputs ("\n# ", stdout);
          else
            fputc (*c, stdout);
        }
      fputs ("\n#.\n", stdout);
    }

  while (N_ahead (infile))
    {
      for (field = 0; field < n_fields; ++field)
        {
          Taql value;

          if (field)
            fputc (' ', stdout);

          value = Peek (infile, 0, field);

          if (!mer_field [field])
            {
              Fprint (stdout, value);
            }
          else
            {
              t_taql_uint64 mer;
              char in_ascii[17];

              mer = as_uInt64 (value);
              mer_to_ascii (in_ascii, mer);
              fputs (in_ascii, stdout);
            }
        }
      fputc ('\n', stdout);
      Advance (infile, 1);
    }
}


/* arch-tag: Thomas Lord Mon Nov  6 09:54:40 2006 (gprint/gprint.c)
 */

