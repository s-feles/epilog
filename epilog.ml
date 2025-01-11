open Ast
open RefMonad

module M = RefMonad (struct type t = term_data end) (String)
open M
let (let*) = bind

let fresh = ref 0

let fresh_var () =
  let cnt = !fresh in
  fresh := cnt + 1;
  "#" ^ string_of_int cnt

let rec list_monad xs =
  match xs with
  | [] -> return []
  | m :: ms ->
    let* x = m in
    let* xs = list_monad ms in
    return (x :: xs)

let rec deref t =
  match t with
  | Var x ->
    let* subst = get x in
    begin
      match subst with
      | Some t' -> 
        let* t'' = deref t' in
        let* () = set x t'' in
        return t''
      | None -> return t
    end
  | Sym (f, ts) ->
    let* ts' = List.map (fun t -> deref t.data) ts |> list_monad in
    let new_terms = List.fold_right (fun (t, d) acc -> { t with data = d } :: acc) (List.combine ts ts') [] in
    return (Sym (f, new_terms))
  | _ -> return t

let rec contains_var x t =
  let* t' = deref t in
  match t' with
  | Var v when v = x -> return true
  | Sym (_, ts) -> List.fold_left (fun acc t -> 
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
        else 
          let* t' = deref t in
          let* () = set x t' in 
          return ()
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

let rec select_clause prog = 
  match prog with
  | [] -> fail
  | c :: cs ->
    let* b = flip in
    if b then return c else select_clause cs

let refresh_clause c =
  let name = fresh_var () in
  let rec refresh t =
    match t.data with
    | Var x -> { t with data = Var (name ^ x) }
    | Sym (f, ts) -> { t with data = Sym (f, List.map refresh ts) }
    | _ -> t
  in match c.data with
  | Fact t -> (refresh t, [])
  | Rule (h, b) -> (refresh h, List.map refresh b)

let rec solve gs prog =
  match gs with
  | [] -> return ()
  | g :: gs ->
    let* c = select_clause prog in
    let (h, b) = refresh_clause c in
    let* () = unify h.data g.data in
    solve (b @ gs) prog

let get_query_vars ts =
  let rec get_vars acc t =
    match t.data with
    | Var x -> x :: acc
    | Sym (_, ts) -> List.concat_map (get_vars acc) ts
    | _ -> acc
  in let cons_uniq xs x =
    if List.mem x xs then xs else x :: xs
  in List.concat_map (get_vars []) ts
    |> List.fold_left cons_uniq []

let get_subst vs =
  let rec subst vs acc =
    match vs with
    | [] -> return acc
    | v :: vs ->
      let* t = get v in begin
        match t with
        | Some t -> 
          let* t = deref t in
          subst vs ((v, t) :: acc)
        | None -> subst vs acc
        end
  in subst vs []

let print_subst subst =
  let open Printf in
  let rec format_term t = format_term_data t.data
  and format_term_data t =
    match t with
    | Var x -> x
    | Num n -> string_of_int n
    | Atom f -> f.data
    | Sym (f, ts) -> sprintf "%s(%s)" f.data (String.concat ", " (List.map format_term ts))
  in match subst with
  | [] -> print_endline "true"
  | _ -> 
    subst
    |> List.map (fun (v, t) -> sprintf "%s = %s" v (format_term_data t))
    |> String.concat ", "
    |> print_endline

let rec repl prog =
  print_string "?- ";
  flush stdout;
  try
    let query = Parser.parse_query stdin in
    let vars = get_query_vars query in
    let m =
      let* () = solve query prog in
      let* subst = get_subst vars in
      return subst
    in let results = run m |> List.of_seq in
    let rec handle = function
    | [] -> print_endline "false.\n"
    | subst :: rest -> 
      print_subst subst;
      match input_line stdin with
      | "." -> ()
      | ";" -> handle rest
      | _ -> print_endline "Invalid input\n"
    in handle results; repl prog
  with
  | Errors.Parse_error (pos, reason) ->
    Printf.eprintf "Error: Parsing error at position %d:%d: %s\n"
    pos.Ast.start.pos_lnum
    (pos.Ast.start.pos_cnum - pos.Ast.start.pos_bol)
    (match reason with
    | EofInComment -> "EOF in comment"
    | InvalidNumber n -> Printf.sprintf "Invalid number: %s" n
    | InvalidChar c -> Printf.sprintf "Invalid character: %c" c
    | UnexpectedToken tok -> Printf.sprintf "Invalid token: %s" tok)

let () = 
  let open Printf in
  match Sys.argv with
  | [|_; fname |] -> begin
    try
      let program = Parser.parse_file fname in
      repl program
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