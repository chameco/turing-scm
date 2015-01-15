(declare (uses core event net))

(define *ctx* (make-context))
(define *conn* (connect-to-server *ctx* "127.0.0.1"))
(define *id* (get-owner-id *conn*))

(main-game-loop
  (list)
  (initialize-display)
  (client-event-handler *conn*)
  (client-draw-handler *conn*)
  (client-update-handler *conn*))
