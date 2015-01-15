(declare (uses core event net))

(define *ctx* (make-context))
(define *conn* (bind-clients *ctx*))
(define *id* (get-owner-id *conn*))

(make-prototype "test" radius: 10 speed: 1 update-chain: (list object-stop-at-dest-update object-move-update))
(make-prototype "test2" radius: 20 speed: 5 update-chain: (list object-move-update))

(main-game-loop
  (list (make-object "test" (cons 100 200) 0 moving: #f owner: *id*)
        (make-object "test2" (cons 200 200) (/ 3.1415926 3) moving: #t owner: *id*)
        (make-object "test" (cons 300 200) 0 moving: #f owner: *id*))
  #f ; no screen on server
  (server-event-handler *conn*)
  (server-draw-handler *conn*)
  (server-update-handler *conn*))
