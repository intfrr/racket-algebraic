#lang scribble/manual

@title[#:tag "tut:ext"]{A Syntax Extension}

@require{./algebraic-includes.rkt}

This is the second tutorial in a series starting with @secref{tut:core}.

@defmodulelang[algebraic/model/ext]

In @secref{tut:core}, we built an s-expression interpreter as a small-step term
evaluator loosely based on the λ-calculus. To help encode complex terms as
runnable s-expressions, we used a manual term rewriting technique. This time,
we're going to implement that technique and one more as an extension to the
original surface syntax.

