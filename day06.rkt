#lang scribble/lp2
@(require scribble/manual aoc-racket/helper)

@aoc-title[6]

@defmodule[aoc-racket/day06]

@link["http://adventofcode.com/day/6"]{The puzzle}. Our @link-rp["day06-input.txt"]{input} is a list of instructions for turning on (or off) the bulbs in a @racket[(* 1000 1000)] grid of lights.

@chunk[<day06>
       <day06-setup>
       <day06-q1>
       <day06-q2>
       <day06-refactored>
       <day06-test>]

@isection{How many lights are lit after following the instructions?}

We need to a) create a data structure to hold our grid of lights, then b) step through the instructions on the list, and then c) count how many lights are lit at the end.

When you need random access to a fixed-size set of items, you should think @secref["vectors" #:doc '(lib "scribblings/guide/guide.scrbl")]. (We could do this problem with a @seclink["hash-tables" #:doc '(lib "scribblings/guide/guide.scrbl")]{hash table}, but it would be a lot slower.) The grid-ness of the problem might suggest a two-dimensional vector — e.g., a 1000-unit vector where each slot holds another 1000-unit vector. But this doesn't buy us any convenience. We'll just use a single @racket[(* 1000 1000)]-unit @iracket[vector], and translate our Cartesian coordinates into linear vector indexes by treating a coordinate like @tt{(246, 139)} as @racket[246139].

Each instruction consists of two pieces. First, an operation: either @italic{turn on}, @italic{turn off}, or @italic{toggle} (meaning, invert the current state of the bulb). Second, a definition of a rectangular segment of the grid that the operation will be applied to (e.g., @italic{333,60 through 748,159}). Therefore, a natural way to model each instruction is as a Racket function followed by four numerical arguments.

@chunk[<day06-q1>
       
       (define (str->instruction str)
         (match-define (list* _ action coordinates)
           (regexp-match #px"^(.*?)(\\d+),(\\d+) through (\\d+),(\\d+)$" str))
         
         (define (action->bulb-func action)
           (case action
             [("turn on") (thunk* 1)]
             [("turn off") (thunk* 0)]
             [else (λ (bulb) (if (= bulb 1) 0 1))]))
         
         (list* (action->bulb-func (string-trim action))
                (map string->number coordinates)))
       
       (define (q1 strs)
         (define lights (make-vector (* 1000 1000) 0))
         (for ([instruction (in-list (map str->instruction strs))])
              (set-lights lights instruction))
         (count-lights lights))
                               
       ]

We'll define our functions for setting and counting the lights separately, since we'll be able to resuse them for the second part.

@chunk[<day06-setup>
       (require racket rackunit)
       (provide (all-defined-out))
       
       (define (set-lights lights arglist)
         (match-define (list bulb-func x1 y1 x2 y2) arglist)
         (for* ([x (in-range x1 (add1 x2))][y (in-range y1 (add1 y2))])
               (define vector-loc (+ (* 1000 x) y))
               (define current-light (vector-ref lights vector-loc))
               (vector-set! lights vector-loc (bulb-func current-light))))
       
       (define (count-lights lights)
         (for/sum ([light (in-vector lights)]
                   #:when (positive? light))
                  light))]



@section{What is the total brightness of the lights if the rules are reinterpreted?}

The second part redefines the meaning of the three instructions, and introduces a notion of ``brightness'':

@itemlist[
 @item{@italic{Turn on} now means increase brightness by 1.}
 @item{@italic{Turn off} now means reduce brightness by 1, to a minimum of 0.}
 @item{@italic{Toggle} now means increase brightness by 2.}
 ]

This part is the same as the last, except we change the definitions of our bulb functions to match the new rules.


@chunk[<day06-q2>
       (define (str->instruction-2 str)
         (match-define (list* _ action coordinates)
           (regexp-match #px"^(.*?)(\\d+),(\\d+) through (\\d+),(\\d+)$" str))
         
         (define (action->bulb-func action)
           (case action
             [("turn on") (λ (bulb) (add1 bulb))]
             [("turn off") (λ (bulb) (max 0 (sub1 bulb)))]
             [else (λ (bulb) (+ bulb 2))]))
         
         (list* (action->bulb-func (string-trim action))
                (map string->number coordinates)))
       
       (define (q2 strs)
         (define lights (make-vector (* 1000 1000) 0))
         (for ([instruction (in-list (map str->instruction-2 strs))])
              (set-lights lights instruction))
         (count-lights lights))]

@section{Refactored solution}

Since the only part that changes between the solutions is the bulb functions, we could refactor the solutions to avoid repetition.

@chunk[<day06-refactored>
       (define (day06-solve strs bulb-func-converter)
         (define lights (make-vector (* 1000 1000) 0))
         (for ([instruction (in-list (map (make-str-converter bulb-func-converter) strs))])
              (set-lights lights instruction))
         (count-lights lights))
       
       (define (make-str-converter bulb-func-converter)
         (λ (str)
           (match-define (list* _ action coordinates)
             (regexp-match #px"^(.*?)(\\d+),(\\d+) through (\\d+),(\\d+)$" str))
           (list* (bulb-func-converter (string-trim action))
                  (map string->number coordinates))))
       
       (define q1-bulb-func-converter
         (λ (action) (case action
                      [("turn on") (thunk* 1)]
                      [("turn off") (thunk* 0)]
                      [else (λ (bulb) (if (= bulb 1) 0 1))])))
       
       (define q2-bulb-func-converter
         (λ (action) (case action
                      [("turn on") (λ (bulb) (add1 bulb))]
                      [("turn off") (λ (bulb) (max 0 (sub1 bulb)))]
                      [else (λ (bulb) (+ bulb 2))])))
       ]

@section{Testing Day 6}

@chunk[<day06-test>
       (module+ test
         (define input-strs (file->lines "day06-input.txt"))
         (check-equal? (q1 input-strs) 400410)
         (check-equal? (q2 input-strs) 15343601)
         (check-equal? (day06-solve input-strs q1-bulb-func-converter) 400410)
         (check-equal? (day06-solve input-strs q2-bulb-func-converter) 15343601))]


