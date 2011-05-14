/* lexer.lex: 
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
#include "taql/mers/mer-utils.ch"
#define YYSTYPE t_taql_boxed
#include "gread.h"
extern void yyerror (const char *);
%}


%option yylineno
%option noyywrap

%x comment

NUMBER  [-+]?[0-9]+(\.[0-9]*)?(e[0-9]+(\.[0-9]*)?)?(#(u?int(4|8|32|64)|[sd]float))?


MER  [AaCcMmGgRrSsVvTtWwYyHhKkDdBbNn]{1,16}|\.


SYM   ["][^"]*["]

%%

<INITIAL>"#: taql-0.1/text\n"	{ return MAGIC; }
<INITIAL>"#"			{ return ATTENTION; }
<INITIAL>"field"		{ return FIELD; }
<INITIAL>"param"		{ return PARAM; }
<INITIAL>"#-\n# "		{ BEGIN(comment); return COMMENT; }
<INITIAL>"#-\n#.\n"		{ BEGIN(INITIAL); return END_OF_HEADER; }
<INITIAL,comment>"#.\n"         { BEGIN(INITIAL); return END_OF_HEADER; }
<INITIAL>{NUMBER}		{
                                  yylval = Lex (yytext);
                                  return VALUE;
                                }
<INITIAL>{MER}			{
				  yylval = uInt64 (ascii_to_mer (yytext));
                                  return VALUE;
                                }
<INITIAL>{SYM}			{
 
                                  yylval = Lex (yytext);
                                  return VALUE;
                                }
<comment>.			{
 
                                  yylval = Int32 ((int)yytext[0]);
                                  return COMMENT_CHAR;
                                }

<comment>"\n# "			{
                                  yylval = Int32 ((int)'\n');
                                  return COMMENT_CHAR;
                                }

<INITIAL>[ \t]+ 		{}


<INITIAL>"\n"			{ return END_OF_RECORD; }

<INITIAL>.			{ yyerror ("bogus lexeme"); }

<INITIAL><<EOF>>		{ return END_OF_FILE; }

%%

/* arch-tag: Thomas Lord Wed Jan 24 10:56:37 2007 (gread/lexer.lex)
 */

