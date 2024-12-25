# Epilog - what comes after Prolog
This somewhat pretentious title expresses a hope that I ultimately manage to turn this project into a working Prolog interpreter. It is part of my functional programming university class.

## What it does
~~So far it only reads a file and returns an abstract syntax tree, as long as the file contains a correct Prolog program.~~
Given two terms, Epilog now checks whether they are unifiable. If they are, the program terminates with no output. If not, it says so. 
One can manually show substitutions made by using the code for `show_term_data` and `show_term`, as well as some `printf`s.

## How do I run it?
This was built on OCaml version 5.1.1. It uses dune, ocamllex and ocamlyacc, so make sure you have those if you don't for some reason. If you do, in the main directory you can put your program (in place of program.pl) and run:
```
dune build
dune exec epilog -- [your program name]
```
For the example program.pl provided, the exec command is `dune exec epilog -- program.pl`.
~~It should print the AST to your terminal/specified output stream.~~
You can check if two terms are unifiable or not by writing them in program.pl in two consecutive lines as Prolog facts. These are, of course, more often than not, *incorrect Prolog programs*, but they are still *correctly parseable* for Epilog's purposes.
______

If you're interested in seeing how this project came about, you can view the Project Diary or the commit history.