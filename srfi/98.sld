(define-library
  (srfi 98)
  (import (except (scheme base)
                  get-environment-variable
                  get-environment-variables)
          (foreign c))
  (export get-environment-variable
          get-environment-variables
          )
  (include "98.scm"))
