select(H, cons(H, T), T).
select(X, cons(H, T), cons(H, R)) :- select(X, T, R).

perm(nil, nil).
perm(Xs, cons(Y, Zs)) :- select(Y, Xs, Ys), perm(Ys, Zs).

append(nil, Xs, Xs).
append(cons(H, Xs), Ys, cons(H, Zs)) :- append(Xs, Ys, Zs).

len(nil, 0).
len(cons(_, Xs), N) :- len(Xs, M), N is M+1.
% Example query: perm(cons(1, cons(2, cons(3, nil))), X).