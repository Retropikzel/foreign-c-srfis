(define-c-library libc
                  '("stdlib.h"
                    "stdio.h"
                    "string.h"
                    "dirent.h"
                    "sys/stat.h"
                    "sys/types.h"
                    "unistd.h"
                    "pwd.h"
                    "grp.h"
                    "fcntl.h")
                  libc-name
                  '((additional-versions ("0" "6"))))

(define-c-procedure c-perror libc 'perror 'void '(pointer))
(define-c-procedure c-mkdir libc 'mkdir 'int '(pointer int))
(define-c-procedure c-rmdir libc 'rmdir 'int '(pointer))
(define-c-procedure c-stat libc 'stat 'int '(pointer pointer))
(define-c-procedure c-lstat libc 'stat 'int '(pointer pointer))
(define-c-procedure c-open libc 'open 'int '(pointer int))
(define-c-procedure c-opendir libc 'opendir 'pointer '(pointer))
(define-c-procedure c-readdir libc 'readdir 'pointer '(pointer))
(define-c-procedure c-close libc 'close 'int '(int))
(define-c-procedure c-closedir libc 'closedir 'int '(pointer))
(define-c-procedure c-realpath libc 'realpath 'pointer '(pointer pointer))
(define-c-procedure c-chmod libc 'chmod 'int '(pointer int))
(define-c-procedure c-getpid libc 'getpid 'int '())
(define-c-procedure c-time libc 'time 'int '(pointer))
(define-c-procedure c-srand libc 'srand 'void '(int))
(define-c-procedure c-rand libc 'rand 'int '())
(define-c-procedure c-getcwd libc 'getcwd 'pointer '(pointer int))
(define-c-procedure c-chdir libc 'chdir 'int '(pointer))
(define-c-procedure c-getuid libc 'getuid 'int '())
(define-c-procedure c-getgid libc 'getgid 'int '())
(define-c-procedure c-geteuid libc 'geteuid 'int '())
(define-c-procedure c-getegid libc 'getegid 'int '())
(define-c-procedure c-getgroups libc 'getgroups 'int '(int pointer))
(define-c-procedure c-getpwuid libc 'getpwuid 'pointer '(int))
(define-c-procedure c-getpwnam libc 'getpwnam 'pointer '(pointer))
(define-c-procedure c-getgrgid libc 'getgrgid 'pointer '(int))
(define-c-procedure c-getgrnam libc 'getgrnam 'pointer '(pointer))
(define-c-procedure c-setenv libc 'setenv 'int '(pointer pointer int))
(define-c-procedure c-unsetenv libc 'unsetenv 'int '(pointer))
(define-c-procedure c-rename libc 'rename 'int '(pointer pointer))
(define-c-procedure c-link libc 'link 'int '(pointer pointer))
(define-c-procedure c-slink libc 'link 'int '(pointer pointer))
(define-c-procedure c-chown libc 'chown 'int '(pointer int int))

(define slash (cond-expand (windows "\\") (else "/")))
(define randomized? #f)

(define (random-to max)
  (when (not randomized?)
    (c-srand (c-time (make-c-null)))
    (set! randomized? #t))
  (modulo (c-rand) max))

(define (random-string size)
  (letrec
    ((looper
       (lambda (result integer)
         (cond ((= (string-length result) size) result)
               ((or (< integer 0)
                    (> integer 128))
                (looper result (random-to 128)))
               (else
                 (let ((char (integer->char integer)))
                   (if (not (or (char-alphabetic? char)
                                (char-numeric? char)))
                     (looper result (c-rand))
                     (looper (string-append result
                                            (string (integer->char integer)))
                             (random-to 128)))))))))
    (looper "" (random-to 128))))

(define-record-type file-info-record
  (make-file-info-record device inode mode nlinks uid gid rdev size blksize blocks atime mtime ctime fname/port follow?)
  file-info?
  (device file-info:device)
  (inode file-info:inode)
  (mode file-info:mode)
  (nlinks file-info:nlinks)
  (uid file-info:uid)
  (gid file-info:gid)
  (rdev file-info:rdev)
  (size file-info:size)
  (blksize file-info:blksize)
  (blocks file-info:blocks)
  (atime file-info:atime)
  (mtime file-info:mtime)
  (ctime file-info:ctime)
  (fname/port file-info:fname/port)
  (follow? file-info:follow?))

(define (file-info-directory? file-info)
  (let ((handle (c-open (string->c-utf8 (file-info:fname/port file-info)) 2)))
    (cond ((> handle 0) (c-close handle) #f)
          (else #t))))

(define (file-info fname/port follow?)
  (when (port? fname/port)
    (error "file-info implementation does not support ports as arguments"))
  (let* ((fname-pointer (string->c-utf8 fname/port))
         (stat-pointer (make-c-bytevector 256))
         (result (if follow?
                   (c-stat fname-pointer stat-pointer)
                   (c-lstat fname-pointer stat-pointer)))
         (error-message "file-info error")
         (error-pointer (string->c-utf8 error-message)))
    (when (< result 0)
      (c-perror error-pointer)
      (c-free fname-pointer)
      (c-free stat-pointer)
      (c-free error-pointer)
      (error error-message fname/port))
    (make-file-info-record #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 0) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 1) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 2) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 3) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 4) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 5) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 6) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 7) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 8) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 9) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 10) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 11) (native-endianness))
                           #f ;(c-bytevector-u64-ref stat-pointer (* (c-type-size 'uint64) 12) (native-endianness))
                           fname/port
                           follow?)))

(define create-directory
  (lambda (fname . permission-bits)
    (let* ((fname-pointer (string->c-utf8 fname))
           (mode (if (null? permission-bits)
                   #o775
                   (string->number (string-append "#o"
                                                  (number->string (car permission-bits))))))
           (result (c-mkdir fname-pointer mode))
           (error-message "create-directory error")
           (error-pointer (string->c-utf8 error-message)))
      (c-free fname-pointer)
      (when (< result 0)
        (c-perror error-pointer)
        (c-free error-pointer)
        (error error-message)))))

(define (create-hard-link old-fname new-fname)
  (c-link (string->c-utf8 old-fname)
          (string->c-utf8 new-fname)))

(define (create-symlink old-fname new-fname)
  (c-slink (string->c-utf8 old-fname)
           (string->c-utf8 new-fname)))

(define (rename-file old-fname new-fname)
  (c-rename (string->c-utf8 old-fname) (string->c-utf8 new-fname)))

(define (delete-directory fname)
  (let* ((fname-pointer (string->c-utf8 fname))
         (result (c-rmdir fname-pointer))
         (error-message "delete-directory error")
         (error-pointer (string->c-utf8 error-message)))
    (c-free fname-pointer)
    (when (< result 0)
      (c-perror error-pointer)
      (c-free error-pointer)
      (error error-message))))

(define (set-file-owner fname uid gid)
  (let ((fname-pointer (string->c-utf8 fname)))
    (c-chown fname-pointer uid gid)
    (c-free fname-pointer)))

(define (pointer-string-read pointer offset)
  (letrec* ((looper (lambda (c index result)
                      (if (char=? c #\null)
                        (list->string (reverse result))
                        (looper (c-bytevector-char-ref pointer
                                                       (+ offset index))
                                (+ index 1)
                                (cons c result))))))
    (looper (c-bytevector-char-ref pointer offset) 1 (list))))

; struct dirent d_name offset on linux
(define d-name-offset 19)

(define directory-files
  (lambda (dir . dotfiles?)
    (letrec* ((include-dotfiles? (if (null? dotfiles?) #f (car dotfiles?)))
              (path-pointer (string->c-utf8 dir))
              (directory-pointer (c-opendir path-pointer))
              (error-message "directory-files error")
              (error-pointer (string->c-utf8 error-message))
              (dotfile? (lambda (name) (char=? (string-ref name 0) #\.)))
              (looper (lambda (directory-entity files)
                        (if (c-null? directory-entity)
                          files
                          (let ((name (pointer-string-read directory-entity
                                                           d-name-offset)))
                            (looper (c-readdir directory-pointer)
                                    (cond ((string=? name ".") files)
                                          ((string=? name "..") files)
                                          ((and include-dotfiles?
                                                (dotfile? name))
                                           (cons name files))
                                          ((not (dotfile? name))
                                           (cons name files))
                                          (else files))))))))
      (when (c-null? directory-pointer)
        (c-perror error-pointer)
        ;(c-free error-pointer)
        ;(c-free directory)
        ;(c-free path-pointer)
        (error error-message))
      (let ((files (looper (c-readdir directory-pointer) (list))))
        ;(c-free error-pointer)
        ;(c-free directory-pointer)
        ;(c-free path-pointer)
        (c-closedir directory-pointer)
        files))))

(define real-path
  (lambda (path)
    (let* ((path-pointer (string->c-utf8 path))
           (real-path-pointer (c-realpath path-pointer (make-c-null)))
           (real-path (string-copy (c-utf8->string real-path-pointer))))
      (c-free path-pointer)
      (c-free real-path-pointer)
      real-path)))

(define (set-file-mode path mode)
  (c-chmod (string->c-utf8 path)
           (string->number (string-append "#o" (number->string mode)))))

(define-record-type <directory>
  (make-directory handle dot-files?)
  directory?
  (handle directory:handle)
  (dot-files? directory:dot-files?))

(define (open-directory path . dot-files?)
  (make-directory (c-opendir (string->c-utf8 path))
                  (if (null? dot-files?)
                    #f
                    (car dot-files?))))

(define (read-directory directory-object)
  (let ((directory-entity (c-readdir (directory:handle directory-object))))
    (if (c-null? directory-entity)
      (eof-object)
      (let ((name (pointer-string-read directory-entity d-name-offset)))
        (cond ((or (string=? name ".")
                   (string=? name ".."))
               (read-directory directory-object))
              ((and (directory:dot-files? directory-object)
                    (char=? (string-ref name 0) #\.))
               name)
              ((char=? (string-ref name 0) #\.)
               (read-directory directory-object))
              (else name))))))

(define (close-directory directory-object)
  (c-closedir (directory:handle directory-object)))

(define temp-file-prefix
  (make-parameter
    (if (get-environment-variable "TMPDIR")
      (string-append (get-environment-variable "TMPDIR")
                     slash
                     (number->string (c-getpid)))
      (string-append
        (cond-expand (windows (get-environment-variable "TMP")) (else "/tmp"))
        slash
        (number->string (c-getpid))))))

(define create-temp-file
  (lambda prefix
    (let* ((tmpdir (cond-expand
                     (windows (get-environment-variable "TMP"))
                     (else "/tmp")))
           (real-prefix (if (null? prefix)
                          (string-append tmpdir slash (number->string (c-getpid)))
                          (car prefix)))
           (path (string-append real-prefix "-" (random-string 6))))
      (if (file-exists? path)
        (create-temp-file real-prefix)
        (begin
          (with-output-to-file path (lambda () (display "")))
          (set-file-mode path 600)
          path)))))

(define (call-with-temporary-filename maker . prefix)
  (let* ((tmpdir (cond-expand (windows (get-environment-variable "TMP"))
                              (else "/tmp")))
         (real-prefix (if (null? prefix)
                        (string-append tmpdir slash (number->string (c-getpid)))
                        (car prefix)))
         (path (string-append real-prefix "-" (random-string 6))))
    (apply maker (list path))))

(define (current-directory)
  (let* ((path-pointer (make-c-bytevector 1024))
         (path (begin
                 (c-getcwd path-pointer 1024)
                 (string-copy (c-utf8->string path-pointer)))))
    (c-free path-pointer)
    path))

(define (set-current-directory! path)
  (c-chdir (string->c-utf8 path)))

(define (pid)
  (c-getpid))

(define (user-uid)
  (c-getuid))

(define (user-gid)
  (c-getgid))

(define (user-effective-uid)
  (c-geteuid))

(define (user-effective-gid)
  (c-getegid))

(define (groups-loop max-count count groups-pointer result)
  (if (>= count max-count)
    result
    (groups-loop max-count
                 (+ count 1)
                 groups-pointer
                 (append result
                         (list (c-bytevector-sint-ref groups-pointer
                                                      (* (c-type-size 'int) count)
                                                      (native-endianness)
                                                      (c-type-size 'int)))))))

(define (user-supplementary-gids)
  (let* ((group-count (c-getgroups 0 (make-c-null)))
         (groups (make-c-bytevector (* (c-type-size 'int) group-count))))
    (c-getgroups group-count groups)
    (groups-loop group-count 0 groups (list))))

(define-record-type <user-info>
  (make-user-info name uid gid home-dir shell full-name)
  user-info?
  (name user-info:name)
  (uid user-info:uid)
  (gid user-info:gid)
  (home-dir user-info:home-dir)
  (shell user-info:shell)
  (full-name user-info:full-name))

(define (user-info uid/name)
  (let ((password-struct (if (number? uid/name)
                           (c-getpwuid uid/name)
                           (c-getpwnam (string->c-utf8 uid/name)))))
    (make-user-info (c-utf8->string (c-bytevector-pointer-ref password-struct
                                                              0))
                    (c-bytevector-sint-ref password-struct
                                           (* (c-type-size 'pointer) 2)
                                           (native-endianness)
                                           (c-type-size 'int))
                    (c-bytevector-sint-ref password-struct
                                           (+ (* (c-type-size 'pointer) 2)
                                              (c-type-size 'int))
                                           (native-endianness)
                                           (c-type-size 'int))
                    (c-utf8->string (c-bytevector-pointer-ref password-struct
                                                              (+ (* (c-type-size 'pointer) 3)
                                                                 (* (c-type-size 'int) 2))))
                    (c-utf8->string (c-bytevector-pointer-ref password-struct
                                                              (+ (* (c-type-size 'pointer) 4)
                                                                 (* (c-type-size 'int) 2))))
                    (c-utf8->string (c-bytevector-pointer-ref password-struct
                                                              (+ (* (c-type-size 'pointer) 2)
                                                                 (* (c-type-size 'int) 2)))))))


(define-record-type <group-info>
  (make-group-info name gid)
  group-info?
  (name group-info:name)
  (gid group-info:gid))

(define (group-info gid/name)
  (let ((group-struct (if (number? gid/name)
                        (c-getgrgid gid/name)
                        (c-getgrnam (string->c-utf8 gid/name)))))
    (make-group-info
      (c-utf8->string (c-bytevector-pointer-ref group-struct 0))
      (c-bytevector-sint-ref group-struct
                             (* (c-type-size 'pointer) 2)
                             (native-endianness)
                             (c-type-size 'int)))))

(define (set-environment-variable! name value)
  (c-setenv (string->c-utf8 name) (string->c-utf8 value) 1))

(define (delete-environment-variable! name)
  (c-unsetenv (string->c-utf8 name)))
