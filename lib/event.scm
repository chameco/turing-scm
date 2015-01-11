(declare (unit event)
         (uses object)
         (uses utils graphics))

(use sdl-base)

(define (base-event-handler state running camera event)
  (let ([event-type (sdl-event-type event)])
   (cond
     [(= event-type SDL_QUIT) (values state #f camera)]
     [(= event-type SDL_MOUSEBUTTONDOWN)
      (let* ([pos (cons (sdl-event-x event) (sdl-event-y event))]
             [apos (invert-adjust-position camera pos)])
        (if (= (sdl-event-button event) SDL_BUTTON_LEFT)
          (values
            (select-object state apos (lambda (o) (set-prop o 'selected (not (get-prop o 'selected)))))
            running
            camera)
          (values
            (let loop ([l state])
              (if (null? l)
                '()
                (if (get-prop (car l) 'selected)
                  (cons (move-object-to (car l) apos) (loop (cdr l)))
                  (cons (car l) (loop (cdr l))))))
            running
            camera)))]
     [else (values state running camera)])))
