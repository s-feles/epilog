open Ast
open RefMonad

module M = RefMonad (struct type t = term_data end) (String)
open M
let (let*) = bind

let show_term (t : term) =
  let open Printf in
  let rec show t = 
    match t with
    | Var x -> sprintf "Var(%s)" x
    | Sym (f, ts) -> 
      sprintf "Sym(%s, [%s])" f.data (String.concat "; " (List.map (fun t -> show t.data) ts))
    | Num n -> sprintf "Num(%s)" (string_of_int n)
    | Atom f -> sprintf "Atom(%s)" f.data
  in show t.data

let show_clause c =
  let open Printf in
  let rec show c =
    match c with
    | Fact t -> printf "Fact(%s)" (show_term t)
    | Rule (t, ts) -> printf "Rule(%s, [%s])" (show_term t) (String.concat ", " (List.map show_term ts))
  in show c.data

let fresh = ref 0

let fresh_var () =
  let cnt = !fresh in
  fresh := cnt + 1;
  "#" ^ string_of_int cnt

let rec deref t =
  match t with
  | Var x ->
    let* subst = get x in
    begin
      match subst with
      | Some t' -> 
        let* t' = deref t' in
        let* () = set x t in
        return t'
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

  let rec unify t1 t2 =
    let* t1' = deref t1 in
    let* t2' = deref t2 in
    match t1', t2' with
    | Var x, Var y when x = y -> return ()
    | t, Var x | Var x, t -> 
      let* subst = get x in begin
        match subst with
        | Some t' -> unify t t'
        | None -> 
          let* c = contains_var x t in
          if c then fail
          else let* () = set x t in return ()
      end 
    | Sym (f1, ts1), Sym (f2, ts2) ->
      if f1.data = f2.data && List.length ts1 = List.length ts2 then
        List.fold_left (fun acc (t1, t2) -> 
          let* () = acc in unify t1.data t2.data) (return ()) (List.combine ts1 ts2)
      else fail
    | Atom f1, Atom f2 ->
      if f1.data = f2.data then return () else fail
    | Num n1, Num n2 ->
      if n1 = n2 then return () else fail
    | _ -> fail

let rec select_clause (prog : program) = 
  match prog with
  | [] -> fail
  | c :: cs ->
    let* b = flip in
    if b then return c else select_clause cs

let refresh_clause c =
  let name = fresh_var () in
  let rec refresh t =
    match t.data with
    | Var x -> { pos = t.pos ; data = Var (name ^ x) }
    | Sym (f, ts) -> { pos = t.pos ; data = Sym (f, List.map refresh ts) }
    | _ as t' -> { pos = t.pos ; data = t' }
  in match c.data with
  | Fact t -> (refresh t, [])
  | Rule (h, b) -> (refresh h, List.map refresh b)

let rec solve gs =
  match gs with
  | [] -> return ()
  | g :: gs ->
    let* c = select_clause [] in
    let (h, b) = refresh_clause c in
    let* () = unify h.data g.data in
    solve (b @ gs)

let () = 
  let open Printf in
  match Sys.argv with
  | [|_; fname |] -> begin
    try
      let program = Parser.parse_file fname in
      printf "select_clause test\n";
      printf "Original program:\n";
      List.iter (fun c -> show_clause c; print_newline ()) program;
      printf "\nSelected clauses:\n";
      let selected = select_clause program
        |> run
        |> List.of_seq
      in List.iter (fun c -> show_clause c; print_newline ()) selected
    with
    | Failure s -> printf "%s" s
    | Errors.Cannot_open_file { fname; message } -> 
      eprintf "Error: Cannot open file '%s': %s\n" fname message
    | Errors.Parse_error (pos, reason) ->
      eprintf "Error: Parsing error at position %d:%d: %s\n"
      pos.Ast.start.pos_lnum
      (pos.Ast.start.pos_cnum - pos.Ast.start.pos_bol)
      (match reason with
      | EofInComment -> "EOF in comment"
      | InvalidNumber n -> sprintf "Invalid number: %s" n
      | InvalidChar c -> sprintf "Invalid character: %c" c
      | UnexpectedToken tok -> sprintf "Invalid token: %s" tok)
  end
  | _ -> eprintf "Usage: dune exec epilog -- <program.pl>"