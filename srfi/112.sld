(define-library
  (srfi 112)
  (import (scheme base)
          (retropikzel shell))
  (export implementation-name
          implementation-version
          cpu-architecture
          machine-name
          os-name
          os-version)
  (include "112.scm"))
