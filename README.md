# PLL: Programming in Logic in Lisp

PLL is a set of implementations of Prolog in Scheme. It is not
supposed to be efficient, but rather as a simple way to teach the
fundamentals of Logic Programming and the internal working of a
Prolog interpreter (conceptually only -- a real implementation would
be radically different). This interpreter is based on a simple
implementation of the AMB operator.

PLL is very small (less than 500 lines of code, including different
versions of the interpreter).

Each variant is built on top of the other.

- Pure prolog: no variables, no assertions, only plain Prolog and
  SLD-resolution.

- Prolog w/built-ins: with an extensible set of built-in predicates.
  Only the built-ins within a list are allowed.

- Prolog w/Scheme functions: call any Scheme function from Prolog.

- Prolog w/local vars: this version has support for "IS" and local
  Prolog variables.

- Prolog w/meta-predicates: this version has support for "assert"
  and "retract".

- Prolog w/cut: this version supports cuts.

One last implementation is missing, that would allow for writing
and reading the database (so it would be possible to store and
retrieve programs). This is very simple to implement and planned
for the near future.

This interpreter is implemented in three files:

- `prolog-core.scm`: this is the main program, where all the above variants
  of Prolog are implemented. Each variant differs from the previous
  only slightly, and the difference is made clear in code comments.

- `amb.scm`: handles non-determinism. This is a simple and usual
  implementation of the AMB operator.

- `unify.scm`: contains code for unification.

There are also two files used to load the interpreter:

- `pll.scm`: contains an R7RS library declaration (for Chibi users:
  `pll.sld` is a symlink to `pll.scm`, and works as expected)

- `pll-standalone.scm`: contains code to load the interpreter,
   without creating any libraries or modules. Will override
   identifiers!

## Supported Scheme implementations


I have made an effort to get the interpreter working in as many Scheme
implementations as I could. Below is a list of supported and not
supported Schemes. "Supported" means I ran the example code pieces
(in prolog-examples.scm) and they worked as sxpected. I did no
further tests.

There are two ways to use PLL:

```
(load "pll-standalone.scm")    ;; this works on all supported schemes.

(import (pll))                 ;; only on the systems marked as having 
                               ;; support for R7RS modules
```

```
Scheme      version	R7RS module	Note
-----------------------------------------------
Chicken     4.*		Y
Gauche      0.9.4	Y
Guile       2.*		-
Chibi       0.7.2	Y
Husk        3.19.1	-
SISC        1.16.6	-
Saggitarius 0.7.1	Y
Gambit      4.7		-		Needs -:s flag for syntax rules, and SRFI-1
MIT Scheme  9.1.1	-
STklos      1.10	-
Scheme48       	 	-		Needs ,open srfi-1
```

Currently not supported:

```
Bigloo     (prolog+cut eats up 100% CPU; needs investigation)
SigScheme  (syntax-rules is disabled in sigscheme for now)
TinyScheme (syntax-rules not implemented)
Scheme9    (very strange behavior -- needs investigation)
Kawa       (AMB doesn't work because of some different call/cc behavior)
Foment     (the Hanoi towers example eats up 100% CPU and never finishes)
SCM        (support for neither cond-expand nor syntax-rules)
SIOD       (syntax-rules not implemented)
```

## Documentation

A very short manual is included (manual.md, manual.txt, manual.pdf).

