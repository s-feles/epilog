open Ast

let rec show_term_data data =
  let open Printf in
  match data with 
  | Var var -> sprintf "Var(%s)" var
  | Num n -> sprintf "Num(%d)" n
  | Atom sym -> sprintf "Atom(%s)" (show_symbol sym)
  | Sym (sym, terms) -> sprintf "Sym(%s, [%s])"
    (show_symbol sym)
    (String.concat "; " (List.map show_term terms))

and show_term t =
  show_term_data t.data

and show_symbol sym =
  sym.data

let show_clause cl =
  match cl.data with
  | Fact t -> Printf.sprintf "Fact(%s)" (show_term t)
  | Rule (head, body) -> Printf.sprintf "Rule(%s, [%s])" (show_term head) (String.concat "; " (List.map show_term body))
  
let show_program p =
  String.concat "\n" (List.map show_clause p)

let () = 
  match Sys.argv with
  | [| _; fname |] -> begin
    try
      let program = Parser.parse_file fname in
      Printf.printf "Read:\n%s\n" (show_program program)
    with
    | Errors.Cannot_open_file { fname; message } -> 
      Printf.eprintf "Error: Cannot open file '%s': %s\n" fname message
    | Errors.Parse_error (pos, reason) ->
      Printf.eprintf "Error: Parsing error at position %d:%d: %s\n"
      pos.Ast.start.pos_lnum
      (pos.Ast.start.pos_cnum - pos.Ast.start.pos_bol)
      (match reason with
      | EofInComment -> "EOF in comment"
      | InvalidNumber n -> Printf.sprintf "Invalid number: %s" n
      | InvalidChar c -> Printf.sprintf "Invalid character: %c" c
      | UnexpectedToken tok -> Printf.sprintf "Invalid token: %s" tok)
    end
  | _ -> Printf.eprintf "Usage: %s <program.pl>\n" Sys.argv.(0)
