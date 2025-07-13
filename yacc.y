%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylineno;

FILE *html;
char *current_field_name;
char *current_field_type;

void yyerror(const char *s) {
    fprintf(stderr, "Parse error at line %d: %s\n", yylineno, s);
}
int yylex(void);

void generate_field_html(char *name, char *type, char *attributes);
char* process_attributes(char *attr_list);
%}

%union {
    char *str;
    int num;
}

%token <str> STRING ID BOOL FIELD_TYPE
%token <num> NUMBER

%token FORM META SECTION FIELD VALIDATE IF ERROR
%token REQUIRED DEFAULT PATTERN MIN MAX ROWS COLS OPTIONS ACCEPT
%token EQ NEQ GE LE GT LT

%type <str> form_name section_name field_name field_type attribute_list attribute option_list

%%

form:
    FORM form_name '{' {
        html = fopen("output.html", "w");
        fprintf(html, "<!DOCTYPE html>\n<html>\n<head>\n");
        fprintf(html, "<title>%s</title>\n", $2);
        fprintf(html, "<style>\n");
        fprintf(html, "body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }\n");
        fprintf(html, ".form-container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }\n");
        fprintf(html, "fieldset { margin: 20px 0; padding: 20px; border: 2px solid #ddd; border-radius: 8px; }\n");
        fprintf(html, "legend { font-weight: bold; font-size: 1.3em; color: #333; padding: 0 10px; }\n");
        fprintf(html, "label { display: block; margin: 12px 0; font-weight: 500; }\n");
        fprintf(html, "input, textarea, select { margin: 5px; padding: 8px; border: 1px solid #ccc; border-radius: 4px; font-size: 14px; }\n");
        fprintf(html, "input[type='submit'] { background-color: #007bff; color: white; padding: 12px 30px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; }\n");
        fprintf(html, "input[type='submit']:hover { background-color: #0056b3; }\n");
        fprintf(html, ".radio-group, .checkbox-group { margin: 10px 0; }\n");
        fprintf(html, ".radio-group input, .checkbox-group input { margin-right: 8px; }\n");
        fprintf(html, ".error { color: red; font-size: 0.9em; margin-top: 5px; }\n");
        fprintf(html, "</style>\n");
        fprintf(html, "<script>\n");
        fprintf(html, "function validateForm() {\n");
        fprintf(html, "  var age = document.forms['%s']['age'].value;\n", $2);
        fprintf(html, "  if (age < 13) {\n");
        fprintf(html, "    alert('Contestants must be at least 13 years old to participate.');\n");
        fprintf(html, "    return false;\n");
        fprintf(html, "  }\n");
        fprintf(html, "  if (age > 99) {\n");
        fprintf(html, "    alert('Invalid age provided.');\n");
        fprintf(html, "    return false;\n");
        fprintf(html, "  }\n");
        fprintf(html, "  return true;\n");
        fprintf(html, "}\n");
        fprintf(html, "</script>\n");
        fprintf(html, "</head>\n<body>\n");
        fprintf(html, "<div class='form-container'>\n");
        fprintf(html, "<form name=\"%s\" method=\"post\" onsubmit=\"return validateForm()\">\n", $2);
        fprintf(html, "<h1>%s</h1>\n", $2);
    } optional_meta sections validations '}' {
        fprintf(html, "<input type=\"submit\" value=\"Submit Form\">\n");
        fprintf(html, "</form>\n</div>\n</body>\n</html>\n");
        fclose(html);
        printf("Poetry submission form parsed successfully!\n");
        printf("HTML output written to output.html\n");
    }
;

form_name:
    ID { $$ = $1; }
;

optional_meta:
    META ID '=' STRING ';' {
        fprintf(html, "<!-- Meta: %s = %s -->\n", $2, $4);
    }
    | /* empty */
;

sections:
    /* empty */
    | sections section
;

section:
    SECTION section_name '{' {
        fprintf(html, "<fieldset>\n<legend>%s</legend>\n", $2);
    } fields '}' {
        fprintf(html, "</fieldset>\n");
    }
;

section_name:
    ID { $$ = $1; }
;

fields:
    /* empty */
    | fields field
;

field:
    FIELD field_name ':' field_type attribute_list ';' {
        generate_field_html($2, $4, $5);
    }
;

field_name:
    ID { $$ = $1; }
;

field_type:
    FIELD_TYPE { $$ = $1; }
;

attribute_list:
    /* empty */ { $$ = strdup(""); }
    | attribute_list attribute {
        if ($2 && strlen($2) > 0) {
            char *buf = malloc(strlen($1) + strlen($2) + 2);
            strcpy(buf, $1);
            if (strlen($1) > 0) strcat(buf, " ");
            strcat(buf, $2);
            $$ = buf;
            free($1);
        } else {
            $$ = $1;
        }
    }
;

attribute:
    REQUIRED { $$ = strdup("required"); }
    | REQUIRED '=' BOOL { 
        if (strcmp($3, "true") == 0) {
            $$ = strdup("required");
        } else {
            $$ = strdup("");
        }
        free($3);
    }
    | DEFAULT '=' STRING { 
        char *buf = malloc(strlen($3) + 20);
        sprintf(buf, "value=\"%s\"", $3);
        $$ = buf;
        free($3);
    }
    | DEFAULT '=' BOOL { 
        if (strcmp($3, "true") == 0) {
            $$ = strdup("checked");
        } else {
            $$ = strdup("");
        }
        free($3);
    }
    | PATTERN '=' STRING { 
        char *buf = malloc(strlen($3) + 20);
        sprintf(buf, "pattern=\"%s\"", $3);
        $$ = buf;
        free($3);
    }
    | MIN '=' NUMBER { 
        char *buf = malloc(50);
        sprintf(buf, "min=\"%d\"", $3);
        $$ = buf;
    }
    | MAX '=' NUMBER { 
        char *buf = malloc(50);
        sprintf(buf, "max=\"%d\"", $3);
        $$ = buf;
    }
    | ROWS '=' NUMBER { 
        char *buf = malloc(50);
        sprintf(buf, "rows=\"%d\"", $3);
        $$ = buf;
    }
    | COLS '=' NUMBER { 
        char *buf = malloc(50);
        sprintf(buf, "cols=\"%d\"", $3);
        $$ = buf;
    }
    | OPTIONS '=' '[' option_list ']' { 
        char *buf = malloc(strlen($4) + 20);
        sprintf(buf, "OPTIONS=%s", $4);
        $$ = buf;
        free($4);
    }
    | ACCEPT '=' STRING { 
        char *buf = malloc(strlen($3) + 20);
        sprintf(buf, "accept=\"%s\"", $3);
        $$ = buf;
        free($3);
    }
;

option_list:
    STRING {
        $$ = strdup($1);
        free($1);
    }
    | option_list ',' STRING {
        char *buf = malloc(strlen($1) + strlen($3) + 10);
        sprintf(buf, "%s,%s", $1, $3);
        $$ = buf;
        free($1);
        free($3);
    }
;

validations:
    /* empty */
    | validations validation
;

validation:
    VALIDATE '{' validation_statements '}'
;

validation_statements:
    /* empty */
    | validation_statements validation_statement
;

validation_statement:
    IF '(' ID LT NUMBER ')' '{' error_statement '}'
    | IF '(' ID GT NUMBER ')' '{' error_statement '}'
    | IF '(' ID LE NUMBER ')' '{' error_statement '}'
    | IF '(' ID GE NUMBER ')' '{' error_statement '}'
    | IF '(' ID EQ NUMBER ')' '{' error_statement '}'
    | IF '(' ID NEQ NUMBER ')' '{' error_statement '}'
;

error_statement:
    ERROR STRING ';' {
        fprintf(html, "<!-- Validation: %s -->\n", $2);
        free($2);
    }
;

%%

void generate_field_html(char *name, char *type, char *attributes) {
    if (strcmp(type, "text") == 0 || strcmp(type, "email") == 0 || 
        strcmp(type, "number") == 0 || strcmp(type, "date") == 0 || 
        strcmp(type, "password") == 0 || strcmp(type, "file") == 0) {
        fprintf(html, "<label>%s: <input type=\"%s\" name=\"%s\" %s></label><br>\n", 
                name, type, name, attributes);
    }
    else if (strcmp(type, "textarea") == 0) {
        fprintf(html, "<label>%s:<br><textarea name=\"%s\" %s></textarea></label><br>\n", 
                name, name, attributes);
    }
    else if (strcmp(type, "checkbox") == 0) {
        fprintf(html, "<div class='checkbox-group'><label><input type=\"checkbox\" name=\"%s\" %s> %s</label></div>\n", 
                name, attributes, name);
    }
    else if (strcmp(type, "dropdown") == 0) {
        char *options_start = strstr(attributes, "OPTIONS=");
        if (options_start) {
            fprintf(html, "<label>%s: <select name=\"%s\"", name, name);
            // Add other attributes except OPTIONS
            char *other_attrs = strdup(attributes);
            char *opts_pos = strstr(other_attrs, "OPTIONS=");
            if (opts_pos) *opts_pos = '\0';
            fprintf(html, " %s>\n", other_attrs);
            
            // Parse options and create option tags
            char *opts = strchr(options_start, '=') + 1;
            char *opts_copy = strdup(opts);
            char *token = strtok(opts_copy, ",");
            while (token != NULL) {
                fprintf(html, "<option value=\"%s\">%s</option>\n", token, token);
                token = strtok(NULL, ",");
            }
            free(opts_copy);
            free(other_attrs);
            fprintf(html, "</select></label><br>\n");
        }
    }
    else if (strcmp(type, "radio") == 0) {
        fprintf(html, "<label>%s:</label><br>\n<div class='radio-group'>\n", name);
        char *options_start = strstr(attributes, "OPTIONS=");
        if (options_start) {
            char *opts = strchr(options_start, '=') + 1;
            char *opts_copy = strdup(opts);
            char *token = strtok(opts_copy, ",");
            while (token != NULL) {
                char *req_str = strstr(attributes, "required") ? "required" : "";
                fprintf(html, "<label><input type=\"radio\" name=\"%s\" value=\"%s\" %s> %s</label><br>\n", 
                        name, token, req_str, token);
                token = strtok(NULL, ",");
            }
            free(opts_copy);
        }
        fprintf(html, "</div>\n");
    }
}

int main() {
    printf("Starting FormLang++ parser...\n");
    if (yyparse() == 0) {
        printf("Parsing completed successfully.\n");
        return 0;
    } else {
        printf("Parsing failed.\n");
        return 1;
    }
}