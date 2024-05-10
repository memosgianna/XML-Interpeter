%{ 
#include "bison.tab.h"
#include <stdio.h>
#include <ctype.h>


int validComment(const char *comment){
    int len=strlen(comment);

    //check "<!--"
    if(len<7 || strncmp(comment,"<!--",4)!=0)
        return 0;

    //check "-->"
    if(strncmp(comment+len-3,"-->",3)!=0)
        return 0;

    //check -- mesa
    for(int i=4; i<len-3; i++){
        if(comment[i]=='-' && comment[i+1]=='-')
            return 0;
    }

    return 1;
}
%}

%%

"<!--".*"-->" {
    if (validComment(yytext)){
    }
    else{
        fprintf(stderr, "Invalid Comment at line: %d\n", yylineno-1);
        exit(0);
    }
        
} 

"/>"            { return OTHER_CLOSE;}
">"             { return TAG_CLOSE; }
"android:id"    { yylval.string = strdup(yytext); return ANDROID_ID; }
"android:layout_width" { yylval.string = strdup(yytext); return LAYOUT_WIDTH; }
"android:layout_height" { yylval.string = strdup(yytext); return LAYOUT_HEIGHT; }
"android:orientation" { yylval.string = strdup(yytext); return ORIENTATION; }
"android:text" { yylval.string = strdup(yytext); return TEXT; }
"android:button_count" {yylval.integer = atoi(yytext); return RADIO_BUTTON_COUNT; }
"android:src" { yylval.string = strdup(yytext); return SRC; }
"android:padding" { yylval.integer = atoi(yytext); return PADDING; }
"android:textColor" { yylval.integer = atoi(yytext); return TEXTCOLOR; }
"android:checkButton" { yylval.string = strdup(yytext); return CHECKBUTTON;}
"android:max"       {yylval.integer = atoi(yytext); return MAX;}
"android:progress"       {yylval.integer = atoi(yytext); return PROGRESS;}

"<LinearLayout" { return LINEAR_LAYOUT_OPEN; }
"</LinearLayout>" { return LINEAR_LAYOUT_CLOSE; }
"<RelativeLayout" { return RELATIVE_LAYOUT_OPEN; }
"</RelativeLayout>"   { return RELATIVE_LAYOUT_CLOSE; }
"<Button"          {return BUTTON_OPEN; }
"<TextView"      { return TEXT_VIEW_OPEN; }
"<ImageView"     { return IMAGE_VIEW_OPEN; }
"<RadioGroup"     {return RADIO_GROUP_OPEN;}
"</RadioGroup>"   {return RADIO_GROUP_CLOSE; }
"<RadioButton"  {return RADIO_BUTTON_OPEN; }
"<ProgressBar" {return PROGRESS_BAR_OPEN; }
"="             {return EQUALS;}
    

\"match_parent\"    {yylval.string=strdup(yytext); return SIZE1; }
\"wrap_content\"    {yylval.string=strdup(yytext); return SIZE2; }
\"[1-9][0-9]*\"      { yylval.string = strdup(yytext);  return NUMBER; }
"0"              { yylval.integer = 0; return NUMBER; }
\"[a-zA-Z0-9_ ]+\"  { yylval.string = strdup(yytext+1); yylval.string[strlen(yylval.string)-1] = '\0'; return STRING;}


[ \t\n]         /* Ignore whitespace */
.               { printf("Invalid character: %s\n", yytext); }

%%

int yywrap() {
    return 1;

}
