%{
#include <stdlib.h>
#include "prettier.tab.h"
#define yyterminate() return END
%}
%option yylineno

space [ \t]

alpha [a-zA-Z]
alphanum [a-zA-Z0-9]
id ({alpha}|_)+({alphanum}|_)*

symbols " "|"!"|"¡"|\"|"#"|"$"|"%"|"&"|"'"|"("|")"|"*"|"+"|","|"-"|"."|"/"|":"|";"|"<"|"="|">"|"?"|"¿"|"@"|"["|\\|"^"|"_"|"`"|"{"|"|"|"}"|"~"
filename    <({id}|{symbols})+>

charv       '.*'
intv        [0-9]+
floatv      [0-9]*"."[0-9]+f
exp         e("+"|"-")?[0-9]+
doublev     [0-9]+{exp}|[0-9]+"."[0-9]*{exp}f?
numericv    {charv}|{intv}|{floatv}|{doublev}
stringv     \"[^\"]*\"

type    char|int|long|float|double

op_assign ([\+\-\*\/\%\|\&\^]|"<<"|">>")=

line_comment "//"[^\n]*
mline_comment "/*"([^*]|("*"+[^*/]))*"*"*"*/"

%%

{filename}    { yylval.valString = strdup(yytext); return FILENAME; }
#             { return HASH; }
include       { return INCLUDE; }
ifdef         { return IFDEF; }
ifndef        { return IFNDEF; }
endif         { return ENDIF; }
define        { return DEFINE; }

if              { return IF; }
else            { return ELSE; }
do              { return DO; }
while           { return WHILE; }
for             { return FOR; }
break           { return BREAK; }
continue        { return CONTINUE; }
return          { return RETURN; }

{type}          { yylval.valString = strdup(yytext); return TYPE; }
{stringv}       { yylval.valString = strdup(yytext); return STRINGV; }
void            { return VOID; }
{numericv}      { yylval.valString = strdup(yytext); return NUMERICV; }

main            { return MAIN; }

{id}            { yylval.valString = strdup(yytext); return ID; }
{op_assign}     { yylval.valString = strdup(yytext); return OP_EQ; }

","             { return COMMA; }
";"             { return SEMICOLON;}
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"("             { return LPAR; }
")"             { return RPAR; }
"["             { return LBRACK; }
"]"             { return RBRACK; }

"++"|"--"       { yylval.valString = strdup(yytext); return INCR; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"%"             { return MOD; }


"="             { return EQ; }
"=="            { return EQ_EQ; }
"!="            { return NOT_EQ; }
"<"             { return LT; }
">"             { return GT; }
"!"             { return NOT; }
"<="            { return LT_EQ; }
">="            { return GT_EQ; }

"<<"            { return LSHIFT; }
">>"            { return RSHIFT; }

"&"             { return AND; }
"|"             { return OR; }
"~"             { return COMPL; }
"^"             { return XOR; }

"&&"            { return LOGIC_AND; }
"||"            { return LOGIC_OR; }

"?"             { return QUESTION; }
":"             { return COLON; }

"."             { return DOT; }
"->"            { return ARROW; }

{line_comment}  { yylval.valString = strdup(yytext); return SCOMMENT; }
{mline_comment} { yylval.valString = strdup(yytext); return MCOMMENT; }

[ \t\n]

.               { yylval.valString = strdup(yytext); return UNDEFINED; }

%%