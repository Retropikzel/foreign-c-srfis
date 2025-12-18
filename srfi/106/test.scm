
(define client-socket (make-client-socket "127.0.0.1" "3000"))

(socket-send client-socket (string->utf8 "Hello from test"))

(write client-socket)
(newline)
