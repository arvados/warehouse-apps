/* gread.y: 
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



%{

#include "libtaql/taql.h"

extern int yylex (void);
void yyerror (char const * s);

#define YYSTYPE t_taql_boxed

size_t output = 0;

size_t column = 0;

%}

%token MAGIC
%token ATTENTION
%token FIELD
%token PARAM
%token COMMENT
%token COMMENT_CHAR
%token END_OF_HEADER
%token END_OF_RECORD
%token END_OF_FILE
%token VALUE

%%

taql_stream: MAGIC fields_and_params comment_or_eoh records END_OF_FILE  { YYACCEPT; } ; 

fields_and_params: /* empty */
                 | fields_and_params1
                 ;

fields_and_params1: field_or_param
                  | fields_and_params1 field_or_param
                  ;

field_or_param: field
              | param
              | noop
              ;

field: ATTENTION FIELD VALUE VALUE END_OF_RECORD { Add_field (output, $4, $3); } ;

param: ATTENTION PARAM VALUE VALUE END_OF_RECORD { Add_param (output, $3, $4); } ;

noop: ATTENTION END_OF_RECORD ;

comment_or_eoh: comment_or_eoh1 { File_fix (output, 1, 0); } ;

comment_or_eoh1: comment
               | END_OF_HEADER
               ;

comment: COMMENT comment_characters END_OF_HEADER ;

comment_characters: /* empty */
                  | comment_characters1
                  ;

comment_characters1: comment_char
                   | comment_characters1 comment_char
                   ;

comment_char: COMMENT_CHAR { Add_to_comment (output, as_Int32 (yylval)); } ;

records: /* empty */
       | records1
       ; 

records1: record
        | records1 record
        ;


record: end_of_record
      | record1 end_of_record
      ;

end_of_record: END_OF_RECORD
               {
                 Advance (output, 1);
                 column = 0;
               }
             ;

record1: value
       | record1 value
       ;

value: VALUE
       {
         Poke (output, 0, column, $1);
         ++column;
       }
     ;


%%

void
yyerror (char const * s)
{
  Fatal (s);
}


void
begin (int argc, const char * argv[])
{
  output = Outfile ("-");

  if (yyparse ())
    {
      Fatal ("syntax error in input");
    }

  Close (output);
}


/* arch-tag: Thomas Lord Wed Jan 24 10:55:54 2007 (gread/gread.y)
 */

