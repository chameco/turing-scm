(declare (unit net)
         (uses utils))

(foreign-code "
              #include <zmq.h>
              void *zeromq_context = zmq_ctx_new();
              ")

(define connect
  (foreign-lambda* void ((c-string ip))
    "
    void *zeromq_socket = zmq_socket(zeromq_context, ZMQ_REQ);
    "))

(define (get-owner-id) 'myself)

(define (network-event-handler state running camera event) (values state running camera))

(define (network-update-handler state running camera) (values state running camera))
