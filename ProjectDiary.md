# Epilog Project Diary
~~It should probably be called a journal.~~
In fact it is a diary.

## Day 1
Managed to set up the Dune project after a few hours of battling documentation.
Implemented functions for printing abstract syntax in lieu of `deriving show`.

## Day 3
Implemented a (as it turned out, faulty) version of Robinson's unification algorithm. Experimented with mutability of the data field of the 'a node type and with using a ref in the term type. Both failed as the substitutions during unification were not global; this allowed for 'unifications' that would substitute e.g. a symbol for a variable, then later an atom for the same variable.

## Day 4
Came up with and implemented a reference (mutability) monad in the file refMonad.ml. It contains a functor that takes a value type and a Map.OrderedType to return a state monad that supports creating and managing references under a given key. Will explore if and how it helps with unification.

Implemented unification using the monad after its slight modification. There is much room for improvement in terms of shortening paths and in general better management of the substitutions. Perhaps I can now start implementing backtracking functionality. State recovery will probably be a major challenge.

## Day 20
After a long break, came back to the project.
Implemented backtracking in the state monad.
Turns out, state recovery was not that challenging to implement after carefully considering the idea. The version of the backtracking monad in RefMonad.ml supports state recovery across branches, which is visible in the definition of the `'a t = state -> ('a * state) Seq.t` (also, for ease of code inspection, changed the definition of the monadic type to one where `state` is `Value.t KeyMap.t`). One can see that each calculation in the resulting `Seq.t` is tied to its own individual state and these states do not affect each other across different calculations.
This should allow further progress towards correct Prolog interpretation. So far, only minor changes to the unification function were made (due to the monadic type change). Unification does not utilize full backtracking possibilities now nor will it in the future; it remains a single calculation. It could, obviously, use the `fail` function instead of throwing an exception, but for the purpose of Epilog's current functionality, the exception was left in. This will be changed.

The file refMonad.ml could be moved to the src directory and added to Epilog's library. It is left in the main project directory for ease of REPL testing. If one wishes to examine the behaviour of the state across branches, one can run the following in utop:
```
#use "refMonad.ml";;

module M = RefMonad (struct type t = int end) (Int);;

open M;;

let (let*) = bind;;

let test = 
    let* r = new_ref 0 1 in
    let* () = set r 10 in
    let* b = flip in
    if b then
        let* () = set r 20 in
        let* v = get r in
        return v
    else
        let* v = get r in
        return v;;

run test |> List.of_seq;;
```
The last line should output `[ Some 20; Some 10 ]`.