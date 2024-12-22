type position =
  { start  : Lexing.position
  ; length : int
  }

type 'a node =
  { pos  : position
  ; data : 'a
  }

type var    = string
type symbol = string node

type term = term_data node
and term_data =
  | Var  of var
  | Num  of int
  | Atom of symbol
  | Sym  of symbol * term list

type clause = clause_data node
and clause_data =
  | Fact of term
  | Rule of term * term list

type program = clause list
type query   = term list
