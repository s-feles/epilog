module BT : sig
  type 'a t
  type mark

  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val fail : 'a t
  val flip : bool t
  val mark_cut : unit -> mark t
  val cut_to : mark -> unit t
  val run : 'a t -> 'a Seq.t
end = struct
  type mark = int

  type 'a elem =
  | Mark of mark
  | Comp of (unit -> 'a)

  type 'a t = unit -> 'a node
  and 'a node = 
    | Nil
    | NilCut of mark
    | Cons of 'a elem * 'a t
  let fresh = ref 0
  let fresh_mark () =
    let m = !fresh in
    fresh := m + 1;
    m
  
  let fail = fun () -> Nil
  let return x = fun () -> Cons (Comp (fun () -> x), fail)
  let flip = fun () -> Cons (Comp (fun () -> true), fun () -> Cons (Comp (fun () -> false), fail))
  let mark_cut () = 
    let m = fresh_mark () in
    fun () -> Cons (Comp (fun () -> m), fun () -> Cons (Mark m, fail))
  let cut_to (m : mark) =
    fun () -> Cons (Comp (fun () -> ()), fun () -> NilCut m)
  
  let rec drop_until m xs =
    fun () ->
    match xs () with
    | Nil -> NilCut m
    | NilCut _ -> NilCut m
    | Cons (Mark m', xs) when m' = m -> Cons(Mark m, xs)
    | Cons (_, xs) -> drop_until m xs ()
  
  let rec append xs ys =
    fun () ->
    match xs () with
    | Nil -> ys ()
    | NilCut m -> drop_until m ys ()
    | Cons (x, xs) -> Cons(x, append xs ys)
  
  let rec concat_map (xs : 'a t) (f : 'a -> 'b t) : 'b t =
    fun () -> 
    match xs () with
    | Nil -> Nil
    | NilCut m -> NilCut m
    | Cons (Mark m, xs) -> Cons (Mark m, concat_map xs f)
    | Cons (Comp x, xs) -> append (f (x ())) (concat_map xs f) ()
  
  let bind = concat_map
  
  let rec run m =
    fun () ->
    match m () with
    | Nil -> Seq.Nil
    | NilCut _ -> assert false
    | Cons (Mark m, xs) -> run xs ()
    | Cons (Comp x, xs) -> Seq.cons (x ()) (run xs) ()
end