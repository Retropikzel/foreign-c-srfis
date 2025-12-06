(define-c-library libc '("stdlib.h") libc-name '((additional-versions ("0" "6"))))
(define-c-procedure c-getenv libc 'getenv 'pointer '(pointer))

(define (get-environment-variable name)
  (let* ((name (c-getenv (string->c-utf8 name)))
         (result (if (c-null? name) #f (string-copy (c-utf8->string name)))))
    (c-free name)
    result))

(define (get-environment-variables)
  '())
