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
```ocaml
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

## Day 21
With the backtracking monad in place, implemented some functions useful for Prolog interpretation: nondeterministic clause selection, replacing variable names with fresh ones. Modified unification to utilize monadic `fail`. 
Removed the following:
- Mutable `data` field in `'a node` \[`ast.ml`\], a relic of past attempts of implementing mutability
- `Not_unifiable` exception, no longer useful with the backtracking monad
- `view` function; it was either that or writing `_.data` each time a `node` is encountered.
Added functions for showing terms and clauses, useful for testing of clause refreshing and selection.
Added an integer `ref` for the purposes of generating fresh variable names, along with a function that does.
Added a `solve` function (yet untested) that will hopefully correctly resolve a list of goals given in a query.
Added testing of the `select_clause` function. Here is the code for `refresh_clause` testing:
```ocaml
let program = Parser.parse_file fname in
      printf "refresh_clause test\n";
      printf "Original program:\n";
      List.iter (fun c -> show_clause c; print_newline ()) program;
      printf "\nRefreshed program:\n";
      let refreshed = List.map refresh_clause program in
      List.iter (fun (h, b) ->
        printf "%s" (show_term h);
        printf " :- ";
        printf "%s\n" (String.concat ", " (List.map show_term b)))
        refreshed;
```
One can replace with it the code inside the `try` block in the main function if one wishes to test the refreshing and fresh variable name generation.

Implemented substitution recovery, which means Epilog now can output the result of a successful computation.
Implemented a REPL with an interactive environment. Epilog now takes queries from standard input when run.
Fixed a problem with dereferencing (symbols weren't dereferenced properly) that was affecting the goal resolution process.
**Epilog is now a working Prolog interpreter**, though with somewhat dire functionality. It recognizes no syntactic sugars, the cut or arithmetic. This is, of course, room for great improvement, on which I will start working shortly. I guess I could call it a *v1.0*, though.

## Day 25
Implemented arithmetic operations and the `is` predicate correct enough to program a working list length predicate. Next up are probably boolean operators or lists.

## Day 27
Implemented list syntax: `[X, Y, Z]`, `[X|Xs]`, `[X, Y|Zs]` are now all supported by Epilog. Contents of `program.pl` can now be rewritten using regular list syntax and are properly evaluated by Epilog. What remains is printing - when using list notation, results are displayed using `#cons` and `#nil`, signed with a hash not to prevent the user from defining `cons` and `nil` symbols of their own. The display is, of course, to be fixed.

In the meantime I moved on to implementing the cut. This required an overhaul of the backtracking monad and is done on the branch `cut`, a few commits ahead of `main`. When (if) the implementation is correct, the branches will be merged. Further updates of README and this diary will be on the branch `cut` for now, except for a print fix on `main`.

Fixed printing lists.

Implemented the new monad `BT` first as a backtracking monad with cut functionality. It is a lazy list of delayed computations whose elements (nodes) can either be:
- `Nil`, signifying the list is empty
- `NilCut`, signifying the list is empty, but holding a marker that passes down information about an ongoing cut when appending two lists
- `Cons` holding an element and the rest of the list.
An element of the list is either a cut marker (`Mark of mark`) or a lazy computation (`Comp of (unit -> 'a)`). 

The function `mark_cut` places a freshly generated marker under a computation that returns the marker itself. Generation of fresh markers is obscured from the user by the module interface, as is the marker type.

The function `cut_to` takes a marker and returns a unit computation followed by a `NilCut`. Since it is monadic, it must be bound; since `bind` calls `concat_map`, the `NilCut` will be appended to another list and the cut is performed: computations are dropped from the stack until a matching marker is encountered.

Initial simple tests showed correct behaviour, but requiring careful marker placement. It shouldn't be particularly surprising that the following fragments:
```ocaml
    let* m = mark_cut () in
    let* b1 = flip in
    let* b2 = flip in
    [...]
```
_______
```ocaml
    let* b1 = flip in
    let* m = mark_cut () in
    let* b2 = flip in
    [...]
```
_______
```ocaml
    let* b1 = flip in
    let* b2 = flip in
    let* m = mark_cut () in
    [...]
```
will produce much varying results after calling `cut_to m`.

## Day 28
Expanded the backtracking monad to include state. Changed the lazy list type from `'a t` to `'a bt`; the monadic type is now `type 'a t = state -> ('a * state) bt`, resembling the `RefMonad` type `state -> ('a * state) Seq.t` with the described additional functionality.

Integrated the `BT` monad into Epilog; the previous functionalities are all retained and the interpreter works as intended.

Soon the cut will be implemented into the lexer, parser and interpreter itself.

# Day 36
The projects seems to be coming to a close.
The cut has been implemented and tested. It is correct by lack of counterexample so far.
Implemented quick predicate base search by employing a map that binds a `(symbol, arity)` pair to a list of clauses that have potentially unifiable heads. This greatly reduces the clause selection time when the predicate base is large.

Overall, Epilog supports:
- Arithmetic and `is`
- Boolean operators\*
- Cut and negation as failure
- Prolog list syntax
- Checking goals for sensibility (will fail if a goal is not a symbol or atom)
- Quick search of predicate base.

\* - There are some cases to be considered with boolean operators.
`equals(X, Y)` is an arithmetic equality symbol (in particular it is symmetric), which is a predefined predicate, though it doesn't support infix notation.
`X is Y` works correctly unless negated.
`X = Y` parses to `eq(X, Y)`, which is a predefined predicate checking for structural equality of both sides.
`X < Y` and `X > Y` are comparison tests that can be places on the right hand side of a clause, but can produce unreliable results when called as goals (for example `not(X < Y)` always succeeds, regardless of what one puts in place of X and Y).
`lt(X, Y)` and `gt(X, Y)` are predefined comparison clauses that produce reliable results when called as goals (e. g. `not(lt(1, 2))` fails).

Epilog does not have garbage collection or Huet unification, both of which would have been good performance improvements, but I ended up not exploring these opportunities as of now.

I think this is about it for me. Epilog v1.1. I learned a lot on the way. Maybe I will expand it in my free time, when I finally get some.