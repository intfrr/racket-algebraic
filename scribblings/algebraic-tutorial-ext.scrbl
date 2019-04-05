#lang scribble/manual

@title[#:tag "tut:ext"]{A Syntax Extension}

@require{./algebraic-includes.rkt}
@require[texmath]

This is the second tutorial in a series starting with @secref{tut:core}.

@defmodulelang[algebraic/model/ext]

In @secref{tut:core}, we built an s-expression interpreter as a small-step term
evaluator based loosely on the λ-calculus. To help encode complex terms as
runnable s-expressions, we used a manual term rewriting technique. This time,
we're going to simplify the surface syntax dramatically by building that
technique and one more into replacement @id[parse] and @id[print]
@tech{functions}.

@; -----------------------------------------------------------------------------

@section[#:tag "tut:ext:syntax"]{The Extended Syntax}

@subsubsub*section{Multi-clause Abstractions}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @tabular[
        @list[
          @list[
            @abs[
              @list{@${t} ⩴ ⋯ | φ}
              [@${p} @${t}]
              [ "⋮"   "⋮"  ]
              [@${p} @${t}]
            ]
            @abs[
              @list{@~ | μ}
              [@${p} @${t}]
              [ "⋮"   "⋮"  ]
              [@${p} @${t}]
            ]
          ]
        ]
      ]
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @tabular[
        @list[
          @list[
            @abs[
              "φ"
              [@${p_1} @${t_1}]
              [@${p_2} @${t_2}]
              [  "⋮"      "⋮"  ]
              [@${p_n} @${t_n}]
            ]
            @~ " ↝ " @~
            @abs[
              @list{φ@${p_1}.@${t_1};φ}
              [@${p_2} @${t_2}]
              [  "⋮"      "⋮"  ]
              [@${p_n} @${t_n}]
            ]
          ]
        ]
      ]
      @list{@${n} ≥ 2}
      @tabular[
        @list[
          @list[
            @abs[
              "μ"
              [@${p_1} @${t_1}]
              [@${p_2} @${t_2}]
              [  "⋮"      "⋮"  ]
              [@${p_n} @${t_n}]
            ]
            @~ " ↝ " @~
            @abs[
              @list{μ@${p_1}.@${t_1};μ}
              [@${p_2} @${t_2}]
              [  "⋮"      "⋮"  ]
              [@${p_n} @${t_n}]
            ]
          ]
        ]
      ]
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @tabular[
        @list[
          @list[
            @abs["φ" [@${p_1} @${t_1}]]
            @~ " ↝ " @~
            @list{φ@${p_1}.@${t_1}}
          ]
        ]
      ]
      @tabular[
        @list[
          @list[
            @abs["μ" [@${p_1} @${t_1}]]
            @~ " ↝ " @~
            @list{μ@${p_1}.@${t_1}}
          ]
        ]
      ]
    ]
  ]
]

@subsubsub*section{Application Currying}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @list{@${t} ⩴ ⋯ | @${t}⋯@${t}}
      @list{@${p} ⩴ ⋯ | @${p}⋯@${p}}
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '((center))
  @list[
    @list[
      @list{@${t_1} @${t_2} ⋯ @${t_n} @~ ↝ @~ @${t_1} (@${t_2} ⋯ @${t_n})}
      @list{@${n} ≥ 2}
      @list{@${p_1} @${p_2} ⋯ @${p_n} @~ ↝ @~ @${p_1} (@${p_2} ⋯ @${p_n})}
    ]
  ]
]
@tabular[
  #:style full-width
  #:column-properties '((center))
  @list[
    @list[
      @list{@${t_1};@${t_2};⋯;@${t_n} @~ ↝ @~ @${t_1};(@${t_2};⋯;@${t_n})}
      @list{@${p_1};@${p_2};⋯;@${p_n} @~ ↝ @~ @${p_1};(@${p_2};⋯;@${p_n})}
    ]
  ]
]

@subsubsub*section{Local Bindings}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @list{fix = φ@${f}.(φ@${x}.@${f} φ@${y}.(@${x} @${x}) @${y}) (φ@${x}.@${f} φ@${y}.(@${x} @${x}) @${y})}
    ]
    @list[
      @abs[
        "let ≈ μ"
        [@list{(@${p} @${t})} @${body} @list{(φ@${p}.@${body}) @${t}}]
        [@list{(@${p} @${t};@${cs})} @${body} @list{let (@${p} @${t}) let @${cs} @${body}}]
      ]
    ]
    @list[
      @abs[
        "letrec ≈ μ"
        [@list{(@${p} @${t})} @${body} @list{let (@${p} @${t}) let @${cs} @${body}}]
      ]
    ]
  ]
]

@; -----------------------------------------------------------------------------

@section[#:tag "tut:ext:examples"]{Examples}

@subsubsub*section{Numbers}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @abs[
        @list{add = φ}
        [@${a}        @Zero         @${a}]
        [@${a} @list{(@Succ @${b})} @${a}]
      ]
      @abs[
        @list{mul = φ}
        [@${a}        @Zero         @Zero]
        [@${a} @list{(@Succ @${b})} @list{add @${a} mul @${a} @${b}}]
      ]
    ]
  ]
]

@subsubsub*section{Booleans}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @abs[
        @list{not = φ}
        [@False @True ]
        ["_"    @False]
      ]
      @tabular[
        @list[
          @list[
            @abs[
              @list{and = μ(@${a} @${b}).φ}
              [@False @False]
              ["_"    @${b} ]
            ] @${ a}
          ]
        ]
      ]
    ]
    @list[
      @tabular[
        @list[
          @list[
            @abs[
              @list{or = μ(@${a} @${b}).φ}
              [@False @${b}]
              [@${x}  @${x}]
            ] @${ a}
          ]
        ]
      ]
      @tabular[
        @list[
          @list[
            @abs[
              @list{xor = μ(@${a} @${b}).φ}
              [@False @${b}]
              [@${x}  @list{and (not @${b}) @${x}}]
            ] @${ a}
          ]
        ]
      ]
    ]
  ]
]
 
@subsubsub*section{Lists}

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @abs[
        @list{list = μ}
        [@${x} "◊" @list{@Cons (@${x};@Nil)}]
        [@${x} @${xs} @list{@Cons (@${x};list @${xs})}]
      ]
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @tabular[
        @list[
          @list[
            @abs[
              @list{reverse = φ@${xs}.letrec (@${rev} φ}
              [           @Nil             @${a} @${a}]
              [@list{@Cons (@${y};@${ys})} @${a} @list{@${rev} @${ys} @Cons (@${y};@${a})}]
            ] @${) a}
          ]
        ]
      ]
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @abs[
        @list{append = φ}
        [@Nil         @${ys}         @${ys}]
        [@Cons @list{(@${x};@${xs})} @list{@Cons (@${x};append @${xs} @${ys})}]
      ]
    ]
  ]
]

@tabular[
  #:style full-width
  #:column-properties '(center)
  @list[
    @list[
      @abs[
        @list{map = φ}
        [ "_"                 @Nil                @Nil]
        [@${f} @list{@Cons @list{(@${x};@${xs})}} @list{@Cons (@${f} @${x};map @${f} @${xs})}]
      ]
    ]
  ]
]
