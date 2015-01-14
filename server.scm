(declare (uses core)
         (uses event)
         (uses net))

(define ctx (make-context))
(define conn (bind-clients ctx))
(debug (deserialize-state (pull-input conn 5000)))
