%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern int yylineno;
extern FILE* yyin;
extern char* yytext;

void yyerror(const char *);
int yylex();

//gia must haves
int mandatory_tokens_seen = 0;
int mandatory_radio_buttons=0;


//gia elegxo unique android:ids
#define MAX_IDS 1000
char *id_list[MAX_IDS];
int num=0;

void add_id(char *id){
    if(num>=MAX_IDS){
        fprintf(stderr, "Maximum ammount of android:id reached.\n");
        exit(1);
    }
    id_list[num++]=id;
}

int check_id(char *id){
    for(int i=0; i<num; i++){
        if(strcmp(id, id_list[i])==0){
            return 0;
        }
    }
    return 1;
}


//gia checkButton sto radiogroup
struct {
    char* code;
} checkButton;

int radio_button_check=0;


#define MAX_RADIO_BUTTONS 100
char* radio_button_ids[MAX_RADIO_BUTTONS];
int num_radio_buttons = 0;
int checkButton_line = 0;
int radio_button_found=0;

void perform_validation(){
    int match_found=0;
    for(int i=0; i<num_radio_buttons; i++){
        if (strcmp(checkButton.code, radio_button_ids[i])==0) {
            match_found = 1;
            break;
        }
    }

    if(match_found==0){
        fprintf(stderr, "No match found for checkButton at line %d\n", checkButton_line-1);
        exit(0);
    }
}

//gia max kai progress sto PROGRESS BAR
char* max_progress_value;
char* progress_value;

char* remove_quotes(const char* str){
    int length=strlen(str);
    if (length >= 2 && str[0]=='"' && str[length - 1]=='"'){
        char* result=malloc(length-1);
        strncpy(result, str + 1, length-2);
        result[length-2]='\0';
        return result;
    }
    return strdup(str);
}


//gia plithos radio buttons entos enos radio group
char* num_of_radio_buttons;
int current_num_of_radio_buttons=0;
char* num_of_radio_buttons_after;
int radioButtonCountLine=0;

void compareRadioButtons(int current_num_of_radio_buttons, const char* num_of_radio_buttons) {
    int count=atoi(num_of_radio_buttons);
    if(current_num_of_radio_buttons!=count){
        fprintf(stderr, "You didnt give the mandatory number of radio buttons in the radio group. Line: %d\n", radioButtonCountLine-1);
        exit(0);
    }else{
        //printf("Number of radio buttons is ok\n");
    }
}

%}

%union {
    char* string;
    int integer;
}

%token STRING NUMBER INT NS SN RADIO_BUTTON_COUNT TEXTCOLOR ANDROID_ID COMMENT_START COMMENT_STOP LAYOUT_WIDTH LAYOUT_HEIGHT COMMENT_CHAR ORIENTATION TEXT SRC PADDING MAX PROGRESS CHECKBUTTON EMPTY EQUALS OPEN OTHER_CLOSE BUTTON_OPEN
%token LINEAR_LAYOUT_OPEN LINEAR_LAYOUT_CLOSE RELATIVE_LAYOUT_OPEN RELATIVE_LAYOUT_CLOSE TEXT_VIEW_OPEN TEXT_VIEW_CLOSE IMAGE_VIEW_OPEN IMAGE_VIEW_CLOSE BUTTON_CLOSE RADIO_GROUP_OPEN RADIO_GROUP_CLOSE RADIO_BUTTON_OPEN RADIO_BUTTON_CLOSE PROGRESS_BAR_OPEN PROGRESS_BAR_CLOSE TAG_CLOSE
%token SIZE1 SIZE2

%type <string> STRING
%type <string> NUMBER
%type <string> field
%type <string> SIZE1
%type <string> SIZE2


%start Root

%%

field: STRING | NUMBER | SIZE1 |SIZE2;

Root: linear_layout
    |relative_layout
    ;

sizes: SIZE1 | SIZE2 | NUMBER;


linear_layout: LINEAR_LAYOUT_OPEN linear_layout_attrs Content LINEAR_LAYOUT_CLOSE
    ;

linear_layout_attrs: | linear_layout_attr linear_layout_attrs
    ;

    linear_layout_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1;  }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | ANDROID_ID EQUALS field{

        if(!check_id($3)){
            yyerror("Android:id value already exists");
        }else{
            add_id($3);
        }
    }
    | ORIENTATION EQUALS field
    | TAG_CLOSE
        {
            if (mandatory_tokens_seen != 3) {
                yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT token.\n");
            }
            mandatory_tokens_seen = 0;
        }
    ;



relative_layout: RELATIVE_LAYOUT_OPEN relative_layout_attrs ContentRel RELATIVE_LAYOUT_CLOSE
    ;

relative_layout_attrs: | relative_layout_attr relative_layout_attrs
    ;

relative_layout_attr:  LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
    }
    | TAG_CLOSE
    {
        if (mandatory_tokens_seen != 3) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;


Content: | Element Content
    ;

Element:
    text_view
    | image_view
    | button
    | radio_group
    | progress_bar
    ;


ContentRel: | ElementRel ContentRel
    ;

ElementRel:
    text_view
    | image_view
    | button
    | radio_group
    | progress_bar
    | 
    ;


text_view: TEXT_VIEW_OPEN text_view_attrs 
    ;

text_view_attrs: | text_view_attr text_view_attrs
    ;

text_view_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | TEXT EQUALS field { mandatory_tokens_seen |= 4; }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
    }
    | TEXTCOLOR EQUALS field
    | OTHER_CLOSE
    {
        if ((mandatory_tokens_seen & 7) != 7) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT or TEXT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;



image_view: IMAGE_VIEW_OPEN image_view_attrs 
    ;

image_view_attrs: | image_view_attr image_view_attrs
    ;

image_view_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | SRC EQUALS field { mandatory_tokens_seen |= 4; }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
    }
    | PADDING EQUALS NUMBER
    | OTHER_CLOSE
    {
        if ((mandatory_tokens_seen & 7) != 7) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT or SRC token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;




button: BUTTON_OPEN button_attrs 
    ;
button_attrs: | button_attr button_attrs
    ;
button_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | TEXT EQUALS field { mandatory_tokens_seen |= 4; }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exist");
            return 1;
        }
        add_id($3);
    }
    | PADDING EQUALS NUMBER 
    | OTHER_CLOSE
    {
        if ((mandatory_tokens_seen & 7) != 7) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT or TEXT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;




radio_group: RADIO_GROUP_OPEN radio_group_attrs ContentR RADIO_GROUP_CLOSE
    ;

radio_group_attrs: | radio_group_attr radio_group_attrs
    ;

radio_group_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2;  }
    | RADIO_BUTTON_COUNT EQUALS NUMBER { 
        mandatory_tokens_seen |=4;
        num_of_radio_buttons=strdup($3);
        num_of_radio_buttons_after=remove_quotes(num_of_radio_buttons);
        radioButtonCountLine=yylineno;
    }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
        
    }
    | CHECKBUTTON EQUALS field {
        checkButton.code = strdup($3); 
        checkButton_line = yylineno;
    }
    | TAG_CLOSE
    {
        if (mandatory_tokens_seen != 7) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT or RADIO_BUTTON_COUNT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }



ContentR: | radio_button ContentR
    ;



radio_button: RADIO_BUTTON_OPEN radio_button_attrs
    ;

radio_button_attrs: | radio_button_attr radio_button_attrs 
    ;

radio_button_attr:LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | TEXT EQUALS field { mandatory_tokens_seen |= 4; }
    | ANDROID_ID EQUALS field{
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
        current_num_of_radio_buttons++;
        radio_button_found++;

        if (checkButton.code != NULL && strcmp(checkButton.code, $3) == 0) {
            //printf("Match found: checkButton id matches radio_button id\n");
            radio_button_check++;
        }

        radio_button_ids[num_radio_buttons++] = strdup($3);

    }
    | OTHER_CLOSE
    {
        if ((mandatory_tokens_seen & 7) != 7) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT or TEXT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;




progress_bar: PROGRESS_BAR_OPEN progress_bar_attrs 
    ;

progress_bar_attrs: | progress_bar_attr progress_bar_attrs
    ;

progress_bar_attr: LAYOUT_WIDTH EQUALS sizes { mandatory_tokens_seen |= 1; }
    | LAYOUT_HEIGHT EQUALS sizes { mandatory_tokens_seen |= 2; }
    | ANDROID_ID EQUALS field{
        current_num_of_radio_buttons++;
        if(!check_id($3)){
            yyerror("Error: android:id value already exists");
            return 1;
        }
        add_id($3);
    }
    | MAX EQUALS NUMBER {  
        max_progress_value=strdup($3);
        
    }
    | PROGRESS EQUALS NUMBER { 
        progress_value=strdup($3);
        char* max_progress_value_after=remove_quotes(max_progress_value);
        char* progress_value_after=remove_quotes(progress_value);
        
        if (atoi(progress_value_after) <= 0 || atoi(progress_value_after) > atoi(max_progress_value_after)) {
            yyerror("Invalid progress   value.");
        }   

    }
    | OTHER_CLOSE
    {
        if (mandatory_tokens_seen != 3) {
            yyerror("Missing mandatory LAYOUT_WIDTH or LAYOUT_HEIGHT token.\n");
            return 1;
        }
        mandatory_tokens_seen = 0;
    }
    ;

%%

void yyerror(const char *s) {
    //printf("Error: %s\n", s);
    fprintf(stderr, "Error: %s at line: %d\n", s, yylineno-1);
    exit(0);
}

int main(int argc, char *argv[]) {

    FILE* file=fopen(argv[1],"r");
    int line = 0;
    int prnt;

    if (!file) {
        printf("Error: Failed to open file '%s'\n", argv[1]);
        return 1;
    }

    yyin=file;
    printf("%d. ",line);
    while ((prnt = fgetc(file)) != EOF) {
        if(prnt=='\n'){
            line++;
            putchar(prnt);
            printf("%d. ",line);
        }else{
            putchar(prnt);
        }
    }
    printf("\n");

    rewind(yyin);
    if (yyparse() == 0) {
        if(radio_button_found>0){
            perform_validation();
            compareRadioButtons(current_num_of_radio_buttons, num_of_radio_buttons_after);

        }
    }

    fflush(stdout);
    fclose(file);
    printf("Compilation Succeded!\n");
    return 0;
}