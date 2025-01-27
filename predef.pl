eq(X, X).
lt(X, Y) :- X < Y.
gt(X, Y) :- X > Y.

equals(X, Y) :- M is X, M is Y.

not(G) :- G, !, fail.
not(_).