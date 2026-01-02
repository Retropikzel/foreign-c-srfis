

(display "HERE address-family: ")
(write (address-family inet))
(newline)

(display "HERE address-info: ")
(write (address-info v4mapped addrconfig))
(newline)

(display "HERE socket-domain:")
(write (socket-domain stream))
(newline)

(display "HERE ip-protocol: ")
(write (ip-protocol ip))
(newline)

(define-c-library libc `("stdlib.h") libc-name '((additional-versions ("0" "6"))))
(define-c-procedure c-system libc 'system 'int '(pointer))

(c-system (string->c-utf8 "echo \"lol\" | nc -l 3001 &"))

(define sock1 (make-client-socket "127.0.0.1" "3001"))

(display "HERE sock1: ")
(write sock1)
(newline)

(display "HERE sock1 recv: ")
(write (utf8->string (socket-recv sock1 3)))
(newline)

(socket-send sock1 (string->utf8 "Hello from sock1\n"))

(socket-close sock1)


(define sock2-port "3002")
(define sock2 (make-server-socket sock2-port))
(display "HERE sock2: ")
(write sock2)
(newline)

(display (string-append "run: echo \"lol\" | nc 127.0.0.1 " sock2-port))
(newline)

(define client-sock1 (socket-accept sock2))
(display "HERE client-sock1: ")
(write client-sock1)
(newline)

(socket-send client-sock1 (string->utf8 "Hello from client-sock1\n"))

(display "HERE client-sock1 recv: ")
(write (utf8->string (socket-recv client-sock1 3)))
(newline)



#|
(c-system (string->c-utf8 "echo \"lol\" | nc -l -U /tmp/demo.sock &"))

(define sock2 (make-client-socket "/tmp/demo.sock" "3000" *af-unix*))


(display "HERE sock2: ")
(write (utf8->string (socket-recv sock2 3)))
(newline)

(socket-send sock2 (string->utf8 "Hello from sock2\n"))

(socket-close sock2)
|#




