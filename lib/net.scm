(declare (unit net)
         (uses utils))

(use (srfi 4)
     s11n
     ports
     format)

(foreign-declare "#include <zmq.h>
                  #include <stdio.h>
                  #include <stdlib.h>
                  #include <stddef.h>
                  #include <errno.h>
                  #include <assert.h>")

(define-foreign-variable _ZMQ_PULL int "ZMQ_PULL")
(define ZMQ_PULL _ZMQ_PULL)
(define-foreign-variable _ZMQ_PUSH int "ZMQ_PUSH")
(define ZMQ_PUSH _ZMQ_PUSH)
(define-foreign-variable _ZMQ_PUB int "ZMQ_PUB")
(define ZMQ_PUB _ZMQ_PUB)
(define-foreign-variable _ZMQ_SUB int "ZMQ_SUB")
(define ZMQ_SUB _ZMQ_SUB)

(define make-context
  (foreign-lambda* long ()
    "
    void *context = zmq_ctx_new();
    if (!context) {
        printf(\"E: context creation failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    C_return((long) context);
    "))

(define make-socket
  (foreign-lambda* long ((long context) (int type))
    "
    void *socket = zmq_socket((void *) context, type);
    if (!socket) {
        printf(\"E: socket creation failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    C_return((long) socket);
    "))

(define set-socket-topic
  (foreign-lambda* void ((long socket) (c-string topic))
    "
    int rc = zmq_setsockopt((void *) socket, ZMQ_SUBSCRIBE, topic, strlen(topic));
    if (rc == -1) {
        printf(\"E: connect failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    "))

(define set-socket-topic-all
  (foreign-lambda* void ((long socket))
    "
    int rc = zmq_setsockopt((void *) socket, ZMQ_SUBSCRIBE, 0, 0);
    if (rc == -1) {
        printf(\"E: connect failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    "))

(define socket-connect
  (foreign-lambda* void ((long socket) (c-string ip))
    "
    int rc = zmq_connect((void *) socket, ip);
    if (rc == -1) {
        printf(\"E: connect failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    "))

(define socket-bind
  (foreign-lambda* void ((long socket) (c-string ip))
    "
    int rc = zmq_bind((void *) socket, ip);
    if (rc == -1) {
        printf(\"E: bind failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    "))

(define (string->u8vector s) (list->u8vector (map char->integer (string->list s))))
(define (u8vector->string u) (list->string (map integer->char (u8vector->list u))))

(define socket-send
  (foreign-lambda* void ((long socket) (u8vector message) (int len))
    "
    int rc = zmq_send((void *) socket, message, len, 0);
    if (rc == -1) {
        printf(\"E: send failed: %s\\n\", zmq_strerror(errno));
        exit(1);
    }
    "))

(define (socket-receive socket size)
  (define socket-receive-impl
    (foreign-lambda* void ((long socket) (u8vector buffer) (int len))
      "
      int rc = zmq_recv((void *) socket, buffer, len, 0);
      if (rc == -1) {
          printf(\"E: receive failed: %s\\n\", zmq_strerror(errno));
          exit(1);
      }
      "))
  (let ([buffer (make-u8vector size 0)])
   (socket-receive-impl socket buffer size)
   buffer))

(define (connect-to-server context ip)
  (let ([outgoing (make-socket context ZMQ_PUSH)]
        [incoming (make-socket context ZMQ_SUB)])
    (socket-connect outgoing (string-append "tcp://" ip ":5558"))
    (set-socket-topic-all incoming)
    (socket-connect incoming (string-append "tcp://" ip ":5559"))
    (cons outgoing incoming)))

(define (bind-clients context)
  (let ([outgoing (make-socket context ZMQ_PUB)]
        [incoming (make-socket context ZMQ_PULL)])
    (socket-bind outgoing (string-append "tcp://*:5559"))
    (socket-bind incoming (string-append "tcp://*:5558"))
    (cons outgoing incoming)))

(define (push-output conn msg)
  (socket-send (car conn) msg (u8vector-length msg)))

(define (pull-input conn size)
  (socket-receive (cdr conn) size))

(define send-state
  (let ([last-sent #f])
   (lambda (conn state)
     (if (not (equal? state last-sent))
       (let* ([to-send (with-output-to-string (lambda () (serialize state)))]
              [len (string-length to-send)])
         (debug "sending")
         (push-output conn (string->u8vector (format #f "~16,'0d" len)))
         (push-output conn (string->u8vector to-send))
         (set! last-sent state))))))

(define (receive-state conn)
  (let ([len (string->number (u8vector->string (pull-input conn 16)))])
   (if len
     (let ([state-string (pull-input conn len)])
      (with-input-from-string (u8vector->string state-string) (lambda () (deserialize))))
     (list))))

(define (get-owner-id conn) 'myself) ; FIXME
