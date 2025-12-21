(define-c-library libc
                  `("sys/types.h"
                    "sys/socket.h"
                    "sys/un.h"
                    "netinet/in.h"
                    "netdb.h"
                    "errno.h"
                    "fcntl.h"
                    "poll.h"
                    "string.h")
                  libc-name
                  '((additional-versions ("0" "6"))))

(define-c-procedure c-socket libc 'socket 'int '(int int int))
(define-c-procedure c-getaddrinfo libc 'getaddrinfo 'int '(pointer pointer pointer pointer))
(define-c-procedure c-connect libc 'connect 'int '(int pointer int))
(define-c-procedure c-perror libc 'perror 'void '(pointer))
(define-c-procedure c-fcntl libc 'fcntl 'int '(int int int))
(define-c-procedure c-send libc 'send 'int '(int pointer int int))
(define-c-procedure c-read libc 'read 'int '(int pointer int))
(define-c-procedure c-poll libc 'poll 'int '(pointer int int))
(define-c-procedure c-strcpy libc 'strcpy 'int '(pointer pointer))


(define-record-type <socket>
  (make-socket file-descriptor)
  socket?
  (file-descriptor socket-file-descriptor))

(define *af-inet* 2)
(define *af-inet6* 10)
(define *af-unix* 1)
(define *af-unspec* 0)

(define *sock-stream* 1)
(define *sock-dgram* 2)

(define *ai-canonname* 2)
(define *ai-numerichost* 4)
(define *ai-v4mapped* 8)
(define *ai-all* 16)
(define *ai-addrconfig* 32)

(define *ipproto-ip* 0)
(define *ipproto-tcp* 6)
(define *ipproto-udp* 17)

(define *msg-peek* 17)
(define *msg-oob* 1)
(define *msg-waitall* 256)

(define *shut-rd* 0)
(define *shut-wr* 1)
(define *shut-rdwr* 2)

(define F-SETFL 4)
(define O-NONBLOCK 2048)
(define EINPROGRESS 115)
(define SOL-SOCKET 1)
(define SO-ERROR 4)
(define POLLIN 1)
(define POLLOUT 4)

(define socket-merge-flags (lambda flags (apply + flags)))
(define (socket-purge-flags base-flag . flags) (apply - (cons base-flag flags)))

(define (make-network-socket node service ai-family ai-socktype ai-flags ai-protocol)
  (let* ((addrinfo-hints (let ((pointer (make-c-bytevector 128 0)))
                          (c-bytevector-sint-set! pointer
                                                  (c-type-size 'int)
                                                  ai-family
                                                  (native-endianness)
                                                  (c-type-size 'int))
                          (c-bytevector-sint-set! pointer
                                                  (* (c-type-size 'int) 2)
                                                  ai-socktype
                                                  (native-endianness)
                                                  (c-type-size 'int))
                          pointer))
        (addrinfo (make-c-bytevector 128 0))
        (addrinfo-result
          (call-with-address-of
            addrinfo
            (lambda (addrinfo-address)
              (call-with-address-of
                addrinfo-hints
                (lambda (addrinfo-hints-address)
                  (c-getaddrinfo (string->c-utf8 node)
                                 (string->c-utf8 service)
                                 addrinfo-hints
                                 addrinfo-address))))))
        (socket-file-descriptor
          (c-socket
            ;; ai-family
            (c-bytevector-sint-ref addrinfo
                                   (c-type-size 'int)
                                   (native-endianness)
                                   (c-type-size 'int))
            ;; ai-socktype
            (c-bytevector-sint-ref addrinfo
                                   (* (c-type-size 'int) 2)
                                   (native-endianness)
                                   (c-type-size 'int))
            ;; ai-protocol
            (c-bytevector-sint-ref addrinfo
                                   (* (c-type-size 'int) 3)
                                   (native-endianness)
                                   (c-type-size 'int)))))
    (when (< addrinfo-result 0)
      (c-perror (string->c-utf8 "make-client-socket (addrinfo) error"))
      (raise-continuable "make-client-socket (addrinfo) error"))
    (when (< socket-file-descriptor 0)
      (c-perror (string->c-utf8 "make-client-socket error"))
      (raise-continuable "make-client-socket (socket) error"))
    (when (< (c-fcntl socket-file-descriptor F-SETFL O-NONBLOCK) 0)
      (c-perror (string->c-utf8 "make-client-socket (fcntl) error"))
      (raise-continuable "make-client-socket (fcntl) error"))
    (letrec* ((connect-result
                (c-connect socket-file-descriptor
                           ;; ai-addr
                           (c-bytevector-pointer-ref addrinfo
                                                     (* (c-type-size 'int) 6))
                           ;; ai-addrlen
                           (c-bytevector-sint-ref addrinfo
                                                  (* (c-type-size 'int) 4)
                                                  (native-endianness)
                                                  (c-type-size 'int))))
              (pollfd (make-c-bytevector 128 0)))
      (c-bytevector-sint-set! pollfd
                              0
                              socket-file-descriptor
                              (native-endianness)
                              (c-type-size 'int))
      (c-bytevector-sint-set! pollfd
                              0
                              0
                              (native-endianness)
                              (c-type-size 'int))
      ;; TODO Why 8 works but 1 does not?
      (when (= (c-poll pollfd 8 5000) 0)
        (error "make-client-socket (poll) error")))
    (make-socket socket-file-descriptor)))

(define (make-unix-socket node service ai-family ai-socktype ai-flags ai-protocol)
  (let* ((socket-file-descriptor (c-socket ai-family ai-socktype 0))
         (ai-family-size 2)
         (sockaddr
           (let* ((pointer (make-c-bytevector 128 0))
                  (pointer-address (c-bytevector->address pointer))
                  (node-pointer (address->c-bytevector
                                     (+ pointer-address ai-family-size))))
             (c-bytevector-u16-native-set! pointer 0 *af-unix*)
             (c-strcpy node-pointer (string->c-utf8 node))
           pointer))
    (sockaddr-size (+ ai-family-size (bytevector-length (string->utf8 node)))))
    (when (< socket-file-descriptor 0)
      (c-perror (string->c-utf8 "make-client-socket error"))
      (raise-continuable "make-client-socket (socket) error"))
    (when (< (c-fcntl socket-file-descriptor F-SETFL O-NONBLOCK) 0)
      (c-perror (string->c-utf8 "make-client-socket (fcntl) error"))
      (raise-continuable "make-client-socket (fcntl) error"))
    (let ((connect-result (c-connect socket-file-descriptor sockaddr sockaddr-size)))
      (when (< connect-result 0)
        (c-perror (string->c-utf8 "make-client-socket (connect) error"))
        (raise-continuable "make-client-socket (connect) error"))
      (make-socket socket-file-descriptor))))

(define (make-client-socket node service . args)
  (let* ((ai-family (if (>= (length args) 1) (list-ref args 0) *af-inet*))
         (ai-socktype (if (>= (length args) 2) (list-ref args 1) *sock-stream*))
         (ai-flags (if (>= (length args) 3)
                     (list-ref args 2)
                     (socket-merge-flags *ai-v4mapped* *ai-addrconfig*)))
         (ai-protocol
           (if (>= (length args) 4)
             (list-ref args 3)
             *ipproto-ip*)))
    (if (equal? ai-family *af-unix*)
      (make-unix-socket node service ai-family ai-socktype ai-flags ai-protocol)
      (make-network-socket node service ai-family ai-socktype ai-flags ai-protocol))))

(define message-type
  (lambda names
    (if (null? names)
      #f
      (map
        (lambda (name)
          (cond ((equal? name 'none) #f)
                ((equal? name 'peek) *msg-peek*)
                ((equal? name 'oob) *msg-oob*)
                ((equal? name 'wait-all) *msg-waitall*)))
        names))))

(define (socket-send socket bv . flags)
  (let* ((msg (bytevector->c-bytevector bv))
         (msg-len (bytevector-length bv))
         (sent-count (c-send (socket-file-descriptor socket) msg msg-len 0)))
    (when (= sent-count -1)
      (c-perror (string->c-utf8 "socket-send error"))
      (raise-continuable "socket-send error"))
    sent-count))

(define (socket-recv-loop socket bytes-pointer size)
  (let ((read-result (c-read (socket-file-descriptor socket)
                             bytes-pointer
                             size)))
    (cond ((< read-result 1) (socket-recv-loop socket bytes-pointer size))
          (else
            (c-bytevector->bytevector bytes-pointer size)))))

(define (socket-recv socket size . flags)
  ;; TODO FIXME If connection is closed return empty bytevector
  (let* ((msg-type (if (null? flags)
                     (message-type 'none)
                     (apply message-type flags)))
         (bytes-pointer (make-c-bytevector size 0)))
    (socket-recv-loop socket bytes-pointer size)))
