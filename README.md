# Epilog - what comes after Prolog
This somewhat pretentious title expresses a hope that I ultimately manage to turn this project into a working Prolog interpreter. It is part of my functional programming university class.

## What it does
~~So far it only reads a file and returns an abstract syntax tree, as long as the file contains a correct Prolog program.~~
~~Given two terms, Epilog now checks whether they are unifiable. If they are, the program terminates with no output. If not, it says so. ~~
With new functions implemented, Epilog should now take a Prolog program (not necessarily syntactically correct, but parseable) and essentially print it out twice; this is because the current main portion of the `epilog.ml` file tests the `select_clause` function.

## How do I run it?
This was built on OCaml version 5.1.1. It uses dune, ocamllex and ocamlyacc, so make sure you have those if you don't for some reason. If you do, in the main directory you can put your program (in place of program.pl) and run:
```
dune build
dune exec epilog --profile release [your program name]
```
For the example program.pl provided, the exec command is `dune exec epilog --profile release program.pl`.
The `--profile release` flag is needed for Dune to stop screaming about unused functions for now.
~~It should print the AST to your terminal/specified output stream.~~
~~You can check if two terms are unifiable or not by writing them in program.pl in two consecutive lines as Prolog facts. These are, of course, more often than not, *incorrect Prolog programs*, but they are still *correctly parseable* for Epilog's purposes.~~
Given a Prolog program, Epilog will parse it, print it out and then create a monadic calculation (selecting clauses), which is then run and printed out. The output should look like:
```
select_clause test
Original program:
[facts and rules from a given Prolog program]

Selected clauses:
[identical output as above]
```
The two outputs being identical shows that the `select_clause` function correctly chooses every possible clause.
The project diary contains code for testing the refreshing function.
______

If you're interested in seeing how this project came about, you can view the Project Diary or the commit history.