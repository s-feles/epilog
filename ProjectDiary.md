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