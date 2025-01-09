module RefMonad (Value : sig type t end)  (Key : Map.OrderedType) : sig
  type 'a t
  type key_ref

  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val new_ref : Value.t -> key_ref -> key_ref t
  val get : key_ref -> Value.t option t
  val set : key_ref -> Value.t -> unit t
  val fail : 'a t
  val flip : bool t
  val run : 'a t -> 'a Seq.t
end with type key_ref = Key.t = struct
  module KeyMap = Map.Make(Key)

  type 'a t = Value.t KeyMap.t -> ('a *  Value.t KeyMap.t) Seq.t
  type key_ref = Key.t

  let return x = fun st -> Seq.cons (x, st) Seq.empty

  let bind m f = fun st ->
    Seq.concat_map (fun (x, st) -> f x st) (m st)

  let fail = fun _ -> Seq.empty

  let flip = fun st -> List.to_seq [ true, st; false, st ]
  
  let new_ref (v : Value.t) (k : key_ref) = fun s ->
    Seq.cons (k, KeyMap.add k v s) Seq.empty
  
  let get r = fun s ->
    Seq.cons (KeyMap.find_opt r s, s) Seq.empty
  
  let set r v = fun s ->
    Seq.cons ((), KeyMap.add r v s) Seq.empty
  
  let run m = Seq.map fst (m KeyMap.empty)
end