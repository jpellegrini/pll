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

;; amb.scm -- implements the AMB operator
;; 
;; SYNOPSIS:

;;; amb
;;;
;; (amb-reset)
;; :: resets the amb tree: this will make amb forget everything.
;;
;; (amb x1 x2 ...)
;; :: add "x1 x2 ..." to the set of answers
;;
;; (amb)
;; :: selects one of the answers
;;
;; (require p)
;; :: selects one of the answers x such that (p x) is #true
;;
;; (amb-list lst)
;; :: same as (amb x1 x2 ...), where lst is (list x1 x2 ...)
;;
;; (amb-all v)
;; :: shows all values that may still be returned by amb in the future
;;
;; if amb has no more solutions to show, it will signal an error


;;; amb+
;;;
;; (amb+-reset)
;; :: resets the amb tree: this will make amb+ forget everything.
;;
;; (amb+ x1 x2 ...)
;; :: add "x1 x2 ..." to the set of answers
;;
;; (amb+)
;; :: selects one of the answers
;;
;; (require+ p)
;; :: selects one of the answers x such that (p x) is #true
;;
;; (amb+-delete-one)
;; :: deletes one element from the amb+ set.
;;
;; (amb+-add k)
;; :: adds k to the amb set
;;
;; (amb+-list lst)
;; :: same as (amb+ x1 x2 ...), where lst is (list x1 x2 ...)
;;
;; (amb+-fail)
;; :: synonym to (amb+)
;;
;; if amb+ has no more solutions to show, it will return #f



(begin

;; called when (amb) is called and there is no more answers available.
(define fail
  (lambda ()
    (error "Amb tree exhausted"))) 

(define amb-saved-fail fail)

;; resets the amb tree: this will make amb forget everything.
(define amb-reset
  (lambda ()
    (set! fail amb-saved-fail)))



(define-syntax amb 
  (syntax-rules () 
    ((amb) (fail))
    ((amb expression) expression)
    ((amb expression ...)
     (let ((saved-fail fail))
       (call-with-current-continuation
        (lambda (k-success)
          (call-with-current-continuation
           (lambda (k-failure)
             (set! fail (lambda ()
                          (set! fail saved-fail)
                          (k-failure 'boo)))
             (k-success expression)))
            ...
            (saved-fail)))))))


(define amb-save
  (lambda ()
    (let ((amb-saved-fail-bak amb-saved-fail)
          (amb-fail-bak fail))
      (amb-reset)
      (list amb-saved-fail-bak amb-fail-bak))))

(define amb-restore
  (lambda (lst)
     (set! fail (car lst))
     (set! amb-saved-fail (cadr lst))))

;; gets the first value from amb that satisfies p.
(define (require p)
  (if (not p) (amb)))

;; shows all values available.
(define-syntax amb-all
  (syntax-rules ()
    ((_ e)
     (let ((saved-fail fail)
           (results '()))
       (if (call-with-current-continuation
            (lambda (k)
              (set! fail (lambda () (k #f)))
              (let ((v e))
                (set! results (cons v results))
                (k #t))))
           (fail))
       (set! fail saved-fail)
       (reverse results)))))

(define now
  (lambda ()
    (call-with-current-continuation 
     (lambda (k) (k k)))))

(define amb+-set '())

(define (amb+-reset)
  (set! amb+-set '()))

(define (amb+-delete-one)
  (set! amb+-set (cdr amb+-set)))

(define (amb+-add k)
  (set! amb+-set (cons k amb+-set)))

(define (amb+-fail)
  (if (null? amb+-set)
      #f;(error "amb+: no more choices!")
      (let ((back (car amb+-set)))
        (amb+-delete-one)
        (back back))))

(define (amb+ . args)
  (let ((choices args))
    (let ((cc (now)))
      (cond ((null? choices) (amb+-fail))
            ((pair? choices)
             (let ((choice (car choices)))
               (set! choices (cdr choices))
               (amb+-add cc)
               choice))
            (else (error "amb choices must be a list"))))))

(define (amb+-list lst) (apply amb+ lst))

(define (require+ p)
  (if (not p) (amb+)))

(define amb-list
  (lambda (lst)
    (let loop ((lst lst))
      (if (null? lst)
          (amb)
          (amb (car lst) (loop (cdr lst)))))))

) ;; begin
