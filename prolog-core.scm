;; This software is Copyright (c) Jeronimo C. Pellegrini, 2010-2016.
;;
;;  This program is free software; you can redistribute it and/or
;;  modify it under the terms of the GNU General Public License as
;;  published by the Free Software Foundation; either version 3 of the
;;  License, or (at your option) any later version.
;; 
;;  This program is distributed in the hope that it will be useful, but
;;  WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;;  General Public License for more details.
;; 
;;  You should have received a copy of the GNU General Public License
;;  along with this program; if not, write to:
;;    The Free Software Foundation, Inc.,
;;    51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

;; prolog.scm -- core of the the Prolog interpreter

(begin 
(cond-expand (mit         (define (interaction-environment) user-initial-environment))
             (sisc        (require-extension (srfi 1)))
             (else))

;; rules are lists, so we define better names for their head and tail.
(define rule-head   car)
(define rule-tail   cdr)

;; goals are lists, so we define better names for the next subgoal to be
;; selected and the rest of the subgoal
(define select-goal car)
(define next-goals  cdr)

;; renames one variable (matching symbol), adding a suffix tag.
;;
(define rename-one
  (lambda (var tag)
    (string->symbol
     (string-append
      (symbol->string var) "_"  (number->string tag)))))

;; Recurses through a structure, renaming all variables
;; (matching symbols), adding to them a suffix tag.
;;
(define rename-vars
  (lambda (vars tag)
    (cond ((pair? vars)
           (cons (rename-vars (car vars) tag)
                 (rename-vars (cdr vars) tag)))
          ((and tag (matching-symbol? vars))
           (rename-one vars tag))
          ((eqv? vars '!)
           (list '! (cdr amb+-set)))
          (else vars))))

;; a: head of clause to be unified. Example: '(f ?x)
;;
;; prog: the program. Example:
;;     '( (a ?z) ()
;;        (f 10) (y (a b) z (c d)) )) 
;;
;; Will return SUB and CLAUSE TAIL:
;;
;; (unifying-clause '(x ?a)
;;                  '( (x 5) (p ?z 1)  ))
;; 
;; (((?a . 5)) ((p ?z 1)))
;;
;; Here ((?a . 5)) is the substitution and
;; ((p ?z 1)) is the tail of the selected clause:
;;
(define unifying-clause
  (lambda (a rule)
    (if (null? rule)
        #f
        (let ((sub (unify a (rule-head rule))))
          (if sub
              (list sub (rule-tail rule))
              #f)))))

;; (unifying-clause '(x ?a)
;;                 '( (x 5) (p ?z 1)  ))
;; => (((?a . 5)) ((p ?z 1)))

;;(unifying-clause '(x ?a)
;;                 '( (x 5) ()  ))
;; => (((?a . 5)) (()))

;; the "sub/tail" structure is a list whose first element is a
;; substitution, so we define the following:
(define sub/tail->tail cadr)
(define sub/tail->sub  car)

;; Selects only the part of a substitution which is relevant
;; for a goal.
;;
;; s: subst.
;; g: goal.
;;
;; output: another subst., only for the variables in goal.
;;
;; (select-sub '( (?x 1)
;;                (?y 2)
;;                (?z 3) )
;;             '(f ?y 9 (a ?z 10 v)))
;;
;; ==> ((?z 3) (?y 2))
;;
(define select-sub
  (lambda (sub goal)
    (define relevant?
      (lambda (s)
        (and (occurs? (car s) goal '())
             (not (matching-symbol? (cdr s))))))
    (filter relevant? sub)))


;; for example,
;;(select-sub '( (?x . 1)
;;               (?y . 2)
;;               (?z . ?w)
;;               (?w . 10)
;;               (4  . 4))
;;            '( (f ?y 9) (a ?z 10 v)) )
;; ==> ((?y . 2))

;; Checks if a Scheme object occurs anywhere inside a structure
;; -- not necessarily a list.
;; Will also return #t if the object is eqv? to the structure.
;;
(define deep-occurs?
  (lambda (obj where)
    (cond ((pair? where)
           (or (deep-occurs? obj (car where))
               (deep-occurs? obj (cdr where))))
          (else (eqv? obj where)))))



;; THIS (resolve and pure-prolog) IS ONE STEP OF SLD-RESOLUTION
;;
;; Finds a unifying clause and returns:
;; - The substitution
;; - The goal after sub is applied
;;
;; goal: one atom: (f ?a 10 (g ?z))
;;
;; program:
;;         ( (p ?x 0) ((...)
;;                     (...))
;;           (p 0 ?y) ((...)) )
;;
;;
;; goal: the goal (list of terms). Doesn't change!
;;
;; res: resolvent (LIST of what still needs to prove in order to
;;      prove the goal).
;;
;; sub: the substitution that transforms the goal into a valid instance.
;;
;; tail: after finding A <- B1, B2, ..., with A unifying with the next resolvent
;;       clause, TAIL is the tail
;;       (B1, ...).     (see theta)
;;
;; theta: the substitution that unifies the next resolvent clause with one clause
;;        of the program (see tail)
;;
(define resolve
  (lambda (res sub tag goal prog)
    ;; this is best understood after reading chapter 4 of "The Art of Prolog",
    ;; by Sterling and Shapiro.
    (if (null? res)
        ;; if res is null there is nothing else to do; select the
        ;; relevant parts of the substitution, apply it to the
        ;; resolvent and return them.
        (list (select-sub sub goal) (apply-sub sub res))
        ;; the amb+-list below will include all program rules in the
        ;; amb set.
        (let ((rule (rename-vars (amb+-list prog) tag)))
          (if rule
              (begin
                ;; the following line does some "amb-magic". The
                ;; "require+" will find a rule whose head unifies with
                ;; the current goal.
                (require+ (unify (select-goal res) (rule-head rule)))
                (let ((sub+tail
                       (unifying-clause (select-goal res) rule)))
                  (let ((tail  (sub/tail->tail sub+tail))
                        (theta (sub/tail->sub sub+tail)))
                    ;; we apply theta to both the goal and to the
                    ;; current substitution.
                    (let ((new-sub (append theta (apply-sub theta sub))))
                      (let ((new-res
                             (apply-sub theta
                                        (append tail
                                                (next-goals res)))))
                        (list new-sub new-res))))))
              #f)))))

;; resolved is a list whose car is the substitution and whose tail
;; is the resolvent.
(define resolved->sub car)
(define resolved->res cadr)

;; this is the interpreter for pure Prolog.
(define pure-prolog
  (lambda (prog goal)
    ;; begin zero-ing the AMB tree.
    (amb+-reset)
    (let loop ((res goal)
               (sub '())
               (tag 1))
      (if (null? res)
          ;; if res is null, nothing else needs to be done. Select
          ;; the relevant part of the substitution (sub) for this goal
          ;; and return it.
          (select-sub sub goal)
          ;; if not,  then call resolve to perform one step of
          ;; resolution, and loop over with the new resolvent
          ;; and new substitution.
          (let ((resolved (resolve res sub tag goal prog)))
            (if resolved
                (loop (resolved->res resolved)
                      (resolved->sub resolved)
                      (+ tag 1))
                #f))))))


;;;
;;; WITH BUILT-INS
;;;

;; each built-in in internally a function of two arguments:
;; the first is a list of arguments to the built-in function
;; the second is the current substitution.
(define write-it
  (lambda (args sub)
    (cond ((not (null? args))
           (if (matching-symbol? (car args))
               (display (assoc (car args) sub))
               (display (car args)))
           (write-it (cdr args) sub))
          (else #t))))

(define built-ins #f)

;; a built-in procedure to save the list of built-in procedures
(define save-built-in-list
  (lambda (filename)
    (let ((out (open-output-file filename)))
      (write built-ins out)
      (close-output-port out))))

;; similarly, a procedure to load the built-in list.
(define load-built-in-list
  (lambda (filename)
    (let ((in (open-input-file filename)))
      (let ((x (read in)))
        (if (not (eof-object? x))
            (set! built-ins x)))
      (close-input-port in))))


;; this is the list of default built-ins (there are only three, WRITE, SAVE-BUILT-IN-LIST and LOAD-BUILT-IN-LIST)
(set! built-ins `((write . ,write-it)
                  (save  . ,save-built-in-list)
                  (load  . ,load-built-in-list)))

;; this will interpret a built-in.
;; proc-call is of the form (built-in-name arg1 arg2 ...)
(define interpret-built-in
  (lambda (proc-call sub)
    (let ((proc (cdr (assq (car proc-call) built-ins)))
          (args (cdr proc-call)))
      (proc args sub))))

;; res is of the form "(proc arg1 arg2 ...)"
(define built-in?
  (lambda (res)
    (assq (car res) built-ins)))

(define prolog+built-ins
  (lambda (prog goal)
    (amb-reset)
    (let loop ((res goal)
               (sub '())
               (tag 1))

      (cond ((null? res)
             (list (select-sub sub goal) (apply-sub sub res)))

            ;; if we have a built-in, then call interpret-built-in,
            ;; and loop over.
            ((built-in? (car res))
             (interpret-built-in (car res) sub)
             (loop (cdr res) sub tag))

            (else (let ((resolved (resolve res sub tag goal prog)))
                    (loop (resolved->res resolved)
                          (resolved->sub resolved)
                          (+ tag 1))))))))



;;;
;;; WITH SCHEME PROCEDURES
;;;


(define atom-start car)

(define prolog+scheme
  (lambda (prog goal)
    (amb+-reset)
    (let loop ((res goal)
               (sub '())
               (tag 1))
      (cond ((null? res)
             (select-sub sub goal))

            ;; if we have a list, it's a call to a Scheme procedure,
            ;; so call it, get the return value, require it to
            ;; be different feorm #f and loop over. If the returned
            ;; value is false, then return #f (so Prolog will fail).
            ((list? (atom-start (car res)))
             (let ((truth (eval (apply-sub sub
                                           (atom-start (car res))) 
                                (interaction-environment))))
               (require+ truth)
               (if truth
                   (loop (cdr res) sub tag)
                   #f)))

            (else (let ((resolved (resolve res sub tag goal prog)))
                    (if resolved
                        (loop (resolved->res resolved)
                              (resolved->sub resolved)
                              (+ tag 1))
                        #f)))))))




;;;
;;; WITH LOCAL VARIABLES AND "IS"
;;;

;; the rvalue of an IS is its second element (the cadr).
(define is->rvalue cadr)

;; do-is is the procedure that makes IS and local variables
;; work.
;;
;; res is of the form "(is ?var expression)"
;; do-is will try to unify ?var, which is
;; (atom-start (cdr res)), with expression,
;; which needs to be evaluated, using eval in
;; interaction-environment. We require the unification
;; to be successful, otherwise we fail (that is what
;; the "(require+ s)" does).
(define do-is
  (lambda (res sub)
    (let ((s (unify
              (atom-start (cdr res))
              (eval (apply-sub sub
                               (is->rvalue (cdr res)))
                    (interaction-environment)))))
      (require+ s)
      s)))

(define prolog+local
  (lambda (prog goal)
    (amb+-reset)
    (let loop ((res goal)
               (sub '())
               (tag 1))
      (cond ((null? res)
             (select-sub sub goal))

            ;; if we have a "IS", call 'do-is' on the first
            ;; element of res, get the substitution returned,
            ;; apply it to the rest of the goal and to the
            ;; current substitution, and loop over.
            ((eqv? (atom-start (car res)) 'is)
             (let ((s (do-is (car res) sub)))
               (loop (apply-sub s (cdr res))
                     (append s (apply-sub s sub)) tag)))

            ((list? (atom-start (car res)))
             (let ((truth (eval (apply-sub sub
                                           (atom-start (car res)))
                                (interaction-environment) )))
               (require+ truth)
               (if truth
                   (loop (cdr res) sub tag)
                   #f)))

            (else
             (let ((resolved (resolve res sub tag goal prog)))
               (if resolved
                   (loop (resolved->res resolved)
                         (resolved->sub resolved)
                         (+ tag 1))
                   #f)))))))


;;;
;;; WITH META-PREDICATES (assert, retract)
;;;

(define prolog+meta
  (lambda (prog goal)

    ;; simple appending procedure. We add the new facts to 
    ;; the global variable "prog".
    (define asserta
      (lambda (res)
        (let ((fact (cdar res)))
          (set! prog (cons fact prog)))))

    ;; simple retract procedure: just remove the fact from
    ;; "prog".
    (define retract
      (lambda (res)
        (let ((fact (cadar res)))
          (set! prog (remove (lambda (x) (equal? x fact))
                             prog)))))
    
    (amb+-reset)
    (let loop ((res goal)
               (sub '())
               (tag 1))
      (cond ((null? res)
             (select-sub sub goal))

            ;; asserta adds the fact to the database:
            ((eqv? (atom-start (car res)) 'asserta)
             (asserta res)
             (loop (cdr res) sub tag))

            ;; retract removes the fact:
            ((eqv? (atom-start (car res)) 'retract)
             (retract res)
             (loop (cdr res) sub tag))
            
            ((eqv? (atom-start (car res)) 'is)
             (let ((s (do-is (car res) sub)))
               (loop (apply-sub s (cdr res))
                     (append s (apply-sub s sub)) tag)))
            ((list? (atom-start (car res)))
             
             (let ((truth (eval (apply-sub sub
                                           (atom-start (car res)))
                                (interaction-environment))))
               (require+ truth)
               (if truth
                   (loop (cdr res) sub tag)
                   #f)))
            (else
             (let ((resolved (resolve res sub tag goal prog)))
               (if resolved
                   (loop (resolved->res resolved)
                         (resolved->sub resolved)
                         (+ tag 1))
                   #f)))))))





;;;
;;; WITH CUT
;;;

(define depth 0)
 
;; the symbol '! marks a cut.
(define cut?
  (lambda (x)
    (and (pair? x)
         (eqv? (car x) '!))))

(define prolog+cut
  (lambda (prog goal)
    
    (define asserta
      (lambda (res)
        (let ((fact (cdar res)))
          (set! prog (cons fact prog)))))
    
    (define retract
      (lambda (res)
        (let ((fact (cadar res)))
          (set! prog (remove (lambda (x) (equal? x fact))
                             prog)))))
 
    (amb+-reset)
    (amb+-add (lambda args #f))
    (let loop ((res (rename-vars goal #f))
               (sub '())
               (tag 1))
      
      (cond ((null? res)
             (select-sub sub goal))
           
            ;; check if it's a cut. If it is, set the AMB set of
            ;; continuations to res -- if we backtrack, we'll only
            ;; go this far back! 
            ((cut? (car res))
             (set! amb+-set (cadar res))
             (loop (cdr res) sub tag))
 
            ((eqv? (atom-start (car res)) 'asserta)
             (asserta res)
             (loop (cdr res) sub tag))
            
             ((eqv? (atom-start (car res)) 'retract)
             (retract res)
             (loop (cdr res) sub tag))
             
            ((eqv? (atom-start (car res)) 'is)
             (let ((s (do-is (car res) sub)))
               (loop (apply-sub s (cdr res))
                     (append s (apply-sub s sub)) tag)))
            
            ((list? (atom-start (car res)))
             (let ((r (eval
                       (apply-sub sub
                                  (atom-start
                                   (car res)))
                       (interaction-environment))))
               (require+ r)
               (if r
                   (loop (cdr res) sub tag)
                   #f)))
            (else
             (let ((resolved
                    (resolve res sub tag goal prog)))
               (if resolved
                   (loop (resolved->res resolved)
                         (resolved->sub resolved)
                         (+ tag 1))
                   #f)))))))

)
