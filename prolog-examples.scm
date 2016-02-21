;;;
;;; Prolog examples.
;;; Please see the manual for help with the syntax.
;;;

(define write-line
  (lambda args
    (for-each (lambda (x)
                (display x)
                (display " "))
              args)
    (newline)))


;; Prolog program: 
;; a(X) :- b(X), !, c(X).
;; b(1).
;; b(2).
;; c(2).
;;
;; We ask a(X), it succeeds for X=1, but cannot
;; backtrack so it fails!
(prolog+cut '(( (a ?x) (b ?x) ! (c ?x) )
              ( (b 1) )
              ( (b 2) )
              ( (c 2) ))
            '((a ?x)))


;; Same as in previous example, but we do not use
;; the cut, so it succeeds.
;; Prolog program: 
;; a(X) :- b(X), !, c(X).
;; b(1).
;; b(2).
;; c(2).
;;
;; We ask a(X). Internally, it succeeds for X=1, but since this
;; doesn't work, Prolog backtracks and tries X=2, then succeeds.
(pure-prolog '(( (a ?x) (b ?x) (c ?x) )
               ( (b 1) )
               ( (b 2) )
               ( (c 2) ))
             '((a ?z)))

;; Prolog program:
;; f(0).
;; f(Z) :- g(Z).
;; p(A) :- f(A).
;; g(10).
;;
;;; f(X).
;;; the answer is the substitution X->0.
(pure-prolog '(( (f 0)  )
               ( (f ?z) (g ?z) )
               ( (p ?a) (f ?a) )
               ( (g 10) ))
             '((f ?x)))


;; Prolog program:
;; f(0).
;; f(Z) :- g(Z).
;; p(Z,Y) :- f(Z),g(Y).
;; g(10).
;;
;;; p(10,10) --> succeeds
;;; p(0,10)  --> also succeeds
;;; p(3,10)  --> fails
(pure-prolog '(( (f 0) )
               ( (f ?z) (g ?z))
               ( (p ?z ?y) (f ?z) (g ?y))
               ( (g 10) ))
             '((p 10 10)))

(pure-prolog '(( (f 0) )
              (  (f ?z) (g ?z))
              (  (p ?z ?y) (f ?z) (g ?y))
              (  (g 10) ))
             '((p 0 10)))

(pure-prolog '(( (f 0)  )
               ( (f ?z) (g ?z))
               ( (p ?z ?y) (f ?z) (g ?y))
               ( (g 10) ))
             '((p 3 10)))

;; f(0).
;; f(Z) :- g(Z).
;; h(3).
;; h(4).
;; p(Z,Y,S) :- f(Z),g(Y),h(S)
;; g(10).
;;
;;; p(10,D,A)
;;; succeeds with {D->10, A->3}
;;;
;;; if we put the additional goal q(A), then
;;; p(10,D,A), q(A)
;;; succeeds with {D->10, A->4}
(pure-prolog '(( (f 0) )
               ( (f ?z) (g ?z))
               ( (h 3) )
               ( (h 4) )
               ( (p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
               ( (g 10) ))
             '((p 10 ?d ?a)))

(pure-prolog '(( (f 0) )
               ( (f ?z) (g ?z))
               ( (h 3) )
               ( (h 4) )
               ( (q 4) )
               ( (p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
               ( (g 10) ))
             '((p 10 ?d ?a) (q ?a)))

(pure-prolog '(( (f 0) )
               ( (f ?z) (g ?z))
               ( (h 3) )
               ( (h 4) )
               ( (p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
               ( (g 10)  ))
             '((p 10 ?d ?a) (h ?a)))


;; Changing a variable name in the goal gives the same result as
;; above:
(pure-prolog '(( (f 0) )
              ( (f ?z) (g ?z))
              ( (h 3) )
              ( (h 4) )
              ( (p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
              ( (g 10) ))
            '( (p 10 ?y ?s) (h ?s) )
            )



;; Fails
(prolog+cut '(( (a ?x) (b ?x) ! (c ?x) )
              ( (b 1) )
              ( (b 2) )
              ( (c 2) ))
            '((a ?x)))

;; Succeeds with Z=2
(pure-prolog '(( (a ?x) (b ?x) (c ?x) )
               ( (b 1) )
               ( (b 2) )
               ( (c 2) ))
             '((a ?z)))

;; Succeeds with Z=2
(pure-prolog '(( (a ?x) (b ?x) (c ?x) )
               ( (b 1) )
               ( (b 2) )
               ( (c 2) ))
             '((a ?z)))


;; First prints "Grandson is: johnny", then returns the
;; substitution Who=johnny.
(prolog+built-ins '( ((father john johnny))
                     ((father old-john john))
                     ((grandpa ?a ?b) (father ?a ?x) (father ?x ?b)) )
                  '( (grandpa old-john ?who)  (write "Grandson is: " ?who) ))

;; First prints "Grandson is: johnny", then returns the
;; substitution Who=johnny.
(prolog+scheme '( ((father 'john 'johnny))
                  ((father 'old-john 'john))
                  ((grandpa ?a ?b) (father ?a ?x) (father ?x ?b)) )
               '( (grandpa 'old-john ?who)  ( (write-line "Grandson is: " ?who) )))

;; Prints "5 5" then succeeds with X=Y=5
(prolog+scheme '( ((a 5))
                  ((b 3))
                  ((b 5)))
               '( (a ?x) (b ?y) ((= ?x ?y)) ((write-line ?x " " ?y))))

;; Succeeds
(prolog+scheme '( )
               '( ((= 5 5))))

;; Fails
(prolog+scheme '( )
               '( ((= 2 5))))


;; The variable ?y is not defined, so this signals an error:
(prolog+local '( ((f ?x ?y)
                  ((= ?y (* 2 ?x)))
                  ((write-line 'OK: ?y))))
              '( (f 3 ?a) ))

;; Succeeds with A=6
(prolog+local '( ((f ?x ?y)
                  (is ?y (* 2 ?x))
                  ((write-line 'OK: ?y))))
              '( (f 3 ?a) ))

;; This solves the Towers of Hanoi problem, in Prolog.
(define prolog-hanoi
  '(((hanoi ?n) (hanoi-aux ?n 3 1 2))
    ((hanoi-aux 0 ?a ?b ?c) ! )
    ((hanoi-aux ?n ?a ?b ?c)
     (is ?nn (- ?n 1))
     (hanoi-aux ?nn ?a ?c ?b)
     (mova ?a ?b)
     (hanoi-aux ?nn ?c ?b ?a))
    ((mova ?de ?para)
     ((display ?de))
     ((display " --> "))
     ((display ?para))
     ((newline)))))

;; We call it for 3 discs:
(prolog+cut prolog-hanoi '((hanoi 3)))

;; It wil print the solution, and then succeed:
;; 3 --> 1
;; 3 --> 2
;; 1 --> 2
;; 3 --> 1
;; 2 --> 3
;; 2 --> 1
;; 3 --> 1
;; ()


;; Prolog program:
;; f(X) :- asserta(h(1)).
;; g(X) :- h(X).
;;
;; f(W), g(Z) --> succeeds with Z=1
(prolog+meta '(( (f ?x) (asserta (h 1)))
               ( (g ?x) (h ?x)))
             '((f ?w) (g ?z)))

(define prolog-assert-ok '( ((f ?x) (g ?x)
                             (asserta (h 3))
                             (h ?x))
                            ((g 2))
                            ((g 3))))

;; Succeeds with A=3
(prolog+meta prolog-assert-ok '((f ?a)))

(define prolog-assert-fail '( ((f ?x) (h ?x)
                                    (asserta (h 3))
                                    (g ?x))
                            ((g 2))
                            ((g 3))))

;; Fails:
(prolog+meta prolog-assert-fail '((f ?a)))


;; Prolog program:
;; f(2).
;; f(3).
;; g(1) :- retract(f(2)).
;; g(1) :- f(3).
(define prolog-retract '( ((f 2))
                          ((f 3))
                          ((g 1) (retract ((f 2))))
                          ((g 1) (f 3))))

;; f(X) succeeds with X=2.
(prolog+meta prolog-retract '((f ?x)))

;; g(X) will cause retract(f(2)) to be evaluated, so
;; g(1), f(X) succeeds with X=3.
(prolog+meta prolog-retract '((g 1) (f ?x)))

;; The Prolog with cut has all features from the previous ones:
(prolog+cut prolog-retract '((g 1) ! (f ?x)))

;; f(2), g(1) succeeds, because f(2) is evaluated before
;; g(1).
(prolog+meta prolog-retract '((f 2) (g 1)))

;; If we evaluate g(1) first, it fails:
(prolog+meta prolog-retract '((g 1) (f 2)))

;; Wrror: ?b is not bound:
(prolog+cut '()
             '((is ?a 5)
               (is ?x (+ ?a ?b))))

;; We can use Scheme lists in Prolog. This is append/2:
(define prolog-append '( ((append (?x . ?y) ?z (?x . ?w))
                          (append ?y ?z ?w))
                         ((append () ?x ?x))))

;; Succeeds with A=(0 1)
(prolog+cut prolog-append
             '( (append (0) (1) ?a) ))

;; Succeeds with A=(1)
;; (this one is very nice, and shows some cool Prolog programming techniques)
(prolog+cut prolog-append
             '( (append (0) ?a (0 1)) ))

;; Succeeds with A=(1) and D=0.
(prolog+cut prolog-append
             '( (append (0) ?a (?d 1) )))


;; Difference lists:
(define prolog-difflist '( ((count (- ?x ?x1) 0)
                            ((unify '?x '?x1))
                            !)
                           ((count (- (?h . ?t) ?t1) ?n)
                            (count (- ?t ?t1) ?m)
                            (is ?n (+ ?m 1)))))

;; Succeeds with N=2
(prolog+cut prolog-difflist
             '( (count (- (1 2 . ?a) ?a) ?n) ))

;; Succeeds, but with empty sub (calls to unify via Scheme
;; FFI do NOT add bindings)
(prolog+cut '() '( ((unify '?a '?b))))
(prolog+cut '() '( ((unify '?a 'b))))

;; Fails:
(prolog+cut '() '( ((unify 'a 'b))))

;; This will loop forever
(prolog+cut '(((rep))
               ((rep) (rep)))
             '( (rep) ((write-line 'z)) ((fail)) ))

;;not(P) :- call(P), !, fail.
;;not(P).
(define pfail (lambda ()  #f))

;; Fails:
(prolog+cut '(((f) (a) ! (b))
              ((a)))
            '((f)))

;; Succeeds with NO substitution
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (not (f ?z)))))

;; Fails:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (not (not (f ?z))))))

;; Succeeds:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
              ((not ?x))
              ((f a)) )
            '((not (not (not (not (f ?z)))))))

;; fails:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (not (not (not (not (f ?z))))))))

;; Succeeds with ?z -> a
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((f ?z)))

;; Fails:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (f ?z))))

;; Fails:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (f a))))

;; Succeeds:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x))
               ((f a)) )
             '((not (f b))))

;; Fails:
(prolog+cut '() '( ((pfail)) ))

;; Succeeds:
(prolog+cut '(((not ?x) ?x ! ((pfail)))
               ((not ?x)))
             '((not ((pfail)))))

;; Fails:
(prolog+cut '(((go ?x) ?x)
               ((f a) ((write-line 'HELLO))))
             '( (go ((pfail))) ))

;; Succeeds:
(prolog+cut '(((f a) (g b))
               ((g b) (h c))
               ((h c)))
             '( (f a) ))

;; Succeeds:
(prolog+cut '(((f a)))
            '((f a)))

;; Fails:
(prolog+cut '(((f a)))
            '((f b)))

;; Fails:
(prolog+cut '(( (a ?x) (b ?x) ! (c ?x) )
               ( (b 1) )
               ( (b 2) )
               ( (c 2) ))
             '((a ?x)))

;; f(0).
;; f(Z) :- g(Z).
;; p(Z,Y) :- f(Z),g(Y).
;; g(10)
;;
;;; p(10,10)  --> also succeeds with p(0,10)
(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((p ?z ?y) (f ?z) (g ?y))
              ((g 10)))
            '((p 10 10)))

(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((p ?z ?y) (f ?z) (g ?y))
              ((g 10)))
            '((p 0 10)))


;;; p(3,10)    --> fails
(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((p ?z ?y) (f ?z) (g ?y))
              ((g 10)))
             '((p 3 10)))

;; f(0).
;; f(Z) :- g(Z).
;; h(3).
;; h(4).
;; p(Z,Y,S) :- f(Z),g(Y),h(S)
;; g(10).
;;
;;; p(10,D,A)
;; Succeeds with {D->10, A->3}, {p(10,Y,S)}
(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((h 3))
              ((h 4))
              ((p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
              ((g 10)))
            '((p 10 ?d ?a)))

;; D->10, A->4
(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((h 3))
              ((h 4))
              ((q 4))
              ((p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
              ((g 10)))
             '((p 10 ?d ?a) (q ?a)))


;; Succeeds, A->1
(prolog+cut '(((f 0))
              ((f 1))
              ((g 1))
              ((h ?x) (f ?x) (g ?x)))
            '((f ?a) (h ?a)))

;; Prolog program:
;; f(0).
;; f(1).
;; g(1).
;; h(X) :- f(X), g(X).
;;
;; h(A), !, f(A) succeeds with A=1:
;; - h(X) depends on f(X) and g(X), so
;; prolog tries X=0, but fails for g(X),
;; backtracks, and finds X=1. THEN it
;; goes past the cut, and finds f(A),
;; which is true.
(prolog+cut '(((f 0))
              ((f 1))
              ((g 1))
              ((h ?x) (f ?x) (g ?x)))
            '((h ?a) ! (f ?a)))

;; If we change the order in the goal, Prolog fails:
(prolog+cut '(((f 0))
               ((f 1))
               ((g 1))
               ((h ?x) (f ?x) (g ?x)))
             '((f ?a) ! (h ?a)))

;; f(0).
;; f(Z) :- g(Z).
;; h(3).
;; h(4).
;; p(Z,Y,S) :- f(Z),g(Y),h(S)
;;
;;; p(10,D,A)
;; retorna {D->10, A->3}, {}}
(prolog+cut '(((f 0))
              ((f ?z) (g ?z))
              ((h 3))
              ((h 4))
              ((p ?z ?y ?s) (f ?z) (g ?y) (h ?s))
              ((g 10)))
            '((p 10 ?d ?a) (h ?a)))

;; We define a graph by declaring its edges, then
;; define a reach/2 predicate.
;;
;; edge(a,b).
;; edge(a,c).
;; edge(c,b).
;; edge(c,d).
;; edge(d,e).
;;
;; reach(A,B) :- edge(A,B).
;; reach(A,B) :- edge(A,X), reach(X,B).
(define graph '( ((edge a b))
                 ((edge a c))
                 ((edge c b))
                 ((edge c d))
                 ((edge d e))
                 ;;
                 ((reach ?a ?b) (edge ?a ?b))
                 ((reach ?a ?b) (edge ?a ?x)
                                (reach ?x ?b))))

(pure-prolog graph '( (reach b e) ))

;; Succeeds, X=1
(pure-prolog '(((f 1))
               ((f 2))
               ((f 3)))
             '((f ?x)))

;; Brings other solutions (X=2, X=3)
(amb+)

;; Prints two substitutions (1, 2) then fails.
(define l '())

(prolog+scheme '(((f 1))
                 ((f 2)))
               '((f ?x) ((set! l (write-line ?x))) ((pfail))))
