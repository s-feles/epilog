module BT (Value : sig type t end) (Key : Map.OrderedType) : sig
  type 'a t
  type mark
  type key_ref

  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val fail : 'a t
  val flip : bool t
  val get : key_ref -> Value.t option t
  val set : key_ref -> Value.t -> unit t
  val mark_cut : unit -> mark t
  val cut_to : mark -> unit t
  val run : 'a t -> 'a Seq.t
end with type key_ref = Key.t = struct
  module KeyMap = Map.Make(Key)
  type key_ref = Key.t
  type state = Value.t KeyMap.t
  type mark = int

  type 'a elem =
  | Mark of mark
  | Comp of (unit -> 'a)

  type 'a bt = unit -> 'a node
  and 'a node = 
    | Nil
    | NilCut of mark
    | Cons of 'a elem * 'a bt

  type 'a t = state -> ('a * state) bt

  let fresh = ref 0
  let fresh_mark () =
    let m = !fresh in
    fresh := m + 1;
    m
  
  let fail = fun _ -> fun () -> Nil

  let return x : 'a t = fun st -> fun () -> Cons (Comp (fun () -> (x, st)), fun () -> Nil)

  let flip : bool t = fun st -> fun () -> 
    Cons (Comp (fun () -> (true, st)), fun () -> Cons (Comp (fun () -> (false, st)), fun () -> Nil))

  let mark_cut () : mark t = 
    let m = fresh_mark () in
    fun st -> fun () -> Cons (Comp (fun () -> (m, st)), fun () -> Cons (Mark m, fun () -> Nil))
  
  let cut_to (m : mark) : unit t = fun st ->
    fun () -> Cons (Comp (fun () -> ((), st)), fun () -> NilCut m)
  
  let rec drop_until m xs =
    fun () ->
    match xs () with
    | Nil -> NilCut m
    | NilCut _ -> NilCut m
    | Cons (Mark m', xs) when m' = m -> Cons(Mark m, xs)
    | Cons (_, xs) -> drop_until m xs ()
  
  let rec append (xs : 'a bt) (ys: 'a bt) : 'a bt =
    fun () ->
    match xs () with
    | Nil -> ys ()
    | NilCut m -> drop_until m ys ()
    | Cons (x, xs) -> Cons(x, append xs ys)
  
  let rec concat_map (xs : 'a bt) (f : 'a -> 'b bt) : 'b bt =
    fun () -> 
    match xs () with
    | Nil -> Nil
    | NilCut m -> NilCut m
    | Cons (Mark m, xs) -> Cons (Mark m, concat_map xs f)
    | Cons (Comp x, xs) -> append (f (x ())) (concat_map xs f) ()
  
  let bind (m : 'a t) (f: 'a -> 'b t) : 'b t = fun st ->
    concat_map (m st) (fun (x, st) -> f x st)
  
  let get r = fun st -> 
    fun () -> Cons (Comp (fun () -> KeyMap.find_opt r st, st), fun () -> Nil)
  
  let set r v : unit t = fun s ->
    fun () -> Cons (Comp (fun () -> (), KeyMap.add r v s), fun () -> Nil)
  
  let run (m: 'a t) : 'a Seq.t =
    fun () ->
    let m' = m KeyMap.empty () in
    let rec f = function
    | Nil -> Seq.Nil
    | NilCut _ -> assert false
    | Cons (Mark _, xs) -> f (xs ())
    | Cons (Comp x, xs) -> Seq.cons (fst (x ())) (fun () -> f (xs ())) ()
    in f m'
end