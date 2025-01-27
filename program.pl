select(H, cons(H, T), T).
select(X, cons(H, T), cons(H, R)) :- select(X, T, R).

perm(nil, nil).
perm(Xs, cons(Y, Zs)) :- select(Y, Xs, Ys), perm(Ys, Zs).

append([], Xs, Xs).
append([H|Xs], Ys, [H|Zs]) :- append(Xs, Ys, Zs).

len([], 0).
len([_|Xs], N) :- len(Xs, M), N is M+1.

not(G) :- G, !, fail.
not(_).

insert(X, [], [X]).
insert(X, [Y|Ys], [X, Y|Ys]) :- X < Y, !.
insert(X, [Y|Ys], [Y|Zs]) :- insert(X, Ys, Zs).

insort([], []).
insort([X|Xs], Zs) :- insort(Xs, Ys), insert(X, Ys, Zs).

fact(N, R) :- factorial(N, 1, R).
factorial(0, R, R) :- !.
factorial(N, Acc, Res) :- N > 0, N1 is N-1, Acc1 is Acc * N, factorial(N1, Acc1, Res).
% Example query: perm(cons(1, cons(2, cons(3, nil))), X).