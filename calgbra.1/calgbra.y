%{
#define YYSTYPE double  /* Stack data type */
%}
%token  NUMBER
%left   '+' '-' /* Left associative, lower precedence than below*/
%left   '*' '/'
%left   UNARYMINUS UNARYPLUS
%%
    /* Start of the Grammar */

list:           /* Allow a blank line as input */
            |   list '\n'
            |   list expr '\n'      { printf("\t%.8g\n", $2); }
            ;
expr:           NUMBER              { $$ = $1; }
            |   '-' expr %prec UNARYMINUS   { $$ = -$2; }
            |   '+' expr %prec UNARYPLUS    { $$ = +$2; }
            |   expr '+' expr       { $$ = $1 + $3; }
            |   expr '-' expr       { $$ = $1 - $3; }
            |   expr '*' expr       { $$ = $1 * $3; }
            |   expr '/' expr       { $$ = $1 / $3; }
            |   '(' expr ')'        { $$ = $2; }
            ;
%% 
    /* End of the Grammar */

#include <stdio.h>
#include <ctype.h>

char    *progname;
int     lineno = 1;

main(int argc, char *argv[])
{
    progname = argv[0]; 
    yyparse();
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
        scanf("%lf", &yylval);  /* Read the value of the number from stdin to yylval, which is defined to be same as YYSTYPE*/
        return NUMBER;          /* Return the TYPE of the token, not the value, which is already stored in above variable*/
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

