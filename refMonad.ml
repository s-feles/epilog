module RefMonad (Value : sig type t end)  (Key : Map.OrderedType) : sig
  type 'a t
  type key_ref

  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t

  val new_ref : Value.t -> key_ref -> key_ref t
  val get : key_ref -> Value.t t
  val set : key_ref -> Value.t -> unit t
end = struct
  module KeyMap = Map.Make(Key)

  type 'a t = Value.t KeyMap.t -> 'a *  Value.t KeyMap.t
  type key_ref = Key.t

  let return x = fun s -> (x, s)
  let bind m f = fun s ->
    let (a, s) = m s in
    f a s
  
  let new_ref (v : Value.t) (k : key_ref) = fun s ->
    (k, KeyMap.add k v s)
  
  let get r = fun s ->
    (KeyMap.find r s, s)
  
  let set r v = fun s ->
    ((), KeyMap.add r v s)
end