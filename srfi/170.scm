(define-c-library libc
                  '("stdlib.h"
                    "stdio.h"
                    "string.h"
                    "dirent.h"
                    "sys/stat.h"
                    "sys/statvfs.h"
                    "sys/types.h"
                    "unistd.h"
                    "pwd.h"
                    "grp.h"
                    "fcntl.h")
                  #f
                  '())

(define-c-procedure c-perror libc 'perror 'void '(pointer))
(define-c-procedure c-mkdir libc 'mkdir 'int '(pointer int))
(define-c-procedure c-mkfifo libc 'mkfifo 'int '(pointer int))
(define-c-procedure c-readlink libc 'readlink 'int '(pointer pointer int))
(define-c-procedure c-rmdir libc 'rmdir 'int '(pointer))
(define-c-procedure c-stat libc 'stat 'int '(pointer pointer))
(define-c-procedure c-lstat libc 'stat 'int '(pointer pointer))
(define-c-procedure c-open libc 'open 'int '(pointer int))
(define-c-procedure c-opendir libc 'opendir 'pointer '(pointer))
(define-c-procedure c-dirfd libc 'dirfd 'int '(pointer))
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
(define-c-procedure c-clock-gettime libc 'clock_gettime 'int '(int pointer))
(define-c-procedure c-nice libc 'nice 'int '(int))
(define-c-procedure c-umask libc 'umask 'uint '(int))
(define-c-procedure
  c-utimensat libc 'utimensat 'int '(int pointer pointer int))
(define-c-procedure c-truncate libc 'truncate 'int '(pointer int))
(define-c-procedure c-statvfs libc 'statvfs 'int '(pointer pointer))

(define slash (cond-expand (windows "\\") (else "/")))
(define randomized? #f)

(define (string-split str mark)
  (let* ((str-l (string->list str))
         (res (list))
         (last-index 0)
         (index 0)
         (splitter
           (lambda (c)
             (cond ((char=? c mark)
                    (begin
                      (set! res
                        (append res
                                (list (string-copy str last-index index))))
                      (set! last-index (+ index 1))))
                   ((equal? (length str-l) (+ index 1))
                    (set! res
                      (append res
                              (list (string-copy str
                                                 last-index
                                                 (+ index 1)))))))
             (set! index (+ index 1)))))
    (for-each splitter str-l)
    res))

(define (string-char-replace replace-in replace-this replace-with)
  (let ((result ""))
    (string-for-each
      (lambda (c)
        (if (char=? c replace-this)
          (set! result (string-append result replace-with))
          (set! result (string-append result (string c)))))
      replace-in)
    result))

(define (random-to max)
  (when (not randomized?)
    (c-srand (c-time (c-bytevector-null)))
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

(define-record-type <file-info>
  (make-file-info device
                  inode
                  mode
                  nlinks
                  uid
                  gid
                  rdev
                  size
                  blksize
                  blocks
                  atime
                  mtime
                  ctime
                  fname/port
                  follow?)
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
  (let ((handle (c-open (string->c-bytevector
                          (file-info:fname/port file-info)) 2)))
    (cond ((> handle 0) (c-close handle) #f)
          (else #t))))

(define-c-struct-type stat-struct
                      `((st_dev int)
                        (st_ino uint)
                        (st_mode uint)
                        (st_nlink int)
                        (st_uid uint)
                        (st_gid uint)
                        (st_rdev int)
                        (st_size int)
                        (st_blksize int)
                        (st_blocks int)
                        (st_atim.tv_sec long)
                        (st_atim.tv_nsec long)
                        (st_mtim.tv_sec long)
                        (st_mtim.tv_nsec long)
                        (st_ctim.tv_sec long)
                        (st_ctim.tv_nsec long)))
;;> The file-info procedure returns a file-info record containing useful
;;> information about a file. If the follow? flag is true the procedure will
;;> follow symlinks and report on the file to which they refer. If follow? is
;;> false the procedure checks the actual file itself, even if it's a symlink.
;;> The follow? flag is ignored if the file argument is a port.
(define (file-info fname/port follow?)
  (when (port? fname/port)
    (error "file-info implementation does not support ports as arguments"))
  (let* ((fname-pointer (string->c-bytevector fname/port))
         (stat-pointer (make-c-bytevector (c-type-size stat-struct)))
         (result (if follow?
                   (c-stat fname-pointer stat-pointer)
                   (c-lstat fname-pointer stat-pointer))))
    (when (< result 0)
      (let* ((error-message "file-info error")
             (error-pointer (string->c-bytevector error-message)))
        (c-perror error-pointer)
        (c-bytevector-free fname-pointer)
        (c-bytevector-free stat-pointer)
        (c-bytevector-free error-pointer)
        (error error-message fname/port)))
    (let ((fi (make-file-info
                (c-bytevector-ref stat-pointer stat-struct 'st_dev)
                (c-bytevector-ref stat-pointer stat-struct 'st_ino)
                (c-bytevector-ref stat-pointer stat-struct 'st_mode)
                (c-bytevector-ref stat-pointer stat-struct 'st_nlink)
                (c-bytevector-ref stat-pointer stat-struct 'st_uid)
                (c-bytevector-ref stat-pointer stat-struct 'st_gid)
                (c-bytevector-ref stat-pointer stat-struct 'st_rdev)
                (c-bytevector-ref stat-pointer stat-struct 'st_size)
                (c-bytevector-ref stat-pointer stat-struct 'st_blksize)
                (c-bytevector-ref stat-pointer stat-struct 'st_blocks)
                (make-time time-utc
                           (c-bytevector-ref stat-pointer stat-struct 'st_atim.tv_sec)
                           (c-bytevector-ref stat-pointer stat-struct 'st_atim.tv_nsec))
                (make-time time-utc
                           (c-bytevector-ref stat-pointer stat-struct 'st_mtim.tv_sec)
                           (c-bytevector-ref stat-pointer stat-struct 'st_mtim.tv_nsec))
                (make-time time-utc
                           (c-bytevector-ref stat-pointer stat-struct 'st_ctim.tv_sec)
                           (c-bytevector-ref stat-pointer stat-struct 'st_ctim.tv_nsec))
                fname/port
                follow?)))
      (c-bytevector-free fname-pointer)
      (c-bytevector-free stat-pointer)
      fi)))
;;> The permission-bits for create-directory default to #o775 but are masked
;;> by the current umask.
(define create-directory
  (lambda (fname . permission-bits)
    (let* ((fname-pointer (string->c-bytevector fname))
           (mode (if (null? permission-bits)
                   #o775
                   (string->number
                     (string-append
                       "#o"
                       (number->string (car permission-bits))))))
           (result (c-mkdir fname-pointer mode))
           (error-message "create-directory error")
           (error-pointer (string->c-bytevector error-message)))
      (c-bytevector-free fname-pointer)
      (when (< result 0)
        (c-perror error-pointer)
        (c-bytevector-free error-pointer)
        (error error-message))
      (c-bytevector-free error-pointer))))

;;> The permission-bits for create-directory default to #o664, but are masked
;;> by the current umask.
(define (create-fifo fname . permission-bits)
  (let* ((fname-pointer (string->c-bytevector fname))
         (mode (if (null? permission-bits)
                 #o664
                 (string->number
                   (string-append
                     "#o"
                     (number->string (car permission-bits))))))
         (result (c-mkfifo fname-pointer mode))
         (error-message "create-fifo error")
         (error-pointer (string->c-bytevector error-message)))
    (c-bytevector-free fname-pointer)
    (when (< result 0)
      (c-perror error-pointer)
      (c-bytevector-free error-pointer)
      (error error-message))
    (c-bytevector-free error-pointer)))

(define (create-hard-link old-fname new-fname)
  (c-link (string->c-bytevector old-fname)
          (string->c-bytevector new-fname)))

(define (create-symlink old-fname new-fname)
  (c-slink (string->c-bytevector old-fname)
           (string->c-bytevector new-fname)))

(define (internal-read-symlink fname buffer-length)
  (let* ((path-pointer (string->c-bytevector fname))
         (buffer (make-c-bytevector buffer-length))
         (result (c-readlink path-pointer buffer (- buffer-length 1)))
         (error-message "read-symlink error")
         (error-pointer (string->c-bytevector error-message)))
    (cond ((< result 0)
           (c-perror error-pointer)
           (c-bytevector-free error-pointer)
           (error error-message))
          ((> result buffer-length)
           (c-bytevector-free path-pointer)
           (c-bytevector-free buffer)
           (internal-read-symlink fname (+ buffer-length buffer-length)))
          (else
            (c-bytevector-set! buffer 'u8 result null-byte)
            (let ((name (c-bytevector->string buffer)))
              (c-bytevector-free path-pointer)
              (c-bytevector-free buffer)
              name)))))

;;> Return the filename referenced by the symlink fname.
(define (read-symlink fname) (internal-read-symlink fname 128))

;;> If you override an existing object, then old-fname and new-fname must
;;> type-match — either both directories, or both non-directories.
;;> This is required by the semantics of POSIX rename().
;;>
;;> Calling rename-file on a symbolic link will rename the symbolic link,
;;> not the file it refers to.
;;>
;;> Remark: There is an unfortunate atomicity problem with the rename-file
;;> procedure: if you create file new-fname sometime between rename-file's
;;> existence check and the actual rename operation, your file will be
;;> clobbered with old-fname. There is no way to prevent this problem; at
;;> least it is highly unlikely to occur in practice.
(define (rename-file old-fname new-fname)
  (c-rename (string->c-bytevector old-fname)
            (string->c-bytevector new-fname)))

;;> This procedure deletes directories from the file system. An error is
;;> signaled if fname is not a directory or is not empty.
(define (delete-directory fname)
  (let* ((fname-pointer (string->c-bytevector fname))
         (result (c-rmdir fname-pointer)))
    (c-bytevector-free fname-pointer)
    (when (< result 0)
      (let* ((error-message "delete-directory error")
             (error-pointer (string->c-bytevector error-message)))
        (c-perror error-pointer)
        (c-bytevector-free error-pointer)
        (error error-message)))))

;;> This procedure sets the owner and group of a file specified by supplying
;;> the filename. If the uid argument is the constant owner/unchanged, the
;;> owner is not changed; if the gid argument is the constant group/unchanged,
;;> the group is not changed. Setting file ownership usually requires root
;;> privileges. This procedure follows symlinks and changes the files to which
;;> they refer.
(define (set-file-owner fname uid gid)
  (let ((fname-pointer (string->c-bytevector fname)))
    (c-chown fname-pointer uid gid)
    (c-bytevector-free fname-pointer)))

(define-c-array-type timespec-array 'long)
;;> \procedure{(set-file-times fname [access-time-object modify-time-object])}
;;> This procedure sets the access and modified times for the file fname to
;;> the supplied time object values. It is an error if they are not of type
;;> time-utc. If neither time argument is supplied, they are both taken to be
;;> the current time. The constants time/now and time/unchanged are bound to
;;> values used to specify the current time and an unchanged time
;;> respectively. It is an error if exactly one time is provided. This
;;> procedure will follow symlinks and set the times of the file to which it
;;> refers. If the procedure completes successfully, the file's time of last
;;> status-change (ctime) is set to the current time.
(define (set-file-times fname . args)
  (when (and (not (= (length args) 0))
             (not (= (length args) 2)))
    (error
      (string-append "set-file-times error: "
                     "It is an error if exactly one time is provided")))
  (let* ((current-time (posix-time))
         (access-time-object (if (null? args)
                               current-time
                               (car args)))
         (modify-time-object (if (or (null? args)
                                     (< (length args) 2))
                               current-time
                               (cadr args)))
         (fname-cbv (string->c-bytevector fname))
         (timespecs-cbv (make-c-bytevector (c-type-size* 'long 4)))
         (current-dir-cbv (string->c-bytevector (current-directory)))
         (current-dir-stream (c-opendir current-dir-cbv))
         (current-dir-fd (c-dirfd current-dir-stream)))
    (c-bytevector-set!
      timespecs-cbv timespec-array 0 (time-second access-time-object))
    (c-bytevector-set!
      timespecs-cbv timespec-array 1 (time-nanosecond access-time-object))
    (c-bytevector-set!
      timespecs-cbv timespec-array 2 (time-second modify-time-object))
    (c-bytevector-set!
      timespecs-cbv timespec-array 3 (time-nanosecond modify-time-object))
    (let ((result (c-utimensat current-dir-fd fname-cbv timespecs-cbv 0)))
      (c-bytevector-free fname-cbv)
      (c-bytevector-free timespecs-cbv)
      (c-bytevector-free current-dir-cbv)
      (c-bytevector-free current-dir-stream)
      (when (< result 0)
        (let* ((error-message "set-file-times error")
               (error-pointer (string->c-bytevector error-message)))
          (c-perror error-pointer)
          (c-bytevector-free error-pointer)
          (error error-message))))))

;;> The specified file is truncated to len bytes in length.
(define (truncate-file fname/port len)
  (when (not (exact-integer? len))
    (error "truncate-file error: len must be exact-integer"))
  (when (not (string? fname/port))
    (error "truncate-file error: ports not supported yet"))
  (let* ((fname/port-cbv (string->c-bytevector fname/port))
         (result (c-truncate fname/port-cbv len)))
    (c-bytevector-free fname/port-cbv)
    (when (< result 0)
      (let* ((error-message "truncate-file error")
             (error-pointer (string->c-bytevector error-message)))
        (c-perror error-pointer)
        (c-bytevector-free error-pointer)
        (error error-message)))))

(define (pointer-string-read pointer offset)
  (letrec* ((looper (lambda (c index result)
                      (if (char=? c #\null)
                        (list->string (reverse result))
                        (looper (c-bytevector-ref pointer
                                                  'char
                                                  (+ offset index))
                                (+ index 1)
                                (cons c result))))))
    (looper (c-bytevector-ref pointer 'char offset) 1 (list))))

; struct dirent d_name offset on linux
(define d-name-offset 19)

;;> Return a list of filenames in directory dir. The dotfiles? flag
;;> (default #f) causes files beginning with . to be included in the list.
;;> Regardless of the value of dotfiles?, the two files . and .. are never
;;> returned.
;;> The directory dir is not prepended to each filename in the result list.
;;> That is,
;;>
;;>    (directory-files "/etc")
;;>
;;>returns
;;>
;;>    ("chown" "exports" "fstab" ...)
;;>
;;>not
;;>
;;>    ("/etc/chown" "/etc/exports" "/etc/fstab" ...)
;;>
;;> To use the filenames in the returned list, the programmer can either
;;> manually prepend the directory, or change to the directory before using
;;> the filenames.
(define directory-files
  (lambda (dir . dotfiles?)
    (letrec* ((include-dotfiles? (if (null? dotfiles?) #f (car dotfiles?)))
              (path-pointer (string->c-bytevector dir))
              (directory-pointer (c-opendir path-pointer))
              (error-message "directory-files error")
              (error-pointer (string->c-bytevector error-message))
              (dotfile? (lambda (name) (char=? (string-ref name 0) #\.)))
              (looper (lambda (directory-entity files)
                        (if (c-bytevector-null? directory-entity)
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
      (when (c-bytevector-null? directory-pointer)
        (c-perror error-pointer)
        ;(c-bytevector-free error-pointer)
        ;(c-bytevector-free directory)
        ;(c-bytevector-free path-pointer)
        (error error-message))
      (let ((files (looper (c-readdir directory-pointer) (list))))
        ;(c-bytevector-free error-pointer)
        ;(c-bytevector-free directory-pointer)
        ;(c-bytevector-free path-pointer)
        (c-closedir directory-pointer)
        files))))

;;> This procedure sets the mode bits of a file specified by supplying the
;;> filename. This procedure follows symlinks and changes the files to which
;;> they refer.
(define (set-file-mode path mode)
  (c-chmod (string->c-bytevector path)
           (string->number (string-append "#o" (number->string mode)))))

(define-record-type <directory>
  (make-directory handle dot-files?)
  directory?
  (handle directory:handle)
  (dot-files? directory:dot-files?))

;;> Opens the directory with the specified pathname for reading, returning an
;;> opaque directory object.

;;> The dot-files? argument controls whether filenames beginning with "." are
;;> returned. If it is #f, which is the default, they are not. The filenames
;;> . and .. are never returned.
(define (open-directory path . dot-files?)
  (make-directory (c-opendir (string->c-bytevector path))
                  (if (null? dot-files?)
                    #f
                    (car dot-files?))))

;;> Returns the name of the next available file, or the end-of-file object if
;;> there are no more files.

;;> The dot-files? argument controls whether filenames beginning with "." are
;;> returned. If it is #f, which is the default, they are not. The filenames
;;> . and .. are never returned.
(define (read-directory directory-object)
  (let ((directory-entity (c-readdir (directory:handle directory-object))))
    (if (c-bytevector-null? directory-entity)
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

;;> Closes a directory object.
(define (close-directory directory-object)
  (c-closedir (directory:handle directory-object)))

;;> Returns an absolute pathname derived from pathname that names the same
;;> file and whose resolution does not involve dot (.), dot-dot (..), or
;;> symlinks.
(define real-path
  (lambda (path)
    (let* ((path-pointer (string->c-bytevector path))
           (real-path-pointer (c-realpath path-pointer (c-bytevector-null)))
           (real-path (string-copy (c-bytevector->string real-path-pointer))))
      (c-bytevector-free path-pointer)
      (c-bytevector-free real-path-pointer)
      real-path)))

;;> SRFI 39 or R7RS parameter that returns a string when invoked. Its initial
;;> value is the value of the environment variable TMPDIR concatenated with
;;> "/pid" if TMPDIR is set and to "/tmp/pid" otherwise, where pid is the id
;;> of the current process.
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

;;> Creates a new temporary file and returns its name. The optional argument
;;> specifies the filename prefix to use, and defaults to the result of
;;> invoking temp-file-prefix. The procedure generates a sequence of filenames
;;> that have prefix as a common prefix, looking for a filename that doesn't
;;> already exist in the file system. When it finds one, it creates it with
;;> permission #o600 and returns the filename. (The file permission can be
;;> changed to a more permissive permission with set-file-mode after being
;;> created.)

;;> This file is guaranteed to be brand new. No other process will have it
;;> open. This procedure does not simply return a filename that is very likely
;;> to be unused. It returns a filename that definitely did not exist at the
;;> moment create-temp-file created it.

;;> It is not necessary for the process's pid to be a part of the filename
;;> for the uniqueness guarantees to hold. The pid component of the default
;;> prefix simply serves to scatter the name searches into sparse regions, so
;;> that collisions are less likely to occur. This speeds things up, but does
;;> not affect correctness.
(define create-temp-file
  (lambda prefix
    (let* ((tmpdir (cond-expand
                     (windows (get-environment-variable "TMP"))
                     (else "/tmp")))
           (real-prefix
             (if (null? prefix)
               (string-append tmpdir slash (number->string (c-getpid)))
               (car prefix)))
           (path (string-append real-prefix "-" (random-string 6))))
      (if (file-exists? path)
        (create-temp-file real-prefix)
        (begin
          (with-output-to-file path (lambda () (display "")))
          (set-file-mode path 600)
          path)))))

;;> This procedure can be used to perform certain atomic transactions on the
;;> file system involving filenames. Some examples:
;;>
;;>     Linking a file to a fresh backup temp name.
;;>     Creating and opening an unused, secure temp file.
;;>     Creating an unused temporary directory. 
;;>
;;> This procedure uses prefix to generate a series of trial filenames. Prefix
;;> is a string, and defaults to the value of invoking temp-file-prefix. File
;;> names are generated by concatenating prefix with a varying string.
;;>
;;> The maker procedure is called serially on each filename generated. It must
;;> return at least one value; it may return multiple values. If the first
;;> return value is #f or if maker signals an exception indicating that the
;;> file exists, call-with-temporary-filename will loop, generating a new
;;> filename and calling maker again. If the first return value is true, the
;;> loop is terminated, returning whatever value(s) maker returned.
;;>
;;> After a number of unsuccessful trials, call-with-temporary-filename may
;;> give up, in which case an exception is signaled or propagated.
;;>
;;> To rename a file to a temporary name:
;;>
;;>     (call-with-temporary-filename
;;>       (lambda (backup)
;;>         (create-hard-link old-file backup)
;;>         backup)
;;>       ".temp.") ; Keep link in current working directory
;;>     (delete-file old-file)
;;>
;;> Recall that this SRFI reports procedure failure by signaling an error.
;;> This is critical for this example — the programmer can assume that if the
;;> call-with-temporary-filename call returns, it returns successfully. So the
;;> following delete-file call can be reliably invoked, safe in the knowledge
;;> that the backup link has definitely been established.
;;>
;;> To create a unique temporary directory:
;;>
;;>     (call-with-temporary-filename
;;>       (lambda (dir)
;;>         (create-directory dir)
;;>         dir)
;;>       "/tmp/tempdir.")
;;>
;;> Similar operations can be used to generate unique fifos, or to return
;;> values other than the new filename (for example, an open port).
(define (call-with-temporary-filename maker . prefix)
  (let* ((tmpdir (cond-expand (windows (get-environment-variable "TMP"))
                              (else "/tmp")))
         (real-prefix (if (null? prefix)
                        (string-append tmpdir
                                       slash
                                       (number->string (c-getpid)))
                        (car prefix)))
         (path (string-append real-prefix "-" (random-string 6))))
    (apply maker (list path))))

;;> Returns the current file protection mask, or umask, as an exact integer.
;;> Whenever a file is created, the specified or default permissions are
;;> bitwise-anded with the complement of the umask before they are used.
(define (umask)
  (let ((mask (c-umask 0)))
    (c-umask mask)
    mask))

;;> Sets the file protection mask to the exact integer umask and returns an
;;> unspecified value.
(define (set-umask! umask)
  (c-umask umask))

;;> Returns the current directory as a string containing an absolute pathname.
;;> Whenever a file is referenced with a relative path, it is interpreted as
;;> relative to this directory.
(define (current-directory)
  (let* ((path-pointer (make-c-bytevector 1024))
         (path (begin
                 (c-getcwd path-pointer 1024)
                 (string-copy (c-bytevector->string path-pointer)))))
    (c-bytevector-free path-pointer)
    path))

;;> Sets the current directory to new-directory and returns an unspecified
;;> value.
(define (set-current-directory! path)
  (c-chdir (string->c-bytevector path)))

;;> Retrieves the process id for the current process.
(define (pid) (c-getpid))

;;> Increments the niceness of the current process by delta. The lower the
;;> niceness value is, the more the process is favored during scheduling.
;;> If delta is not specified, the increment is 1.

;;> Real-time processes are not affected by nice.
(define nice
  (lambda args
    (let ((result (if (null? args) (c-nice 1) (c-nice (car args)))))
      (when (< result 0)
        (let* ((error-message "nice error")
               (error-pointer (string->c-bytevector error-message)))
          (c-perror error-pointer)
          (c-bytevector-free timespec)
          (c-bytevector-free error-pointer)
          (error error-message)))
      result)))
(define (user-uid) (c-getuid))
(define (user-gid) (c-getgid))
(define (user-effective-uid) (c-geteuid))
(define (user-effective-gid) (c-getegid))

(define (groups-loop max-count count groups-pointer result)
  (if (>= count max-count)
    result
    (groups-loop max-count
                 (+ count 1)
                 groups-pointer
                 (append result
                         (list (c-bytevector-ref groups-pointer
                                                 'int
                                                 (* (c-type-size 'int) count)
                                                 ))))))

(define (user-supplementary-gids)
  (let* ((group-count (c-getgroups 0 (c-bytevector-null)))
         (groups (make-c-bytevector (* (c-type-size 'int) group-count))))
    (c-getgroups group-count groups)
    (groups-loop group-count 0 groups (list))))

(define-record-type <user-info>
  (make-user-info name uid gid home-dir shell full-name)
  user-info?
  (name internal-user-info:name)
  (uid internal-user-info:uid)
  (gid internal-user-info:gid)
  (home-dir internal-user-info:home-dir)
  (shell internal-user-info:shell)
  (full-name internal-user-info:full-name))

;;> Returns the user name stored in user-info respectively.
;;> An implementation returns #f for any unavailable items.
(define (user-info:name user-info) (internal-user-info:name user-info))
;;> Returns the user uid stored in user-info respectively.
;;> An implementation returns #f for any unavailable items.
(define (user-info:uid user-info) (internal-user-info:uid user-info))
;;> Returns the user gid stored in user-info respectively.
;;> An implementation returns #f for any unavailable items.
(define (user-info:gid user-info) (internal-user-info:gid user-info))
;;> Returns the user home directory stored in user-info respectively.
;;> An implementation returns #f for any unavailable items.
(define (user-info:home-dir user-info) (internal-user-info:home-dir user-info))
;;> Returns the shell path stored in user-info respectively.
;;> An implementation returns #f for any unavailable items.
(define (user-info:shell user-info) (internal-user-info:shell user-info))

;;> Returns the contents of the pw_gecos field stored in user-info. Although
;;> this field is not part of POSIX, it has been part of all Unix variants
;;> since at least the Sixth Edition of Research Unix. It normally contains
;;> the user's full name, but may contain additional system-specific
;;> information; on Windows, it contains exactly the full name.
(define (user-info:full-name user-info)
  (internal-user-info:full-name user-info))

;;> Returns a parsed and expanded version of the raw string returned by
;;> user-info:full-name. The raw value is split on commas, creating a list of
;;> strings to be returned. All ampersands in the first element of the list
;;> are replaced by user-info:name, which is capitalized if it starts with an
;;> ASCII lowercase letter.

;;> However, on Windows the implementation is completely different:
;;> user-info:parsed-full-name returns a list with a single element, the
;;> result of user-info:full-name. No comma splitting or ampersand
;;> substitution is performed.

;;> The meaning of the first element of the returned list is the user's full
;;> name on all known systems. The remaining elements have varying meaning.
;;> For example, on BSD systems, the second through fourth elements are the
;;> user's work location, the user's work phone number, and the user's home
;;> phone number, respectively. On Cygwin, the second element is the Windows
;;> SID corresponding to this user; further elements depend on Cygwin-specific
;;> entries in the /etc/nsswitch.conf file.
(define (user-info:parsed-full-name user-info)
  (let* ((parsed-list
           (string-split (internal-user-info:full-name user-info) #\,))
         (first
           (string-append
             (string (char-upcase (string-ref (car parsed-list) 0)))
             (string-copy (car parsed-list) 1))))
    (cons (string-char-replace first #\& (user-info:name user-info))
          (cdr parsed-list))))

;;> Return a user-info record giving the recorded information for a particular
;;> user. The uid/name argument is either an exact integer user id or a string
;;> user name. If uid/name does not identify an existing user, #f is returned;
;;> this does not constitute an error situation, and callers must be prepared
;;> to handle it.
(define (user-info uid/name)
  (let ((password-struct (if (number? uid/name)
                           (c-getpwuid uid/name)
                           (c-getpwnam (string->c-bytevector uid/name)))))
    (make-user-info (c-bytevector->string (c-bytevector-ref password-struct
                                                            'pointer
                                                            0))
                    (c-bytevector-ref password-struct
                                      'int
                                      (* (c-type-size 'pointer) 2))
                    (c-bytevector-ref password-struct
                                      'int
                                      (+ (* (c-type-size 'pointer) 2)
                                         (c-type-size 'int)))
                    (c-bytevector->string (c-bytevector-ref password-struct
                                                            'pointer
                                                            (+ (* (c-type-size 'pointer) 3)
                                                               (* (c-type-size 'int) 2))))
                    (c-bytevector->string (c-bytevector-ref password-struct
                                                            'pointer
                                                            (+ (* (c-type-size 'pointer) 4)
                                                               (* (c-type-size 'int) 2))))
                    (c-bytevector->string (c-bytevector-ref password-struct
                                                            'pointer
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
                        (c-getgrnam (string->c-bytevector gid/name)))))
    (make-group-info
      (c-bytevector->string (c-bytevector-ref group-struct 'pointer 0))
      (c-bytevector-ref group-struct
                        'int
                        (* (c-type-size 'pointer) 2)))))

;;> Change the value of the environment variable name to be value. Both name
;;> and value are strings. If name is not defined at the time of call, a new
;;> variable is added; if name is defined, its old value is discarded and
;;> replaced by value. If name or value are invalid according to the operating
;;> system, an exception is signaled. Mutating name or value after the call
;;> must not change the name or value of the environment variable.
(define (set-environment-variable! name value)
  (when (not (string? name))
    (error "set-environment-variable! error: name must be string"))
  (when (not (string? value))
    (error "set-environment-variable! error: value must be string"))
  (c-setenv (string->c-bytevector name) (string->c-bytevector value) 1))

;;> Remove the environment variable name such that a subsequent
;;> (get-environment-variable name) would return #f. If the variable cannot
;;> be removed, an exception is signaled. If name does not currently have a
;;> value, the call silently succeeds.
(define (delete-environment-variable! name)
  (when (not (string? name))
    (error "delete-environment-variable! error: Name must be string"))
  (c-unsetenv (string->c-bytevector name)))

(define CLOCK_REALTIME 0)
(define CLOCK_MONOTONIC 1)
(define tv_sec-type 'long)
(define tv_nsec-type 'long)
(define timespec (make-c-bytevector (c-type-size+ tv_sec-type tv_nsec-type)))

;;> Returns the current time as a time object of type time-utc, which
;;> represents the time since the POSIX epoch (midnight January 1, 1970
;;> Universal Time), excluding leap seconds. It uses the POSIX CLOCK_REALTIME
;;> clock.
(define (posix-time)
  (let* ((result (c-clock-gettime CLOCK_REALTIME timespec)))
    (cond
      ((< result 0)
       (let* ((error-message "posix-time error")
              (error-pointer (string->c-bytevector error-message)))
         (c-perror error-pointer)
         (c-bytevector-free timespec)
         (c-bytevector-free error-pointer)
         (error error-message)))
      (else
        (make-time time-utc
                   (c-bytevector-ref timespec
                                     tv_nsec-type
                                     (c-type-size tv_sec-type))
                   (c-bytevector-ref timespec tv_sec-type 0))))))

;;> Returns the current time as a time object of type time-monotonic, which
;;> represents the time since an arbitrary epoch. This epoch is arbitrary,
;;> but cannot change after the current program begins to run. It is
;;> guaranteed that a call to monotonic-time cannot return a time earlier
;;> than a previous call to monotonic-time. This is not guaranteed for
;;> posix-time because the system's POSIX clock is sometimes turned backward
;;> to correct local clock drift. It uses the POSIX CLOCK_MONOTONIC clock.
(define (monotonic-time)
  (let* ((result (c-clock-gettime CLOCK_MONOTONIC timespec)))
    (cond
      ((< result 0)
       (let* ((error-message "posix-time error")
              (error-pointer (string->c-bytevector error-message)))
         (c-perror error-pointer)
         (c-bytevector-free timespec)
         (c-bytevector-free error-pointer)
         (error error-message)))
      (else
        (make-time time-utc
                   (c-bytevector-ref timespec
                                     tv_nsec-type
                                     (c-type-size tv_sec-type))
                   (c-bytevector-ref timespec tv_sec-type 0))))))

