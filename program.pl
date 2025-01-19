select(H, [H|T], T).
select(X, [H|T], [H|R]) :- select(X, T, R).

perm([], []).
perm(Xs, [Y|Zs]) :- select(Y, Xs, Ys), perm(Ys, Zs).

append([], Xs, Xs).
append([H|Xs], Ys, [H|Zs]) :- append(Xs, Ys, Zs).

len([], 0).
len([_|Xs], N) :- len(Xs, M), N is M+1.
% Example query: perm([1, 2, 3], X).