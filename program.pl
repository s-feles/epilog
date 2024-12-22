append(nil, Xs, Xs).
append(cons(H, Xs), Ys, cons(H, Zs)) :- append(Xs, Ys, Zs).

select(H, cons(H, T), T).
select(X, cons(H, T), cons(H, R)) :- select(X, T, R).

perm(nil, nil).
perm(Xs, cons(Y, Zs)) :-
    select(Y, Xs, Ys),
    perm(Ys, Zs).