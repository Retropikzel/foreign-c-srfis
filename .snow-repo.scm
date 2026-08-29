(repository
  (package
    (git
      (hash "02c5fa06cab2ea15fe25fbd6433a8a549ee5d18f")
      (url "https://codeberg.org/retropikzel/foreign-c-srfis.git"))
    (authors "Retropikzel")
    (version "0.2.5")
    (license LGPL-3.0-or-later)
    (library
      (name
        (srfi 170))
      (path "srfi/170.sld")
      (foreign-depends)
      (depends
        (scheme base)
        (scheme char)
        (scheme write)
        (scheme file)
        (scheme process-context)
        (foreign c)
        (srfi 19)))
    (manual "srfi/170/index.html")
    (description "(foreign c) SRFI 170: POSIX API")
    (test "srfi/170/test.scm")
    (test-depends
      (scheme base)
      (scheme write)
      (scheme read)
      (scheme char)
      (scheme file)
      (scheme process-context)
      (retropikzel tap)
      (foreign c)
      (srfi 64)
      (srfi 170))
    (updated "2026-08-29T15:04:01+00:00")))
