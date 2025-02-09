open Ast
open Bt

module M = BT (struct type t = term_data end) (String)
open M
let (let*) = bind

module Arity = struct
  type t = string * int
  let compare t1 t2 = String.compare (fst t1) (fst t2)
end
module ArityMap = Map.Make(Arity)

exception Not_sym

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

let sym_map = 
  [ "+", ( + )
  ; "-", ( - )
  ; "*", ( * )
  ; "/", ( / ) ]
  |> List.to_seq |> Hashtbl.of_seq

let comp_map =
  [ "<", ( < )
  ; ">", ( > ) ]
  |> List.to_seq |> Hashtbl.of_seq

let rec eval_sym fsym t1 t2 =
  let* x = deref t1 in
  let* y = deref t2 in
  match x, y with
  | Num n, Num m -> 
    (match Hashtbl.find_opt sym_map fsym with
    | Some f -> return (Num (f n m))
    | None -> fail)
  | Sym (f', [t1'; t2']), t -> 
    let* n = eval_sym f'.data t1'.data t2'.data in
    eval_sym fsym n t
  | t, Sym (f', [t1'; t2'])->
    let* n = eval_sym f'.data t1'.data t2'.data in
    eval_sym fsym t n
  | _, _ -> fail

  let rec eval_comp fsym t1 t2 =
    let* x = deref t1 in
    let* y = deref t2 in
    match x, y with
    | Num n, Num m -> 
      let c = Hashtbl.find comp_map fsym in
      return (c n m)
    | Sym (f', [t1'; t2']), t -> 
      let* n = eval_sym f'.data t1'.data t2'.data in
      eval_comp fsym n t
    | t, Sym (f', [t1'; t2'])->
      let* n = eval_sym f'.data t1'.data t2'.data in
      eval_comp fsym t n
    | _, _ -> failwith "no nie dziala no"

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

let aritymap prog =
  let rec aux prog map =
    match prog with
    | [] -> map
    | c :: cs -> begin
      match c.data with
      | Fact t -> begin
        match t.data with
        | Atom f -> begin
          match ArityMap.find_opt (f.data, 0) map with
          | Some xs -> aux cs (ArityMap.add (f.data, 0) (c :: xs) map)
          | None -> aux cs (ArityMap.add (f.data, 0) [c] map)
          end
        | Sym (f, ts) -> 
          let sym = f.data in
          let arity = List.length ts in begin
            match ArityMap.find_opt (sym, arity) map with
            | Some xs -> aux cs (ArityMap.add (sym, arity) (c :: xs) map)
            | None -> aux cs (ArityMap.add (sym, arity) [c] map)
            end
        | _ -> aux cs map
        end
      | Rule (h, _) -> begin
        match h.data with
        | Atom f -> begin
          match ArityMap.find_opt (f.data, 0) map with
          | Some xs -> aux cs (ArityMap.add (f.data, 0) (c :: xs) map)
          | None -> aux cs (ArityMap.add (f.data, 0) [c] map)
          end
        | Sym (f, ts) ->
          let sym = f.data in
          let arity = List.length ts in begin
            match ArityMap.find_opt (sym, arity) map with
            | Some xs -> aux cs (ArityMap.add (sym, arity) (c :: xs) map)
            | None -> aux cs (ArityMap.add (sym, arity) [c] map)
            end
        | _ -> aux cs map
        end
      end
  in aux prog ArityMap.empty |> ArityMap.map List.rev

let rec select_clause prog = 
  match prog with
  | [] -> fail
  | c :: cs ->
    let* b = flip in
    if b then return c else select_clause cs

let refresh_clause c m =
  let name = fresh_var () in
  let rec refresh t =
    match t.data with
    | Var x -> { t with data = Var (name ^ x) }
    | Sym (f, ts) -> { t with data = Sym (f, List.map refresh ts) }
    | EmptyCut -> { t with data = Cut m }
    | _ -> t
  in match c.data with
  | Fact t -> (refresh t, [])
  | Rule (h, b) -> (refresh h, List.map refresh b)

let rec format_term t = format_term_data t.data
and format_term_data t =
  match t with
  | Var x -> x
  | Num n -> string_of_int n
  | Atom f when f.data = "#nil" -> "[]"
  | Atom f -> f.data
  | Sym (f, _) when f.data = "#cons" -> format_list t
  | Sym (f, ts) -> Printf.sprintf "Sym(%s(%s))" f.data (String.concat ", " (List.map format_term ts))
  | _ -> ""
  and format_list t =
    let rec aux t acc =
      match t with
      | Atom f when f.data = "#nil" -> acc
      | Sym (f, [t1; t2]) when f.data = "#cons" -> aux t2.data (t1.data :: acc)
      | _ -> assert false
    in let ts = aux t [] |> List.rev in
    List.map format_term_data ts
    |> String.concat ", "
    |> Printf.sprintf "[%s]"

let symarity t =
  let* t = deref t.data in
  match t with
  | Atom f -> return (f.data, 0)
  | Sym (f, ts) -> return (f.data, List.length ts)
  | Cut _ -> return ("#cut", -1)
  | _ -> raise Not_sym

let rec solve gs prog =
  match gs with
  | [] -> return ()
  | g :: gs -> 
    let* k = symarity g in
    let clauses = (match ArityMap.find_opt k prog with
    | Some xs -> xs
    | None -> []) in begin
    match g.data with
    | Cut m ->
      let* () = cut_to m in
      solve gs prog
    | Sym (ff, [t1; t2]) when ff.data = "is" ->
      let* y = deref t2.data in begin
      match y with
      | Sym (f, [t1'; t2']) ->
        let* n = eval_sym f.data t1'.data t2'.data in
        let* () = unify t1.data n in
        solve gs prog
      | Num _ ->
        let* () = unify t1.data t2.data in
        solve gs prog
      | _ -> fail
      end
    | Sym (ff, [t1; t2]) when Hashtbl.mem comp_map ff.data ->
      let* b = eval_comp ff.data t1.data t2.data in 
      if b then solve gs prog else fail
    | _ ->
      let* m = mark_cut () in
      let* c = select_clause clauses in
      let (h, b) = refresh_clause c m in
      let* () = unify h.data g.data in
      solve (b @ gs) prog
    end

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
  match subst with
  | [] -> print_endline "true"
  | _ -> 
    subst
    |> List.map (fun (v, t) -> sprintf "%s = %s" v (format_term_data t))
    |> String.concat ", "
    |> print_endline

let rec repl prog =
  print_string "epi?- ";
  flush stdout;
  try
    let query = Parser.parse_query stdin in
    let vars = get_query_vars query in
    let m =
      let* () = solve query prog in
      let* subst = get_subst vars in
      return subst
    in let results = run m in
    let rec handle s =
      match s () with
      | Seq.Nil -> print_endline "false.\n"
      | Seq.Cons (subst, rest) -> 
        print_subst subst;
        match input_line stdin with
        | "." -> ()
        | ";" -> handle rest
        | _ -> print_endline "Invalid input\n"
    in handle results; repl prog
  with
  | Errors.Parse_error (pos, reason) ->
    Printf.printf "Error: Parsing error at position %d:%d: %s\n"
    pos.Ast.start.pos_lnum
    (pos.Ast.start.pos_cnum - pos.Ast.start.pos_bol)
    (match reason with
    | EofInComment -> "EOF in comment"
    | InvalidNumber n -> Printf.sprintf "Invalid number: %s" n
    | InvalidChar c -> Printf.sprintf "Invalid character: %c" c
    | UnexpectedToken tok -> Printf.sprintf "Invalid token: %s" tok);
    repl prog
  | Not_sym -> 
    Printf.printf "Error: Goal is not a symbol or atom\n";
    repl prog

let () = 
  let open Printf in
  match Sys.argv with
  | [|_; fname |] -> begin
    try 
      let program = Parser.parse_file fname in
      let predef = Parser.parse_file "predef.pl" in
      let f _ v1 _ = Some v1 in
      let m = ArityMap.union f (aritymap program) (aritymap predef) in
      printf "Epilog v1.1.0 | Łukasz Janicki UWr\n";
      repl m
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