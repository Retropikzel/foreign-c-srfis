(test-begin "srfi-170")

(write (posix-time))
(newline)

(write (monotonic-time))
(newline)

(define niceness (nice 1))
(test-assert (number? niceness))
(test-assert (> niceness 0))

(define ui (user-info "retropikzel"))
(write ui)
(newline)

(write (user-info:parsed-full-name ui))
(newline)

#|
(define tmp-dir "/tmp/foreign-c-srfi-170")
(for-each
  (lambda (file)
    (delete-file (string-append tmp-dir "/" file)))
  (directory-files tmp-dir #t))
(when (file-exists? tmp-dir)
  (delete-directory tmp-dir))
(create-directory tmp-dir)

(define tmp-file (string-append tmp-dir "/test.txt"))
(when (file-exists? tmp-file) (delete-file tmp-file))

(with-output-to-file
  tmp-file
  (lambda ()
    (display "Hello")
    (newline)))

(define tmp-dotfile (string-append tmp-dir "/.dot.txt"))
(when (file-exists? tmp-dotfile) (delete-file tmp-dotfile))

(with-output-to-file
  tmp-dotfile
  (lambda ()
    (display "Dot")
    (newline)))

(define tmp-dir-info (file-info tmp-dir #f))
(define tmp-file-info (file-info tmp-file #f))
(define tmp-dotfile-info (file-info tmp-dotfile #f))

(set-file-mode tmp-file 0755)


(define dir1 (open-directory tmp-dir))
(write (read-directory dir1))
(newline)
(write (read-directory dir1))
(newline)
(write (read-directory dir1))
(newline)
(close-directory dir1)

(define dir2 (open-directory tmp-dir #t))
(write (read-directory dir2))
(newline)
(write (read-directory dir2))
(newline)
(write (read-directory dir2))
(newline)
(close-directory dir2)

(display "temp-file-prefix: ")
(display (temp-file-prefix))
(newline)

(display "create-temp-file: ")
(define tf1 (create-temp-file))
(display tf1)
(newline)

(display "create-temp-file, with prefix lol: ")
(define tf2 (create-temp-file "/tmp/lol"))
(display tf2)
(newline)

(call-with-temporary-filename
  (lambda (path)
    (display "call-with-temporary-filename, path: ")
    (display path)
    (newline)))

(display "Current directory: ")
(display (current-directory))
(newline)

(set-current-directory! "/tmp")
(display "Current directory: ")
(display (current-directory))
(newline)

(display "pid: ")
(display (pid))
(newline)

(display "uid: ")
(display (user-uid))
(newline)

(display "gid: ")
(display (user-gid))
(newline)

(display "euid: ")
(display (user-effective-uid))
(newline)

(display "egid: ")
(display (user-effective-gid))
(newline)

(display "user-supplementary-gids: ")
(display (user-supplementary-gids))
(newline)

(display "user-info, uid 0: ")
(display (user-info 0))
(newline)

(display "user-info, name root: ")
(display (user-info "root"))
(newline)

(display "group-info: ")
(display (group-info "root"))
(newline)

(display "set-environment-variable! lol=lel ")
(newline)
(set-environment-variable! "lol" "lel")

;(display "get-environment-variable lol: ")
;(display (get-environment-variable "lol"))
;(newline)

(define movefile "/tmp/test1.txt")
(with-output-to-file
  movefile
  (lambda ()
    (display "Hello")
    (newline)))

(rename-file movefile "/tmp/test2.txt")

(display "File /tmp/test2.txt exists? ")
(display (file-exists? "/tmp/test2.txt"))
(newline)

(display "file-info-directory? on dir: ")
(write (file-info-directory? tmp-dir-info))
(newline)

(display "file-info-directory? on file: ")
(write (file-info-directory? tmp-file-info))
(newline)
|#


(test-end "srfi-170")
