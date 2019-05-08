#lang scribble/lp2
@(require scribble/manual aoc-racket/helper)

@aoc-title[1]

@defmodule[aoc-racket/day01]

@link["http://adventofcode.com/day/01"]{The puzzle}. Our @link-rp["day01-input.txt"]{input} is a string of parentheses that controls an elevator. A left parenthesis @litchar{(} means go up one floor, and a right parenthesis @litchar{)} means go down.

@chunk[<day01>
       <day01-setup>
       <day01-q1>
       <day01-q1-alt>
       <day01-q2>
       <day01-q2-alt>
       <day01-test>]


@isection{Where does the elevator land?}

The building has an indefinite number of floors in both directions. So the ultimate destination is just the number of up movements minus the number of down movements. In other words, a left parenthesis = @racket[1] and a right parenthesis = @racket[-1], and we sum them.

@iracket[regexp-match*] will return a list of all occurrences of one string within another. The length of this list is the number of occurrences. Therefore, we can use it to count the ups and downs.

@chunk[<day01-setup>
       (require racket rackunit)
       (provide (all-defined-out))
       (define up-char #\()
       (define down-char #\))
       
       (define (make-matcher c)
         (λ (str) (length (regexp-match* (regexp (format "\\~a" c)) str))))
       (define get-ups (make-matcher up-char))
       (define get-downs (make-matcher down-char))
       (define (get-destination str) (- (get-ups str) (get-downs str)))]



@chunk[<day01-q1>
       (define (q1 str)
         (get-destination str))]

@isubsection{Alternate approach: numerical conversion}

Rather than counting matches with @racket[regexp-match*], we could also convert the string of parentheses directly into a list of numbers.

@chunk[<day01-q1-alt>
       (define (elevator-string->ints str)
         (for/list ([c (in-string str)])
                   (if (equal? c up-char)
                       1
                       -1)))
       
       (define (q1-alt str)
         (apply + (elevator-string->ints str)))]

@isection[#:tag "q2"]{At what point does the elevator enter the basement?}

The elevator is in the basement whenever it's at a negative-valued floor. So instead of looking at its ultimate destination, we need to follow the elevator along its travels, computing its intermediate destinations, and stop as soon as it reaches a negative floor.

We could characterize this as a problem of tracking @italic{cumulative values} or @italic{state}. Either way, @iracket[for/fold] is the weapon of choice. We'll determine the relative movement at each step, and collect these in a list. (The @racket[get-destination] function is used within the loop to convert each parenthesis into a relative movement, either @racket[1] or @racket[-1].) On each loop, @racket[for/fold] checks the cumulative value of these positions, and stops when they imply a basement value. The length of this list is our answer.

@margin-note{Nothing wrong with @racket[foldl] and @racket[foldr], but @racket[for/fold] is more flexible, and makes more readable code.}


@chunk[<day01-q2>
       (define (in-basement? movements)
         (negative? (apply + movements)))  
       
       (define (q2 str)
         (define relative-movements
           (for/fold ([movements-so-far empty])
                     ([c (in-string str)]
                      #:break (in-basement? movements-so-far))
             (cons (get-destination (~a c)) movements-so-far)))
         
         (length relative-movements))]

@isubsection{Alternate approaches: @tt{for/first} or @tt{for/or}}

When you need to stop a loop the first time a condition occurs, you can also consider @iracket[for/first] or @iracket[for/or]. The difference is that @racket[for/first] ends after the first evaluation of the body, but @racket[for/or] evaluates the body every time, and ends the first time the body is not @racket[#f].

The two are similar. The choice comes down to readability and efficiency — meaning, if each iteration of the loop is expensive, you'll probably want to cache intermediate values, which means you might as well use @racket[for/fold].

@chunk[<day01-q2-alt>       
       (define (q2-for/first str)
         (define basement-position
           (let ([ints (elevator-string->ints str)]) 
             (for/first ([idx (in-range (length ints))]
                         #:when (negative? (apply + (take ints idx))))
                        idx)))
         basement-position)
       
       (define (q2-for/or str)
         (define basement-position
           (let ([ints (elevator-string->ints str)]) 
             (for/or ([idx (in-range (length ints))])
                     (and (negative? (apply + (take ints idx))) idx))))
         basement-position)]


@section{Testing Day 1}

@chunk[<day01-test>
       (module+ test
         (define input-str (file->string "day01-input.txt"))
         (check-equal? (q1 input-str) 74)
         (check-equal? (q1-alt input-str) 74)
         (check-equal? (q2 input-str) 1795)
         (check-equal? (q2-for/first input-str) 1795)
         (check-equal? (q2-for/or input-str) 1795))]


