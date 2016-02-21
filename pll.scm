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

;; pll.scm -- the loadable file for the Prolog interpreter

(cond-expand (chicken  (require-extension r7rs))
             (else))

(define-library (pll)
  (import (scheme base) (scheme eval) (scheme repl) (scheme cxr) (scheme write) (srfi 1))
  ;; include-library-declarations didn't work as I was expecting on Chicken...
  (include  "amb.scm"
            "unify.scm"
            "prolog-core.scm")
  (export ;; AMB:
   fail amb-reset amb amb-save amb-restore require amb-all
   amb+-set amb+-reset amb+-fail amb+ amb+-list require+ amb-list
   ;; unification:
   matching-symbol? apply-sub variable? bound? occurs? unify
   ;; Prolog:
   pure-prolog
   prolog+built-ins
   prolog+scheme
   prolog+local
   prolog+meta
   prolog+cut))
