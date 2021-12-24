%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror (char const *);
extern int yylineno;

char m[128];  // message information
FILE *file;

int indent = 0;
char* tabs() 
{
	char *fmt = malloc(indent + 1);
	strcpy(fmt, indent == 0 ? "" : "\t");

	for (int i = 1; i < indent; i++)
		strcat(fmt, "\t");

	return fmt; 
}

int in_loop = 0;
int in_function = 0;
int open_else = 0;

const int INCLUDE_STATE = 0, IFDEF_STATE = 1, ENDIF_STATE = 11, DEFINE_STATE = 2, FUNCTION_STATE = 3, DECLARATION_STATE = 4,
	EXPRESSION_STATE = 5, RETURN_STATE = 6, STRUCTURE_STATE = 7, COMMENT_STATE = 8;
int old_state = -1, current_state = -1;

void addLine()
{
	if (old_state == -1 || old_state == COMMENT_STATE || old_state == IFDEF_STATE)
		return;

	if (current_state == IFDEF_STATE || current_state == FUNCTION_STATE || current_state == STRUCTURE_STATE)
		fprintf(file, "\n");

	else if (current_state != old_state)
		fprintf(file, "\n");	
}

%}

/*****************************************************************************/

%union
{
	char *valString;
}

%error-verbose

/*****************************************************************************/

%token END 0

%token <valString> HASH INCLUDE FILENAME IFDEF IFNDEF ENDIF DEFINE
%token <valString> TYPE ID STRINGV NUMERICV 
%token VOID
%token SEMICOLON COMMA 
%token LPAR RPAR LBRACE RBRACE LBRACK RBRACK

%token IF ELSE
%token DO WHILE FOR BREAK CONTINUE
%token MAIN RETURN 

%token <valString> INCR
%token EQ

%token <valString> OP_EQ
%token PLUS MINUS MULT DIV MOD 
%token EQ_EQ NOT_EQ LT GT LT_EQ GT_EQ
%token NOT LOGIC_AND LOGIC_OR
%token OR AND XOR COMPL 
%token LSHIFT RSHIFT 
%token QUESTION COLON
%token DOT ARROW

%token <valString> SCOMMENT MCOMMENT

%token <valString> UNDEFINED NEW_LINE

/*****************************************************************************/

%type main main_header

%type ifdef_header

%type function_declaration function_definition function_definition2
%type <valString> function_args args functionv

%type <valString> id vars var
%type <valString> pointers arrayt arrayv

%type const_statements const_statement
%type statements statement statement2 statement3

%type <valString> expr

%type <valString> if else if_header else_header if_statement

%type <valString> for for_header for_var empty_expr
%type <valString> while while_header
%type <valString> do_while do_header

%type new_line lbrace new_line_else lbrace_else

/*****************************************************************************/

%left COMMA
%right EQ OP_EQ
%right QUESTION COLON
%left LOGIC_OR
%left LOGIC_AND
%left OR
%left XOR
%left AND
%left EQ_EQ NOT_EQ
%left LT GT LT_EQ GT_EQ
%left LSHIFT RSHIFT
%left PLUS MINUS
%left MULT DIV MOD
%right NOT COMPL
%left INCR DOT ARROW

/*****************************************************************************/

%start S

/*****************************************************************************/

%%


S : 	
	  main END										{ printf("File formatted successfully.\n"); }
	| const_statements main END 					{ printf("File formatted successfully.\n"); }
	| main const_statements END 					{ printf("File formatted successfully.\n"); }
	| const_statements main const_statements END 	{ printf("File formatted successfully.\n"); }

	| const_statements error	{ yyerror("main function not found."); YYABORT; }
	| /* empty */				{ yyerror("main function not found."); YYABORT; }
;

main :
	main_header statements RBRACE 		{ old_state = FUNCTION_STATE; indent = 0; in_function--; fprintf(file, "}\n"); }
;

main_header : 
	  MAIN function_args LBRACE			{ current_state = FUNCTION_STATE; addLine(); fprintf(file, "void main%s\n{\n", $2);	  indent = 1; old_state = -1; in_function++; }
	| TYPE MAIN function_args LBRACE 	{ current_state = FUNCTION_STATE; addLine(); fprintf(file, "%s main%s\n{\n", $1, $3); indent = 1; old_state = -1; in_function++; }
	| VOID MAIN function_args LBRACE	{ current_state = FUNCTION_STATE; addLine(); fprintf(file, "void main%s\n{\n", $3);   indent = 1; old_state = -1; in_function++; }
;

function_declaration :
	  TYPE ID function_args SEMICOLON 	{ indent--; current_state = FUNCTION_STATE; addLine(); fprintf(file, "%s %s%s;\n", $1, $2, $3); }
	| VOID ID function_args SEMICOLON	{ indent--; current_state = FUNCTION_STATE; addLine(); fprintf(file, "void %s%s;\n", $2, $3);}
;

function_definition : 
	function_definition2 statements RBRACE 	{ in_function--; indent--; fprintf(file, "}\n"); }
;

function_definition2 :
	  TYPE ID function_args LBRACE		
	  	{ 
			current_state = FUNCTION_STATE; addLine(); 
			fprintf(file, "%s %s%s\n{\n", $1, $2, $3);
			old_state = -1; in_function++; 
		}
	| VOID ID function_args LBRACE		
		{ 
			current_state = FUNCTION_STATE; 
			addLine(); 
			fprintf(file, "void %s%s\n{\n", $2, $3);
			old_state = -1; in_function++;
		}

	| ID function_args LBRACE
		{ 
			current_state = FUNCTION_STATE; 
			addLine(); 
			fprintf(file, "void %s%s\n{\n", $1, $2);
			old_state = -1; in_function++;
		}
;

function_args :
	  LPAR RPAR			{ $$ = malloc(4); strcpy($$, "()"); indent++; }
	| LPAR VOID RPAR 	{ $$ = malloc(8); strcpy($$, "(void)"); indent++; }
	| LPAR args RPAR 	{ $$ = malloc(strlen($2) + 4); sprintf($$, "(%s)", $2); indent++; }
;

args : 
	  TYPE id				{ $$ = malloc(strlen($1) + strlen($2) + 2); sprintf($$, "%s %s", $1, $2); }
	| args COMMA TYPE id 	{ $$ = malloc(strlen($1) + strlen($3) + strlen($4) + 4); sprintf($$, "%s, %s %s", $1, $3, $4); }	
;

functionv :
	  ID LPAR expr RPAR	{ $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s(%s)", $1, $3); }
	| ID LPAR RPAR		{ $$ = malloc(strlen($1) + 3); sprintf($$, "%s()", $1); }

	| ID LPAR error RPAR	{ yyerror("expected an expression."); YYABORT; }
;

id :
	  ID				 { $$ = $1; }
	| ID arrayt 		 { $$ = malloc(strlen($1) + strlen($2) + 1); sprintf($$, "%s%s", $1, $2); }
	| pointers ID		 { $$ = malloc(strlen($1) + strlen($2) + 1); sprintf($$, "%s%s", $1, $2); }
	| pointers ID arrayt { $$ = malloc(strlen($1) + strlen($2) + strlen($3) + 1); sprintf($$, "%s%s%s", $1, $2, $3); }
;

vars :
	  var  				{ $$ = $1; }
	| vars COMMA var	{ $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s, %s", $1, $3); }
;

var :
	  id			{ $$ = $1; }
	| id EQ expr		{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s = %s", $1, $3); }
	| id EQ arrayv	{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s = %s", $1, $3); }

	| id EQ error	{ yyerror("expected an expression."); YYABORT; }
;

pointers :
	  MULT			{ $$ = malloc(2); strcpy($$, "*"); }
	| pointers MULT	{ $$ = malloc(strlen($1) + 1); sprintf($$, "%s*", $1); }
;

arrayt :
	  LBRACK RBRACK				{ $$ = malloc(3); strcpy($$, "[]"); }
	| LBRACK expr RBRACK		{  $$ = malloc(strlen($2) + 3); sprintf($$, "[%s]", $2); }
	| arrayt LBRACK expr RBRACK	{  $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s[%s]", $1, $3);}

	| LBRACK error RBRACK 		{ yyerror("expected an expression;\n"); YYABORT; }
;

arrayv :
	  LBRACE expr RBRACE	{ $$ = malloc(strlen($2) + 5); sprintf($$, "{ %s }", $2); }
	| LBRACE arrayv RBRACE	{ $$ = malloc(strlen($2) + 5); sprintf($$, "{ %s }", $2); }
	| arrayv COMMA arrayv	{ $$ = malloc(strlen($1) + strlen($3) + 7); sprintf($$, "%s, %s", $1, $3); }

	| LBRACE error RBRACE 	{ yyerror("expected an expression."); YYABORT; }
;

const_statements :
	  const_statement 					{ old_state = current_state; }
	| const_statements const_statement  { old_state = current_state; }
	| statement3						{ }
	| const_statements statement3 		{ }

	| if						{ yyerror("conditional structures not allowed outside a function."); YYABORT;}
	| const_statements if		{ yyerror("conditional structures not allowed outside a function."); YYABORT;}
	| for 						{ yyerror("loop structures not allowed outside a function."); YYABORT; }
	| const_statements for 		{ yyerror("loop structures not allowed outside a function."); YYABORT; }
	| while 					{ yyerror("loop structures not allowed outside a function."); YYABORT; }
	| const_statements while 	{ yyerror("loop structures not allowed outside a function."); YYABORT; }
	| do_while 					{ yyerror("loop structures not allowed outside a function."); YYABORT; }
	| const_statements do_while { yyerror("loop structures not allowed outside a function."); YYABORT; }
;

const_statement :
	  HASH INCLUDE FILENAME		{ current_state = INCLUDE_STATE; addLine(); fprintf(file, "#include %s\n", $3); }
	| HASH INCLUDE STRINGV 		{ current_state = INCLUDE_STATE; addLine(); fprintf(file, "#include %s\n", $3); }
	| HASH DEFINE ID NUMERICV 	{ current_state = DEFINE_STATE; addLine(); fprintf(file, "#define %s %s\n", $3, $4); }
	| HASH DEFINE ID STRINGV 	{ current_state = DEFINE_STATE; addLine(); fprintf(file, "#define %s %s\n", $3, $3); }

	| ifdef_header const_statements HASH ENDIF { current_state = ENDIF_STATE; fprintf(file, "#endif\n"); }

	| function_declaration 		{ current_state = FUNCTION_STATE; }
	| function_definition		{ current_state = FUNCTION_STATE; }

	| SCOMMENT					{ current_state = COMMENT_STATE; addLine(); fprintf(file, "%s\n", $1); }
	| MCOMMENT					{ current_state = COMMENT_STATE; addLine(); fprintf(file, "%s\n", $1); }

	| HASH error				{ yyerror("unrecognized preprocessing directive."); YYABORT; }
;

ifdef_header :
	  HASH IFDEF id		{ current_state = IFDEF_STATE; addLine(); fprintf(file, "#ifdef %s\n", $3); old_state = IFDEF_STATE; }
	| HASH IFNDEF id	{ current_state = IFDEF_STATE; addLine(); fprintf(file, "#ifndef %s\n", $3); old_state = IFDEF_STATE; }
;

statements : 
	  /* empty */ 			{  }
	| statements statement 	{ old_state = current_state; }
;

statement : 
	  statement2 	{ }
	| if_statement 	{ current_state = STRUCTURE_STATE; }

	| SCOMMENT		{ current_state = COMMENT_STATE; char* t = tabs(); addLine(); fprintf(file, "%s%s\n", t, $1); }
	| MCOMMENT		{ current_state = COMMENT_STATE; char* t = tabs(); addLine(); fprintf(file, "%s%s\n", t, $1); }
;

statement2 :
	  for 				{ current_state = STRUCTURE_STATE; in_loop--; }
	| while 			{ current_state = STRUCTURE_STATE; in_loop--; }
	| do_while 			{ current_state = STRUCTURE_STATE; in_loop--; }
	| statement3		{ }
;

statement3 :
	  SEMICOLON						
		{ 
			current_state = EXPRESSION_STATE; 
			char* t = tabs(); 
			addLine(); fprintf(file, "%s;\n", t); 
		}
	| simple_statement SEMICOLON	{ fprintf(file, ";\n"); }
	| simple_statement error		{ yyerror("';' expected."); YYABORT; }
	| error							{ yyerror("expected an expression."); YYABORT; }
;

simple_statement : 
	  TYPE vars 
		{ 	current_state = DECLARATION_STATE; 
			char* t = tabs(); 
			addLine(); fprintf(file, "%s%s %s", t, $1, $2); 
		}
	| expr 
			{ 	
				current_state = EXPRESSION_STATE;
				char* t = tabs(); 
				addLine(); fprintf(file, "%s%s", t, $1); 
			}
	
	| RETURN
		{ 	
			if (in_function == 0) 
			{
				yyerror("return statement may only be used within a function."); 
				YYABORT;
			}

			current_state = RETURN_STATE; 
			char* t = tabs(); 
			addLine(); fprintf(file, "%sreturn", t); 
		}
	| RETURN expr	
		{ 	
			if (in_function == 0) 
			{
				yyerror("return statement may only be used within a function."); 
				YYABORT;
			}

			current_state = RETURN_STATE;
			char* t = tabs(); 
			addLine(); fprintf(file, "%sreturn %s", t, $2); 
		}

	| BREAK		
		{ 
			if (in_loop == 0) 
			{
				yyerror("break statement may only be used within a loop."); 
				YYABORT;
			}

			current_state = EXPRESSION_STATE;
			char* t = tabs(); fprintf(file, "%sbreak", t); 
		}
	| CONTINUE	
		{ 
			if (in_loop == 0) 
			{
				yyerror("continue statement may only be used within a loop."); 
				YYABORT;
			}

			current_state = EXPRESSION_STATE;
			char* t = tabs(); fprintf(file, "%scontinue", t);
		}
;

expr :
	  ID							{ $$ = $1; }
	| NUMERICV						{ $$ = $1; }
	| STRINGV						{ $$ = $1; }
	| functionv						{ $$ = $1; }
	| LPAR expr RPAR				{ $$ = malloc(strlen($2) + 3); sprintf($$, "(%s)", $2); }

	| ID LBRACK expr RBRACK			{ $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s[%s]", $1, $3); }
	| INCR ID 						{ $$ = malloc(strlen($1) + strlen($2) + 1); sprintf($$, "%s%s", $1, $2); }
	| ID INCR 						{ $$ = malloc(strlen($1) + strlen($2) + 1); sprintf($$, "%s%s", $1, $2); }
	| ID DOT ID 					{ $$ = malloc(strlen($1) + strlen($3) + 2); sprintf($$, "%s.%s", $1, $3); }
	| ID ARROW ID					{ $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s->%s", $1, $3); }

	| PLUS expr 		%prec NOT	{ $$ = malloc(strlen($2) + 3); sprintf($$, "+%s", $2); }
	| MINUS expr 		%prec NOT	{ $$ = malloc(strlen($2) + 3); sprintf($$, "-%s", $2); }
	| AND expr			%prec NOT	{ $$ = malloc(strlen($2) + 3); sprintf($$, "&%s", $2); }
	| MULT expr 		%prec NOT	{ $$ = malloc(strlen($2) + 3); sprintf($$, "*%s", $2); }
	| NOT expr						{ $$ = malloc(strlen($2) + 3); sprintf($$, "!%s", $2); }
	| COMPL expr					{ $$ = malloc(strlen($2) + 3); sprintf($$, "~%s", $2); }

	| expr MULT expr				{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s * %s", $1, $3); }
	| expr DIV expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s / %s", $1, $3); }
	| expr MOD expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s %c %s", $1, '%', $3); }
	| expr PLUS expr				{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s + %s", $1, $3); }
	| expr MINUS expr				{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s - %s", $1, $3); }

	| expr LSHIFT expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s << %s", $1, $3); }
	| expr RSHIFT expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s >> %s", $1, $3); }

	| expr LT expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s < %s", $1, $3); }
	| expr GT expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s > %s", $1, $3); }
	| expr LT_EQ expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s <= %s", $1, $3); }
	| expr GT_EQ expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s >= %s", $1, $3); }

	| expr EQ_EQ expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s == %s", $1, $3); }
	| expr NOT_EQ expr				{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s != %s", $1, $3); }

	| expr AND expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s & %s", $1, $3); }

	| expr XOR expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s ^ %s", $1, $3); }
	
	| expr OR expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s | %s", $1, $3); }

	| expr LOGIC_AND expr			{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s && %s", $1, $3); }

	| expr LOGIC_OR expr			{ $$ = malloc(strlen($1) + strlen($3) + 5); sprintf($$, "%s || %s", $1, $3); }

	| expr QUESTION expr COLON expr	{ $$ = malloc(strlen($1) + strlen($3) + strlen($5) + 7); sprintf($$, "%s ? %s : %s", $1, $3, $5); }

	| expr EQ expr					{ $$ = malloc(strlen($1) + strlen($3) + 4); sprintf($$, "%s = %s", $1, $3); }
	| expr OP_EQ expr				{ $$ = malloc(strlen($1) + strlen($2) + strlen($3) + 5); sprintf($$, "%s %s %s", $1, $2, $3); }

	| expr COMMA expr				{ $$ = malloc(strlen($1) + strlen($3) + 3); sprintf($$, "%s, %s", $1, $3); }
;

if_statement :
	  if 		{ }
	| if else	{ }
;

if :
	  if_header new_line statement 			{ indent--; }
	| if_header lbrace statements RBRACE	{ indent--; char *t  = tabs(); fprintf(file, "%s}\n", t); }
;

else : 
	  else_header new_line_else statement2	{ open_else = 0; indent--; }
	| else_header if_statement 						{ open_else = 0; }
	| else_header lbrace_else statements RBRACE
		{
			indent--; 
			char *t = tabs(); fprintf(file, "%s}\n", t); 
		}
;

if_header :
	IF LPAR expr RPAR 
	{ 	
		current_state = STRUCTURE_STATE;

		char *t;
		if (open_else) 	{ t = ""; open_else = 0;} 
		else 			{ addLine(); t = tabs(); indent++; }

		fprintf(file, "%sif (%s)", t, $3); 

		old_state = -1;
	}

	| IF LPAR error RPAR	{ yyerror("if guard is not an expression."); YYABORT; }
	| IF error				{ yyerror("if guard must be between '(' ')'"); YYABORT; }
;

else_header :
	ELSE 
	{ 
		open_else = 1;
		char *t = tabs(); fprintf(file, "%selse ", t); 
		indent++; old_state = -1;
	}
;

lbrace_else :
	lbrace	{ open_else = 0; }
;

new_line_else :
	new_line	{ open_else = 0; }
;

for :
	  for_header new_line statement 	  	 { indent--; }
	| for_header lbrace statements RBRACE { indent--; char *t = tabs(); fprintf(file, "%s}\n", t); }
;

for_header :
	  FOR LPAR for_var SEMICOLON empty_expr SEMICOLON empty_expr RPAR
		{ 	
			current_state = STRUCTURE_STATE; addLine();
			char *t = tabs(); fprintf(file, "%sfor (%s; %s; %s)", t, $3, $5, $7); 
			indent++; old_state = -1; in_loop++;
		} 

	| FOR error	{ yyerror("for header must be between '(' ')'."); YYABORT; }
;

for_var :
	  TYPE vars		{ $$ = malloc(strlen($1) + strlen($2) + 2); sprintf($$, "%s %s", $1, $2); }
	| expr			{ $$ = $1; }
	| /* empty */	{ $$ = malloc(2); strcpy($$, " "); }
	| error			{ yyerror("expected a declaration or an expression."); YYABORT; }
;

empty_expr :
	  /* empty */	{ $$ = malloc(2); strcpy($$, " "); }
	| expr			{ $$ = $1; }
	| error			{ yyerror("expected an expression."); YYABORT; }
;

while : 
	  while_header new_line statement 		{ indent--; }
	| while_header lbrace statements RBRACE 	{ indent--; char *t = tabs(); fprintf(file, "%s}\n", t); }
;

while_header :
	WHILE LPAR expr RPAR
		{ 
			current_state = STRUCTURE_STATE; addLine();
			char *t = tabs(); fprintf(file, "%swhile (%s)", t, $3); 
			indent++; old_state = -1; in_loop++;
		}

	| WHILE LPAR error RPAR	{ yyerror("while guard is not an expression."); YYABORT; }
	| WHILE error			{ yyerror("while guard must be between '(' ')'"); YYABORT; }
;

do_while : 
	  do_header new_line statement WHILE LPAR expr RPAR SEMICOLON
	  	{ 
			indent--; char *t = tabs(); 
		  	fprintf(file, "%swhile (%s);\n", t, $6); 
		}
	| do_header lbrace statements RBRACE WHILE LPAR expr RPAR SEMICOLON
		{ 	
			indent--; char *t = tabs();  
			fprintf(file, "%s} while (%s);\n", t, $7); 
		}

	| do_header new_line statement WHILE LPAR error RPAR 	{ yyerror("while guard is not an expression."); YYABORT; }
	| do_header new_line statement WHILE error 				{ yyerror("while guard must be between '(' ')'"); YYABORT; }

	| do_header lbrace statements RBRACE WHILE LPAR error RPAR 	{ yyerror("while guard is not an expression."); YYABORT; }
	| do_header lbrace statements RBRACE WHILE error 			{ yyerror("while guard must be between '(' ')'"); YYABORT; }
;

do_header :
	  DO
		{ 
			current_state = STRUCTURE_STATE; addLine();
			char *t = tabs(); fprintf(file, "%sdo", t); 
			indent++; old_state = -1; in_loop++;
		}
;

lbrace :
	LBRACE	{ indent--; char *t = tabs(); fprintf(file, "\n%s{\n", t); indent++; }
;

new_line :
	/* empty */ { fprintf(file, "\n"); }
;

%%

/*****************************************************************************/

void execute()
{
	file = fopen("_output.c", "w");
	yyparse();
	fclose(file);
}

int main(int argc, char *argv[]) 
{

	extern FILE *yyin;

	switch (argc) {

		case 1:	
			yyin = stdin;
			execute();
			break;

		case 2: 
			yyin = fopen(argv[1], "r");
			if (yyin == NULL) 
			{
				printf("ERROR: No se ha podido abrir el fichero.\n");
			}
			else 
			{
				execute();
				fclose(yyin);
			}
			break;
			
		default: 
			printf("ERROR: Demasiados argumentos.\nSintaxis: %s [fichero_entrada]\n\n", argv[0]);
	}

	return 0;
}

void yyerror (char const *message) 
{ 
	if (strncmp(message, "syntax error", 12) != 0)
		fprintf (stderr, "[%d] Error: %s\n", yylineno, message);
}

