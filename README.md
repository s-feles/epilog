# Epilog - what comes after Prolog
This somewhat pretentious title expresses a hope that I ultimately manage to turn this project into a working Prolog interpreter. It is part of my functional programming university class.

## What it does
Reads a Prolog program from a file and opens an interactive environment in which the user can query the program, quite similarly to SWI-Prolog. Uses a backtracking monad with mutable state to perform unification and goal resolution.
Currently Epilog only supports the most basic Prolog functionality. It does not recognize the unary negation `\+`, the cut `!` or the `[H|T]` list syntax, to be implemented soon.

## How do I run it?
This was built on OCaml version 5.1.1. It uses dune, ocamllex and ocamlyacc, so make sure you have those if you don't for some reason. If you do, in the main directory you can put your program (in place of program.pl) and run:
```
dune build
dune exec epilog [your program name]
```
For the example program.pl provided, the exec command is `dune exec epilog program.pl`.
~~The `--profile release` flag is needed for Dune to stop screaming about unused functions for now.~~
Once the program is loaded, it can be queried in an identical fashion to SWI-Prolog.
Example query and response could look like:
```
?- perm(cons(1, cons(2, cons(3, nil))), X).
X = cons(1, cons(2, cons(3, nil)))
;
X = cons(1, cons(3, cons(2, nil)))
```
To exit Epilog, use `Ctrl+C`.
______

If you're interested in seeing how this project came about, you can view the Project Diary or the commit history.