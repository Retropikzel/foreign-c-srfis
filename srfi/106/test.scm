
(define-c-library libc `("stdlib.h") libc-name '((additional-versions ("0" "6"))))
(define-c-procedure c-system libc 'system 'int '(pointer))


(c-system (string->c-utf8 "echo \"lol\" | nc -l 3000 &"))

(define sock1 (make-client-socket "127.0.0.1" "3000"))

(display "HERE sock1: ")
(write (utf8->string (socket-recv sock1 3)))
(newline)

(socket-send sock1 (string->utf8 "Hello from sock1\n"))

(socket-close sock1)


(c-system (string->c-utf8 "echo \"lol\" | nc -l -U /tmp/demo.sock &"))

(define sock2 (make-client-socket "/tmp/demo.sock" "3000" *af-unix*))


(display "HERE sock2: ")
(write (utf8->string (socket-recv sock2 3)))
(newline)

(socket-send sock2 (string->utf8 "Hello from sock2\n"))

(socket-close sock2)
