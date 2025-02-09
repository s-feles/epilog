%token<string> VAR SYM
%token<int> NUM
%token BR_OPN BR_CLS SQR_OPN SQR_CLS BAR
%token CUT ASTERISK COMMA DOT MINUS PLUS SLASH
%token EQ LT GT
%token COLON_MINUS IS
%token EOF

%nonassoc EQ LT GT

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

let make_list xs ys =
  (List.fold_right (fun x acc ->
    make (Sym(make "#cons", [x; acc]))) xs ys)

let make_nil xs = make_list xs (make (Atom(make "#nil")))
%}

%%
cut
: CUT { EmptyCut }
;

list
: SQR_OPN SQR_CLS { make (Atom(make "#nil")) }
//| SQR_OPN term SQR_CLS { make (Sym(make "#cons", [ $2; make (Atom(make "nil")) ])) }
| SQR_OPN term_list BAR term SQR_CLS { make_list $2 $4 }
| SQR_OPN term_list SQR_CLS { make_nil $2 }
;

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

comp_sym
: EQ { make "eq" }
| LT { make "<" }
| GT { make ">" }
;

symbol
: SYM { make $1 }
;

/* ========================================================================= */

term
: term_add is_sym term_add { make (Sym($2, [ $1; $3 ])) }
| list { $1 }
| term_add { $1 }
| cut { make $1 }
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
| term_comp { $1 }
;

term_comp
: term_simple comp_sym term_simple { make (Sym($2, [ $1; $3 ])) }
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
