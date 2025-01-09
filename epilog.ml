open Ast
open RefMonad

exception Not_unifiable

module M = RefMonad (struct type t = term_data end) (String)
open M
let (let*) = bind

let view (t: 'a node) = t.data

let rec deref t =
  match t with
  | Var x ->
    let* subst = get x in
    begin
      match subst with
      | Some t' -> deref t'
      | None -> return t
    end
  | _ -> return t

let rec contains_var x t =
  let* t' = deref t in
  match t' with
  | Var v when v = x -> return true
  | Sym(_, ts) -> List.fold_left (fun acc t -> 
    let* acc' = acc in
    if acc' then return true else contains_var x t) (return false) (List.map (fun x -> x.data) ts)
  | _ -> return false

let unify t1 t2 =
  let rec unif t1 t2 =
    let* t1' = deref t1 in
    let* t2' = deref t2 in
    match t1', t2' with
    | Var x, Var y when x = y -> return ()
    | t, Var x | Var x, t -> 
      let* subst = get x in begin
        match subst with
        | Some t' -> unif t t'
        | None -> 
          let* c = contains_var x t in
          if c then raise Not_unifiable
          else let* () = set x t in return ()
      end 
    | Sym (f1, ts1), Sym (f2, ts2) ->
      if view f1 = view f2 && List.length ts1 = List.length ts2 then
        List.fold_left (fun acc (t1, t2) -> 
          let* () = acc in unif (view t1) (view t2)) (return ()) (List.combine ts1 ts2)
      else raise Not_unifiable
    | Atom f1, Atom f2 ->
      if view f1 = view f2 then return () else raise Not_unifiable
    | Num n1, Num n2 ->
      if n1 = n2 then return () else raise Not_unifiable
    | _ -> raise Not_unifiable
  in unif t1 t2 |> run |> List.of_seq |> List.hd

let () = 
  match Sys.argv with
  | [|_; fname |] -> begin
    try
      let program = Parser.parse_file fname in
      match program with
      | r1 :: r2 :: [] -> begin
        match view r1, view r2 with
        | Fact t1, Fact t2 -> unify t1.data t2.data
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