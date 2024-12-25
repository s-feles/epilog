open Ast

exception Not_unifiable

module M = Map.Make(String)
type env = term M.t

let view (t: 'a node) = t.data

let rec show_term_data data =
  let open Printf in
  match data with 
  | Var var -> sprintf "Var(%s)" var
  | Num n -> sprintf "Num(%d)" n
  | Atom sym -> sprintf "Atom(%s)" (view sym)
  | Sym (sym, terms) -> sprintf "Sym(%s, [%s])"
    (view sym)
    (String.concat "; " (List.map show_term terms))

and show_term t =
  show_term_data (view t)

let rec contains_var (x: var) (t: term_data) : bool =
  match t with
  | Var v when v = x -> true
  | Sym(_, ts) -> List.exists (contains_var x) (List.map view ts)
  | _ -> false

let rec subst v x t =
  match view t with
  | Var y when x = y -> t.data <- v
  | Sym(_, ts) -> List.iter (subst v x) ts
  | _ -> ()

let rec unify (t1 : term) (t2 : term) =
  match view t1, view t2 with
  | Var x, Var y when x = y -> ()
  | Var x, t | t, Var x ->
    if contains_var x t then raise Not_unifiable
    else 
      Printf.printf "%s <- %s\n" x (show_term_data t);
      subst t x t1;
      subst t x t2; (*
  | t, Var x -> 
    if contains_var x t then raise Not_unifiable
    else 
      Printf.printf "%s <- %s\n" x (show_term_data t);
      subst t x t2*)
  | Sym (f1, ts1), Sym (f2, ts2) ->
    if view f1 = view f2 && List.length ts1 = List.length ts2 then List.iter2 unify ts1 ts2
    else raise Not_unifiable
  | Atom f1, Atom f2 -> 
    if view f1 = view f2 then () else raise Not_unifiable
  | Num n1, Num n2 ->
    if n1 = n2 then () else raise Not_unifiable
  | _ -> raise Not_unifiable

let () = 
  match Sys.argv with
  | [|_; fname |] -> begin
    try
      let program = Parser.parse_file fname in
      match program with
      | r1 :: r2 :: [] -> begin
        match view r1, view r2 with
        | Fact t1, Fact t2 -> unify t1 t2
        | _ -> failwith "Wrong input"
        end
      | _ -> failwith "Wrong input"
    with
    | Not_unifiable -> Printf.printf "Not unifiable\n"
    | Failure s -> Printf.printf "%s" s
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
  | _ -> Printf.eprintf "Usage: dune exec epilog -- <program.pl>"