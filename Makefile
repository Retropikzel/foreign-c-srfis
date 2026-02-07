.SILENT: build install clean test-r6rs test-r6rs-docker test-r7rs \
	test-r7rs-docker
.PHONY: test-r6rs test-r7rs
SCHEME=chibi
RNRS=r7rs
SRFI=170
AUTHOR=Retropikzel

SRFI_FILE=srfi/${SRFI}.sld
VERSION=$(shell cat srfi/${SRFI}/VERSION)
DESCRIPTION=$(shell head -n1 srfi/${SRFI}/README.md)
README=srfi/${SRFI}/README.html
TESTFILE=srfi/${SRFI}/test.scm
TMPDIR=.tmp/${SCHEME}

PKG=srfi-${SRFI}-${VERSION}.tgz

DOCKERIMG=${SCHEME}:head
ifeq "${SCHEME}" "chicken"
DOCKERIMG="chicken:5"
endif

all: build

build: srfi/${SRFI}/LICENSE srfi/${SRFI}/VERSION
	echo "<pre>$$(cat srfi/${SRFI}/README.md)</pre>" > ${README}
	snow-chibi package --version=${VERSION} --authors=${AUTHOR} --doc=${README} --description="${DESCRIPTION}" ${SRFI_FILE}

install:
	snow-chibi install --impls=${SCHEME} ${SNOW_CHIBI_ARGS} ${PKG}

uninstall:
	-snow-chibi remove --impls=${SCHEME} ${PKG}

init-venv: build
	@rm -rf venv
	@scheme-venv ${SCHEME} ${RNRS} venv
	@echo "(import (scheme base) (scheme write) (scheme read) (scheme char) (scheme file) (scheme process-context) (srfi 64) (srfi ${SRFI}))" > venv/test.scm
	@printf "#!r6rs\n(import (rnrs) (srfi :64) (srfi :${SRFI}))" > venv/test.sps
	@cat ${TESTFILE} >> venv/test.scm
	@cat ${TESTFILE} >> venv/test.sps
	@if [ "${RNRS}" = "r6rs" ]; then if [ -d ../foreign-c ]; then cp -r ../foreign-c/foreign venv/lib/; fi; fi
	@if [ "${RNRS}" = "r6rs" ]; then cp -r retropikzel venv/lib/; fi
	@if [ "${SCHEME}" = "chezs" ]; then ./venv/bin/akku install akku-r7rs chez-srfi; fi
	@if [ "${SCHEME}" = "ikarus" ]; then ./venv/bin/akku install akku-r7rs chez-srfi; fi
	@if [ "${SCHEME}" = "ironscheme" ]; then ./venv/bin/akku install akku-r7rs chez-srfi; fi
	@if [ "${SCHEME}" = "racket" ]; then ./venv/bin/akku install akku-r7rs chez-srfi; fi
	@if [ "${RNRS}" = "r6rs" ]; then ./venv/bin/akku install; fi
	@if [ "${SCHEME}" = "chicken" ]; then ./venv/bin/snow-chibi install --always-yes srfi.64; fi
	@if [ "${SCHEME}-${RNRS}" = "mosh-r7rs" ]; then ./venv/bin/snow-chibi install --always-yes srfi.64; fi
	@if [ "${RNRS}" = "r7rs" ]; then ./venv/bin/snow-chibi install ${PKG}; fi

run-test: init-venv
	if [ "${RNRS}" = "r6rs" ]; then ./venv/bin/scheme-compile venv/test.sps; fi
	if [ "${RNRS}" = "r7rs" ]; then VENV_CSC_ARGS="-L -lcurl" ./venv/bin/scheme-compile venv/test.scm; fi
	./venv/test

test-r7rs: tmpdir
	@if [ "${SCHEME}" = "chibi" ]; then rm -rf ${TMPDIR}/srfi/98.*; fi
	cd ${TMPDIR} && echo "(import (scheme base) (scheme write) (scheme file) (scheme process-context) (foreign c) (srfi ${SRFI}) (srfi 64))" > test-r7rs.scm
	cd ${TMPDIR} && cat srfi/${SRFI}/test.scm >> test-r7rs.scm
	cd ${TMPDIR} && COMPILE_R7RS=${SCHEME} compile-scheme -I . -o test-r7rs test-r7rs.scm
	cd ${TMPDIR} && printf "\n" | timeout 60 ./test-r7rs

test-r7rs-docker:
	docker build --build-arg IMAGE=${DOCKERIMG} --build-arg SCHEME=${SCHEME} --tag=foreign-c-srfi-test-${SCHEME} -f Dockerfile.test .
	docker run -t foreign-c-srfi-test-${SCHEME} sh -c "make SCHEME=${SCHEME} SRFI=${SRFI} SNOW_CHIBI_ARGS=--always-yes build install test-r7rs"

test-r6rs: tmpdir
	cd ${TMPDIR} && echo "(import (rnrs) (foreign c) (srfi :${SRFI}) (srfi :64))" > test-r6rs.sps
	cd ${TMPDIR} && cat srfi/${SRFI}/test.scm >> test-r6rs.sps
	cd ${TMPDIR} && akku install chez-srfi akku-r7rs "(foreign c)"
	cd ${TMPDIR} && COMPILE_R7RS=${SCHEME} compile-scheme -I .akku/lib -o test-r6rs test-r6rs.sps
	cd ${TMPDIR} && timeout 60 ./test-r6rs

test-r6rs-docker:
	docker build --build-arg IMAGE=${DOCKERIMG} --build-arg SCHEME=${SCHEME} --tag=foreign-c-srfi-test-${SCHEME} -f Dockerfile.test .
	docker run -t foreign-c-srfi-test-${SCHEME} sh -c "make SCHEME=${SCHEME} SRFI=${SRFI} test-r6rs"

tmpdir:
	rm -rf ${TMPDIR}
	mkdir -p ${TMPDIR}
	cp -r srfi ${TMPDIR}/
