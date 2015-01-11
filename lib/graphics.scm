(declare (unit graphics)
         (uses utils))

(use sdl-base)

(define *screen-width* #f)
(define *screen-height* #f)

(define (initialize-graphics screen-dims)
  (set! *screen-width* (car screen-dims))
  (set! *screen-height* (cdr screen-dims)))

(define (adjust-position camera-pos pos)
  (let ([cx (car camera-pos)]
        [cy (cdr camera-pos)]
        [x (car pos)]
        [y (cdr pos)])
    (cons
      (+ x (- (/ *screen-width* 2) cx))
      (+ y (- (/ *screen-height* 2) cy)))))

(define (invert-adjust-position camera-pos pos)
  (let ([cx (car camera-pos)]
        [cy (cdr camera-pos)]
        [x (car pos)]
        [y (cdr pos)])
    (cons
      (- x (- (/ *screen-width* 2) cx))
      (- y (- (/ *screen-height* 2) cy)))))

(define (draw-rectangle screen camera-pos pos dims color)
  (let* ([apos (adjust-position camera-pos pos)]
         [w (car dims)]
         [h (cdr dims)]
         [rect (make-sdl-rect (- (car apos) (/ w 2)) (- (cdr apos) (/ h 2)) w h)])
    (sdl-fill-rect screen rect color)))
