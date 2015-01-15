(declare (unit core)
         (uses utils graphics object))

(use sdl-base
     posix)

(define (initialize-display)
  (sdl-init SDL_INIT_VIDEO)
  (sdl-wm-set-caption "turing" #f)
  (let ([screen (sdl-set-video-mode 0 0 16 0)])
   (if screen
     (begin
       (initialize-graphics (cons (sdl-surface-width screen) (sdl-surface-height screen)))
       screen)
     (log-err "Failed to initialize display"))))

(define (main-game-loop initial-state screen event-handler draw-handler update-handler)
  (let ([event (make-sdl-event)])
   (let loop ([state initial-state]
              [running #t]
              [camera (cons 0 0)])
     (if running
       (begin
         (draw-handler state camera screen)
         (call-with-values (lambda ()
                             (let event-poll-loop ([s state]
                                                   [r running]
                                                   [c camera])
                              (if (sdl-poll-event! event)
                                (call-with-values (lambda () (event-handler s r c event))
                                                  event-poll-loop)
                                (values s r c))))
                           (lambda (state running camera) (call-with-values (lambda () (update-handler state running camera))
                                                                            loop))))))))

(define (client-draw-handler conn) 
  (lambda (state camera screen)
    (sdl-fill-rect screen #f (make-sdl-color 255 255 255))
    (let loop ([l state])
     (if (not (null? l))
       (begin
         (draw-object (car l) camera screen)
         (loop (cdr l)))))
    (sdl-flip screen)))

(define (server-draw-handler conn)
  (lambda (state camera screen)
    (sleep 1)
    (send-state conn state)))

(define (client-update-handler conn)
  (lambda (state running camera)
    (values (receive-state conn)
            running
            camera)))

(define (server-update-handler conn)
  (lambda (state running camera)
    (values (let loop ([l state])
             (if (null? l)
               '()
               (cons (update-object (car l))
                     (loop (cdr l)))))
            running
            camera)))
