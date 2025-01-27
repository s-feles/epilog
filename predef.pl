eq(X, X).
lt(X, Y) :- X < Y.
gt(X, Y) :- X > Y.

not(G) :- G, !, fail.
not(_).