#include "libtaql/taql.h"


void
begin (int argc, const char * argv[])
{
  int x;
  size_t output;

  output = Outfile ("-");

  Add_field (output, Sym ("int32"), Sym ("x"));
  Add_field (output, Sym ("int32"), Sym ("sqr"));
  Add_field (output, Sym ("sfloat"), Sym ("root"));
  Add_param (output, Sym ("foo"), Sym ("bar"));
  Set_comment (output, "this...\n   is...\n      a comment\n");

  File_fix (output, 10, 0);

  for (x = 1; x <= 10; ++x)
    {
      /*     table:   row:     col:   value: 
       */

      Poke ( output,  x - 1,   0,     Int32 (x)                   );
      Poke ( output,  x - 1,   1,     Int32 (x * x)               );
      Poke ( output,  x - 1,   2,     Sfloat (sqrt ((double)x))   );
    }

  Advance (output, x - 1);

  Close (output);
}



/* arch-tag: Thomas Lord Sat Oct 28 11:30:25 2006 (libtaql/main.c)
 */

