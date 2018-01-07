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


;; unify.scm -- implements unification
;; 
;; SYNOPSIS:
;; 
;; (unify x y)
;; :: unifies x and y. 

;;; UNIFICATION WITH STACK
;;; ----------------------
;;;

(begin

;; a symbol is a matching symbol if it begins with a question
;; mark.
(define matching-symbol?
  (lambda (s)
    (and (symbol? s)
         (eqv? (string-ref (symbol->string s) 0)
              #\?))))

;; applies substitution sub in expression exp.
(define apply-sub
  (lambda (sub exp)
    (cond ((eqv? exp '()) '())
          ((pair? exp)
           (cons (apply-sub sub (car exp))
                 (apply-sub sub (cdr exp))))
          (else
           (let ((new-x (assoc exp sub)))
             (if new-x
                 (cdr new-x)
                 exp))))))


;; checks wether the argument is a Prolog "variable":
;; a variable is a symbol beginning with a question mark.
(define variable?
   (lambda (s)
    (and (symbol? s)
         (eqv? (string-ref (symbol->string s) 0)
              #\?))))

(define bound? assq)

(define (value v subst) (cdr (assq v subst)))

(define (bind var val sub) (cons (cons var val) sub))


;; checks wether var occurs within expression x,
;; given the substitution list "subst".
(define occurs?
  (lambda (var x subst)
    (cond ((eqv? var x) #t)
          ((bound? x subst)
           (occurs? var (value x subst) subst))
          ((pair? x) (or (occurs? var (car x) subst)
                         (occurs? var (cdr x) subst)))
          (else #f))))

;; unifies a variable ("var") with a value ("val"),
;; given the substitution list "subst".
(define uni-var
  (lambda (var val sub)
    (cond ((eqv? var val) sub)
          ((bound? var sub)
           (unify (value var sub) val sub))
          ((and (variable? val) (bound? val sub))
           (unify var (value val sub) sub))
          ((occurs? var val sub) #f)
          (else (bind var (apply-sub sub val)
                      (apply-sub (list (cons var val)) sub))))))

;; unify x with y, given the substitution list "s".
(define unify
  (lambda (x y . s)
    (let ((sub (if (null? s) '() (car s))))
      (cond ((equal? x y) sub)
            ((eqv? sub #f) #f)
            ((variable? x) (uni-var x y sub))
            ((variable? y) (uni-var y x sub))
            ((not (or (pair? x) (pair? y))) #f)
            ((and (null? x) (null? y))
             sub)
            ((or (null? x) (null? y))
             #f)
            (else (unify (cdr x) (cdr y)
                         (unify (car x) (car y) sub)))))))

)
