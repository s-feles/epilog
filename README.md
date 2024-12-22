# Epilog - what comes after Prolog
This somewhat pretentious title expresses a hope that I ultimately manage to turn this project into a working Prolog interpreter. It is part of my functional programming university class.

## What it does
So far it only reads a file and returns an abstract syntax tree, as long as the file contains a correct Prolog program.

## How do I run it?
This was built on OCaml version 5.1.1. It uses dune, ocamllex and ocamlyacc, so make sure you have those if you don't for some reason. If you do, in the main directory you can put your program (in place of program.pl) and run:
```
dune build
dune exec epilog -- [your program name]
```
It should print the AST to your terminal/specified output stream.

______

If you're interested in seeing how this project came about, you can view the Project Diary or the commit history.