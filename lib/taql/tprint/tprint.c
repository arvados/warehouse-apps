#include "libtaql/taql.h"


void
begin (int argc, const char * argv[])
{
  size_t infile;
  size_t n_fields;
  size_t field;
  size_t n_params;
  size_t param;
  const char * comment;

  infile = Infile ("-");
  File_fix (infile, 1, 0);

  puts ("#: taql-0.1/text");

  n_fields = N_fields (infile);
  for (field = 0; field < n_fields; ++field)
    {
      fputs ("# field ", stdout);
      Fprint (stdout, Field_name (infile, field));
      fputs (" ", stdout);
      Fprint (stdout, Field_type (infile, field));
      fputc ('\n', stdout);
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
          if (field)
            fputc (' ', stdout);
          Fprint (stdout, Peek (infile, 0, field));
        }
      fputc ('\n', stdout);
      Advance (infile, 1);
    }
}


/* arch-tag: Thomas Lord Fri Nov  3 23:25:19 2006 (tprint/tprint.c)
 */

