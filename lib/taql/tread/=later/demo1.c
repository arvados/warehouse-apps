#include "libtaql/taql.h"


void
begin (int argc, const char * argv[])
{
  size_t input;
  size_t n_fields;
  size_t n_params;

  input = Infile ("-");

  File_fix (input, 10, 0);

  n_params = N_params (input);
  {
    size_t x;
    for (x = 0; x < n_params; ++x)
      {
        fputs ("param ", stdout);
        Fprint (stdout, taql_box_sym (Param_name (input, x)));
        fputs (" ", stdout);
        Fprint (stdout, Param_value (input, x));
        fputs ("\n", stdout);
      }
  }

  fputs ("\f\n", stdout);

  {
    const char * cmnt = Comment (input);

    if (cmnt)
      {
        fputs ("comment:\n", stdout);
        fwrite (cmnt, 1, strlen (cmnt), stdout);
        fputs ("\n", stdout);
      }
  }

  fputs ("\f\n", stdout);

  n_fields = N_fields (input);
  while (N_ahead (input))
    {
      size_t x;

      for (x = 0; x < n_fields; ++x)
        {
          if (x)
            putchar (' ');
          Fprint (stdout, Peek (input, 0, x));
        }
      putchar ('\n');
      Advance (input, 1);
    }
}



/* arch-tag: Thomas Lord Sat Oct 28 12:45:34 2006 (libtaql/demo1.c)
 */

