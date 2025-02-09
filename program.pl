select(H, [H|T], T).
select(X, [H|T], [H|R]) :- select(X, T, R).

perm([], []).
perm(Xs, [Y|Zs]) :- select(Y, Xs, Ys), perm(Ys, Zs).

append([], Xs, Xs).
append([H|Xs], Ys, [H|Zs]) :- append(Xs, Ys, Zs).

len([], 0).
len([_|Xs], N) :- len(Xs, M), N is M + 1.

insert(X, [], [X]).
insert(X, [Y|Ys], [X, Y|Ys]) :- X < Y, !.
insert(X, [Y|Ys], [Y|Zs]) :- insert(X, Ys, Zs).

insort([], []).
insort([X|Xs], Zs) :- insort(Xs, Ys), insert(X, Ys, Zs).

fact(N, R) :- fact(N, 1, R).
fact(0, R, R) :- !.
fact(N, Acc, Res) :- N > 0, N1 is N - 1, Acc1 is Acc * N, fact(N1, Acc1, Res).

p(a) :- !.
p(b).
q(X) :- p(X).
q(c).

r(a).
r(b).
s(c).
s(d).
t(X, Y) :- r(X), !, s(Y), !.
% Example query: perm(cons(1, cons(2, cons(3, nil))), X).