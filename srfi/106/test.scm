
;(define client-socket (make-client-socket "127.0.0.1" "3000"))
(define client-socket (make-client-socket "/tmp/demo.sock" "3000" *af-unix*))

(socket-send client-socket (string->utf8 "Hello from test"))

(write client-socket)
(newline)
