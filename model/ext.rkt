#lang algebraic/racket/base

(require (except-in algebraic/model/core
                    #%app #%datum #%module-begin #%top-interaction
                    parse show algebraic))

(provide #%app #%datum
         (rename-out [ext-module-begin #%module-begin]
                     [ext-top-interaction #%top-interaction])
         (all-defined-out)
         (for-syntax (all-defined-out)))

(define-syntax ext-module-begin
  (μ* (form ...)
    (#%plain-module-begin ((current-print) (algebraic form)) ...)))

(define-syntax ext-top-interaction
  (μ* form
    (#%top-interaction . (algebraic form))))

;;; ----------------------------------------------------------------------------
;;; Syntax

(define (parse t)
  (define term
    (function
      ['fix (term '(φ f (φ x f φ y (x x) y) (φ x f φ y (x x) y)))]
      [('fun [p . ts]) (term `(φ ,p ,@ts))]
      [('mac [p . ts]) (term `(μ ,p ,@ts))]
      [('fun c . cs) (TSeq (term `(fun ,c)) (term `(fun ,@cs)))]
      [('mac c . cs) (TSeq (term `(mac ,c)) (term `(mac ,@cs)))]
      [('let () . body) (term body)]
      [('let ([p . ts] . cs) . body) (term `((φ ,p let ,cs ,@body) ,@ts))]
      [('letrec () . body) (term body)]
      [('letrec ([p . ts] . cs) . body) (term `((φ ,p letrec ,cs ,@body) fix φ ,p ,@ts))]
      [($ t1 t2 . ts) (TSeq (term t1) (term `($ ,t2 ,@ts)))]
      [($ t1) (term t1)]
      [('φ p1 . t2) (values-> TFun (α-rename (patt p1) (term t2)))]
      [('μ p1 . t2) (values-> TMac (α-rename (patt p1) (term t2)))]
      [(t1 t2 . ts) (TApp (term t1) (term (cons t2 ts)))]
      [(t1) (term t1)]
      [x #:if (and (symbol? x) (char-lower-case? (first-char x))) (TVar x)]
      [x #:if (and (symbol? x) (char-upper-case? (first-char x))) (TCon x)]
      [◊ TUni]))
  (define patt
    (function
      [($ p1) (patt p1)]
      [($ p1 p2 . ps) (PSeq (patt p1) (patt `($ ,p2 ,@ps)))]
      [(  p1) (patt p1)]
      [(  p1 p2 . ps) (PApp (patt p1) (patt `(  ,p2 ,@ps)))]
      ['_ PWil]
      [◊ PUni]
      [x #:if (and (symbol? x) (char-lower-case? (first-char x))) (PVar x)]
      [x #:if (and (symbol? x) (char-upper-case? (first-char x))) (PCon x)]))
  (term t))

(define (show a)
  (define term
    (function
      [(TSeq (TFun _ _) _) #:as t `(fun ,@(show-fun t))]
      [(TSeq (TMac _ _) _) #:as t `(mac ,@(show-mac t))]
      [(TSeq _ _) #:as t `($ ,@(seq->list t))]
      [(TApp _ _) #:as t (app->list t)]
      [(TFun p1 t2) `(φ ,(patt p1) ,@(app->list t2))]
      [(TMac p1 t2) `(μ ,(patt p1) ,@(app->list t2))]
      [(TVar x1) (string->symbol (symbol->string x1))]
      [(TCon δ1) δ1]
      [TUni '◊]))
  (define patt
    (function
      [(PApp _ _) #:as p (app->list p)]
      [(PSeq _ _) #:as p (seq->list p)]
      [(PVar x1) (string->symbol (symbol->string x1))]
      [(PCon δ1) δ1]
      [PWil '_]
      [PUni '◊]))
  (define show-mac
    (function
      [(TMac p1 t2) `([,(patt p1) ,@(app->list t2)])]
      [(TSeq t1 t2) (append (show-mac t1) (show-mac t2))]))
  (define show-fun
    (function
      [(TFun p1 t2) `([,(patt p1) ,@(app->list t2)])]
      [(TSeq t1 t2) (append (show-fun t1) (show-fun t2))]))
  (term a))

;;; ----------------------------------------------------------------------------
;;; Semantics

(define-syntax algebraic
  (μ t (show (interpret (parse 't)))))

;;; ----------------------------------------------------------------------------
;;; Pragmatics

(define app->list
  (function
    [(TApp t1 t2) (cons (show t1) (app->list t2))]
    [(PApp p1 p2) (cons (show p1) (app->list p2))]
    [a (list (show a))]))

(define seq->list
  (function
    [(TSeq t1 t2) (cons (show t1) (seq->list t2))]
    [(PSeq p1 p2) (cons (show p1) (seq->list p2))]
    [a (list (show a))]))

;;; ============================================================================

(module+ test
  (require rackunit
           syntax/parse/define)

  (define-syntax-parser check-algebraic
    #:datum-literals (=> ~>)
    [(_ (~seq term (~and arrow (~or => ~>)) want) ...)
     #:with (cmd ...)
     (for/list ([t (syntax-e #'(term ...))]
                [a (syntax-e #'(arrow ...))])
       (cond [(eq? (syntax->datum a) '=>) #`(algebraic #,t)]
             [(eq? (syntax->datum a) '~>) #`(show (step (parse '#,t)))]
             [else (error 'unhandled)]))
     #'(begin (check-algebraic* 'term 'arrow (λ () cmd) 'want) ...)])

  (define-check (check-algebraic* in arr thunk want)
    (with-check-info (['argument in]
                      ['expected want])
      (let ([got (with-handlers
                   ([exn:fail? (λ (ex)
                                 (with-check-info (['exception ex])
                                   (fail-check "got stuck")))])
                   (thunk))])
        (with-check-info (['actual got])
          (or (equal? got want)
              (fail-check "bad result"))))))

  (test-case "value"
    (check-algebraic
     ◊ => ◊                             ;unit
     A => A                             ;constructor
     (φ x x) => (φ x x)                 ;function
     (μ x x) => (μ x x)))               ;macro

  (test-case "variable"
    (check-algebraic
     ((φ x x) A) => A
     ((μ x x) A) => A
     ((μ x x) ((φ y y) A)) ~> ((φ y y) A)
     ((μ x x) ((φ y y) A)) => A))

  (test-case "application"
    (check-algebraic
     (((φ x x) (φ y y)) A) ~> ((φ y y) A)
     (((φ x x) (φ y y)) A) => A
     ((φ x x) ((φ y y) A)) ~> ((φ x x) A)
     ((φ x x) ((φ y y) A)) => A))

  (test-case "constructor"
    (check-algebraic
     (A ◊)         => (A ◊)
     (A (φ x x) B) => (A B)))

  (test-case "sequence"
    (check-algebraic
     ($ ((φ x x) A) B) ~> ($ A B)
     ($ A ((φ x x) B)) ~> ($ A B)
     (A ($ B C))           => (A ($ B C))
     (A ($ ((φ x x) B) C)) => (A ($ B C))
     (A ($ B ((φ x x) C))) => (A ($ B C))
     (A ($ ((φ x x) B) ((φ y y) C))) ~> (A ($ B ((φ y y) C)))))

  (test-case "function"
    (check-algebraic
     ((fun [A Z] [B Y]) A) => Z
     ((fun [A Z] [B Y]) B) => Y
     ((fun [(A a) Z a] [(B b) Y b]) A ◊) => (Z ◊)
     ((fun [(A a) Z a] [(B b) Y b]) B ◊) => (Y ◊)))

  (test-case "macro"
    (check-algebraic
     ((mac [A Z] [B Y]) A) => Z
     ((mac [A Z] [B Y]) B) => Y
     ((mac [(A a) Z a] [(B b) Y b]) A ◊) => (Z ◊)
     ((mac [(A a) Z a] [(B b) Y b]) B ◊) => (Y ◊)
     ((mac [(A a) Z a] [(B b) Y b]) A (φ x x) ◊) ~> (Z (φ x x) ◊)))

  (test-case "1 + 2 = 3"
    (check-algebraic
     (letrec ([add mac [(a Zero) a] [(a Succ b) Succ add a b]])
       add (Succ Zero) Succ Succ Zero)
     => (Succ Succ Succ Zero)))

  (test-case "2 * 3 = 6"
    (check-algebraic
     (letrec ([add fun [(a Zero)    a] [(a Succ b)  Succ add a b]]
              [mul fun [(a Zero) Zero] [(a Succ b) add a mul a b]])
       mul (Succ Succ Zero) (Succ Succ Succ Zero))
     =>
     (Succ Succ Succ Succ Succ Succ Zero)))

  (test-case "booleans"
    (check-algebraic
     (letrec ([not fun [False True] [_ False]]
              [and μ (a b) (fun [False False] [_             b]) a]
              [or  μ (a b) (fun [False     b] [x             x]) a]
              [xor μ (a b) (fun [False     b] [x and (not b) x]) a])
       or (not True) and (xor True True) True)
     => False))

  (test-case "list 1 2 3 ◊"
    (check-algebraic
     (letrec ([list mac [(x ◊) Cons $ x Nil] [(x xs) Cons $ x (list xs)]])
       list (Succ Zero) (Succ Succ Zero) (Succ Succ Succ Zero) ◊)
     =>
     (Cons ($ (Succ Zero)
              (Cons ($ (Succ Succ Zero)
                       (Cons ($ (Succ Succ Succ Zero)
                                Nil))))))))

  (test-case "reverse list 1 2 3 ◊"
    (check-algebraic
     (letrec ([list mac [(x ◊) Cons $ x Nil] [(x xs) Cons $ x (list xs)]]
              [rev fun [(Nil a) a] [((Cons ($ y ys)) a) rev ys Cons $ y a]]
              [reverse φ xs rev xs Nil])
       reverse list (Succ Zero) (Succ Succ Zero) (Succ Succ Succ Zero) ◊)
     =>
     (Cons ($ (Succ Succ Succ Zero)
              (Cons ($ (Succ Succ Zero)
                       (Cons ($ (Succ Zero) Nil))))))))

  (test-case "append (list 1 2 ◊) list 3 4 ◊"
    (check-algebraic
     (letrec ([list mac [(x ◊) Cons $ x Nil] [(x xs) Cons $ x (list xs)]]
              [append fun [(Nil ys) ys] [((Cons $ x xs) ys) Cons $ x (append xs ys)]])
       (append (list (Succ Zero) (Succ Succ Zero) ◊)
               list (Succ Succ Succ Zero) (Succ Succ Succ Succ Zero) ◊))
     =>
     (Cons ($ (Succ Zero)
              (Cons ($ (Succ Succ Zero)
                       (Cons ($ (Succ Succ Succ Zero)
                                (Cons ($ (Succ Succ Succ Succ Zero)
                                         Nil))))))))))

  (test-case "map Succ list 3 2 1 ◊"
    (check-algebraic
     (letrec ([list mac [(x ◊) Cons $ x Nil] [(x xs) Cons $ x (list xs)]]
              [map fun [(_ Nil) Nil] [(f Cons $ x xs) Cons $ (f x) (map f xs)]])
       map Succ list (Succ Succ Succ Zero) (Succ Succ Zero) (Succ Zero) ◊)
     =>
     (Cons ($ (Succ Succ Succ Succ Zero)
              (Cons ($ (Succ Succ Succ Zero)
                       (Cons ($ (Succ Succ Zero) Nil)))))))))
