%{
    double mem[26]; /* Memory for 26 valiables, a - z*/
%}

%union              /* Stack Type */
{
    double  val;    /* Data type of values */
    int     index;  /* Data type of variables, which will be an index into array mem */
}

%token  <val>   NUMBER
%token  <index> VAR

%type   <val>   expr

%right  '='
%left   '+' '-' /* Left associative, lower precedence than below*/
%left   '*' '/' '%'
%left   UNARYMINUS UNARYPLUS

%%
    /* Start of the Grammar */

list:           /* Allow a blank line as input */
            |   list '\n'
            |   list expr '\n'      { printf("\t%.8g\n", $2); }
            |   list error '\n'     { yyerrok; }
            ;

expr:           NUMBER
            |   VAR                 { $$ = mem[$1]; }
            |   VAR '=' expr        { $$ = mem[$1] = $3; }
            |   '-' expr %prec UNARYMINUS   { $$ = -$2; }
            |   '+' expr %prec UNARYPLUS    { $$ = +$2; }
            |   expr '+' expr       { $$ = $1 + $3; }
            |   expr '-' expr       { $$ = $1 - $3; }
            |   expr '*' expr       { $$ = $1 * $3; }
            |   expr '/' expr       
                                    { 
                                        if($3 == 0.0)
                                            execerror("Attempted Division by zero", "");
                                        $$ = $1 / $3; 
                                    }
            |   expr '%' expr       { $$ = fmod($1,$3); }
            |   '(' expr ')'        { $$ = $2; }
            ;
%% 
    /* End of the Grammar */

#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <signal.h>
#include <setjmp.h>

jmp_buf begin;
char    *progname;
int     lineno = 1;

main(int argc, char *argv[])
{
    int fpecatch();

    progname = argv[0]; 
    setjmp(begin);  // Save stack position into begin
    signal(SIGFPE, fpecatch);   // Call fpecatch if floating point exception occurs
    yyparse();
}

execerror(char *s, char *t) // Invokes longjump with the stack position object saved earlier, giving us a clean slate on the stack after an FPE occurs
{
    warning(s,t);
    longjmp(begin, 0);
}

fpecatch()  // Invoked from signal when fpe occurs
{
    execerror("Floating point exception dawg", (char *) 0);
}

yylex()
{
    int c;

    while( (c = getchar()) == ' ' || c == '\t' )   /* Skip over blanks and tabs */
        ;

    if(c == EOF)
        return 0;

    if(c == '.' || isdigit(c))  /* If the character is a digit (or a dot in the middle of a float) */
    {
        ungetc(c, stdin);       /* Put it back on stdin stream */
        scanf("%lf", &yylval.val);  /* Read the value of the number from stdin to yylval, which is defined to be same as YYSTYPE*/
        return NUMBER;          /* Return the TYPE of the token, not the value, which is already stored in above variable*/
    }

    if(islower(c))  /* If the character is a lowercase letter, we return the ASCII value for that variable, which will be stored in the mem[26] memory array*/
    {
        yylval.index = c - 'a';
        return VAR;
    }

    if(c == '\n')
        ++lineno;

    return c;
}

yyerror(char *s)
{
    warning(s, (char *) 0);
}

warning(char *s, char *t)
{
    fprintf(stderr, "%s: %s", progname, s);

    if(t)
        fprintf(stderr, " %s", t);

    fprintf(stderr, " near line %d\n", lineno);
}

