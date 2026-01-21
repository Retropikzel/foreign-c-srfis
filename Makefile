.SILENT: build install clean test-r6rs test-r6rs-docker test-r7rs \
	test-r7rs-docker
.PHONY: test-r6rs test-r7rs
SCHEME=chibi
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
