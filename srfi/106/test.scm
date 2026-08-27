(import (scheme base)
        (scheme write)
        (scheme read)
        (scheme char)
        (scheme file)
        (scheme process-context)
        (retropikzel tap)
        (foreign c)
        (srfi 64)
        (srfi 106))

(test-runner-current (tap-runner))

(test-begin "106")


(test-begin "TCP Client")

(test-begin "URL")
(let ((sock (make-client-socket "tcpbin.com" "4242"))
      (msg "Hello world!"))
  (socket-send sock (string->utf8 msg))
  (test-equal msg (utf8->string (socket-recv sock (string-length msg))))
  (socket-close))
(test-begin "URL")

(test-end "TCP Client")


#|
(define sock1-port "3005")
(define sock2-port "3006")

(define-c-library libc `("stdlib.h") #f '())
(define-c-procedure c-system libc 'system 'int '(pointer))

(display "Testing TCP socket")
(newline)

;(debug (address-family inet))
;(debug (address-info v4mapped addrconfig))
;(debug (socket-domain stream))
;(debug (ip-protocol ip))

(c-system (string->c-bytevector (string-append "echo \"lol\" | nc -l " sock1-port "&")))

(define sock1 (make-client-socket "127.0.0.1" sock1-port))

;(debug sock1)
(write (utf8->string (socket-recv sock1 3)))
(newline)

(socket-send sock1 (string->utf8 "Hello from sock1\n"))

(socket-close sock1)


(define sock2 (make-server-socket sock2-port))
;(debug sock2)

(display (string-append "run: echo \"lol\" | nc 127.0.0.1 " sock2-port))
(newline)

(define client-sock1 (socket-accept sock2))
;(debug client-sock1)

(socket-send client-sock1 (string->utf8 "Hello from client-sock1\n"))

(write (utf8->string (socket-recv client-sock1 3)))
(newline)

|#

(test-end "106")
