PLL: Programming in Logic in Lisp
=================================

PLL is a set of implementations of Prolog in Scheme. It is not supposed
to be efficient, but rather as a simple way to teach the fundamentals of
Logic Programming and the internal working of a Prolog interpreter
(conceptually only -- a real implementation would be radically
different). This interpreter is based on a simple implementation of the
AMB operator.

Each variant is built on top of the other.

-   Pure prolog: no variables, no assertions, only plain Prolog
    and SLD-resolution.

-   Prolog w/built-ins: with an extensible set of built-in predicates.
    Only the built-ins within a list are allowed.

-   Prolog w/Scheme functions: call any Scheme function from Prolog.

-   Prolog w/local vars: this version has support for "IS" and local
    Prolog variables.

-   Prolog w/meta-predicates: this version has support for "assert"
    and "retract".

-   Prolog w/cut: this version supports cuts.

One last implementation is missing, that would allow for writing and
reading the database (so it would be possible to store and retrieve
programs). This is very simple to implement and planned for the near
future.

This interpreter is implemented in three files:

-   `prolog-core.scm`: this is the main program, where all the above
    variants of Prolog are implemented. Each variant differs from the
    previous only slightly, and the difference is made clear in
    code comments.

-   `amb.scm`: handles non-determinism. This is a simple and usual
    implementation of the AMB operator.

-   `unify.scm`: contains code for unification.

There are also two files used to load the interpreter:

-   `pll.scm`: contains an R7RS library declaration (for Chibi users:
    `pll.sld` is a symlink to `pll.scm`, and works as expected)

-   `pll-standalone.scm`: contains code to load the interpreter, without
    creating any libraries or modules. Will override identifiers!


