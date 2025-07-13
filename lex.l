%{
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>

#define DEBUG_TOKENS 1

#if DEBUG_TOKENS
#define RETURN_TOKEN(tok) do { printf("Token: %s (%d) at line %d\n", #tok, tok, yylineno); return tok; } while(0)
#define RETURN_TOKEN_VAL(tok, val) do { printf("Token: %s (\"%s\") at line %d\n", #tok, val, yylineno); return tok; } while(0)
#else
#define RETURN_TOKEN(tok) return tok
#define RETURN_TOKEN_VAL(tok, val) return tok
#endif

%}
%option yylineno

%%

"form"      { RETURN_TOKEN(FORM); }
"meta"      { RETURN_TOKEN(META); }
"section"   { RETURN_TOKEN(SECTION); }
"field"     { RETURN_TOKEN(FIELD); }
"validate"  { RETURN_TOKEN(VALIDATE); }
"if"        { RETURN_TOKEN(IF); }
"error"     { RETURN_TOKEN(ERROR); }

"required"  { RETURN_TOKEN(REQUIRED); }
"default"   { RETURN_TOKEN(DEFAULT); }
"pattern"   { RETURN_TOKEN(PATTERN); }
"min"       { RETURN_TOKEN(MIN); }
"max"       { RETURN_TOKEN(MAX); }
"rows"      { RETURN_TOKEN(ROWS); }
"cols"      { RETURN_TOKEN(COLS); }
"options"   { RETURN_TOKEN(OPTIONS); }
"accept"    { RETURN_TOKEN(ACCEPT); }

"true"|"false" { yylval.str = strdup(yytext); RETURN_TOKEN_VAL(BOOL, yytext); }

"text"|"email"|"number"|"date"|"checkbox"|"radio"|"password"|"file"|"textarea"|"dropdown" {
    yylval.str = strdup(yytext);
    RETURN_TOKEN_VAL(FIELD_TYPE, yytext);
}

\"([^"\\]|\\[\\"])*\" {
    yytext[yyleng - 1] = '\0';
    yylval.str = strdup(yytext + 1);
    RETURN_TOKEN_VAL(STRING, yytext + 1);
}

[0-9]+       { yylval.num = atoi(yytext); printf("Token: NUMBER (%d) at line %d\n", yylval.num, yylineno); return NUMBER; }

"=="         { RETURN_TOKEN(EQ); }
"!="         { RETURN_TOKEN(NEQ); }
">="         { RETURN_TOKEN(GE); }
"<="         { RETURN_TOKEN(LE); }
">"          { RETURN_TOKEN(GT); }
"<"          { RETURN_TOKEN(LT); }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); RETURN_TOKEN_VAL(ID, yytext); }

"="     { printf("Token: = at line %d\n", yylineno); return '='; }
","     { printf("Token: , at line %d\n", yylineno); return ','; }
";"     { printf("Token: ; at line %d\n", yylineno); return ';'; }
"{"     { printf("Token: { at line %d\n", yylineno); return '{'; }
"}"     { printf("Token: } at line %d\n", yylineno); return '}'; }
":"     { printf("Token: : at line %d\n", yylineno); return ':'; }
"["     { printf("Token: [ at line %d\n", yylineno); return '['; }
"]"     { printf("Token: ] at line %d\n", yylineno); return ']'; }
"("     { printf("Token: ( at line %d\n", yylineno); return '('; }
")"     { printf("Token: ) at line %d\n", yylineno); return ')'; }

[ \t\r\n]+   { /* skip whitespace */ }

.            { 
    fprintf(stderr, "Unexpected character '%c' (ASCII %d) at line %d\n", yytext[0], (int)yytext[0], yylineno);
    return yytext[0]; 
}

%%