%token<string> VAR SYM
%token<int> NUM
%token BR_OPN BR_CLS
%token ASTERISK COMMA DOT MINUS PLUS SLASH
%token COLON_MINUS IS
%token EOF

%type<Ast.program> program
%start program

%type<Ast.query> query
%start query

%{

open Ast

let current_pos () =
  let start_p = symbol_start_pos () in
  let end_p   = symbol_end_pos () in
  { start  = start_p
  ; length = end_p.pos_cnum - start_p.pos_cnum
  }

let make data =
  { pos  = current_pos ()
  ; data = data
  }

%}

%%

is_sym
: IS { make "is" }
;

add_sym
: PLUS  { make "+" }
| MINUS { make "-" }
;

mult_sym
: ASTERISK { make "*" }
| SLASH    { make "/" }
;

symbol
: SYM { make $1 }
;

/* ========================================================================= */

term
: term_add is_sym term_add { make (Sym($2, [ $1; $3 ])) }
| term_add { $1 }
;

term_add
: term_mult add_sym term_add { make (Sym($2, [ $1; $3 ])) }
| term_mult { $1 }
;

term_mult
: term_neg mult_sym term_mult { make (Sym($2, [ $1; $3 ])) }
| term_neg { $1 }
;

term_neg
: add_sym term_neg { make (Sym($1, [ $2 ])) }
| term_simple { $1 }
;

term_simple
: BR_OPN term BR_CLS { make ($2).data }
| VAR                { make (Var  $1) }
| NUM                { make (Num  $1) }
| symbol             { make (Atom $1) }
| symbol BR_OPN term_list BR_CLS { make (Sym($1, $3)) }
;

/* ========================================================================= */

term_list
: term                 { [ $1 ]   }
| term COMMA term_list { $1 :: $3 }
;

/* ========================================================================= */

clause
: term DOT                       { make (Fact $1)      }
| term COLON_MINUS term_list DOT { make (Rule($1, $3)) }
;

clause_list_rev
: /* empty */            { []       }
| clause_list_rev clause { $2 :: $1 }
;

clause_list
: clause_list_rev { List.rev $1 }
;

/* ========================================================================= */

program
: clause_list EOF { $1 }
;

query
: term_list DOT { $1 }
;
