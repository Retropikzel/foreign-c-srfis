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

SFX=scm
ifeq "${RNRS}" "r6rs"
SFX=sps
endif

DOCKER_TAG=head
ifeq "${SCHEME}" "chicken"
DOCKER_TAG=5
endif

all: package

package: srfi/${SRFI}/LICENSE srfi/${SRFI}/VERSION
	echo "<pre>$$(cat srfi/${SRFI}/README.md)</pre>" > ${README}
	snow-chibi package \
		--version=${VERSION} \
		--authors=${AUTHOR} \
		--doc=${README} \
		--description="${DESCRIPTION}" \
		${SRFI_FILE}

install:
	snow-chibi install --impls=${SCHEME} ${PKG}

uninstall:
	-snow-chibi remove --impls=${SCHEME} ${PKG}

testfiles:
	rm -rf .tmp
	mkdir -p .tmp
	cp ${PKG} .tmp
	cp -r srfi .tmp/
	cat test-headers.${SFX} ${TESTFILE} | sed 's/SRFI/${SRFI}/' > .tmp/test.${SFX}
	cat ${TESTFILE} >> run-test.${SFX}
	if [ "${RNRS}" = "r6rs" ]; then if [ -d ../foreign-c ]; then cp -r ../foreign-c/foreign .tmp/; fi; fi

test: testfiles package
	cd .tmp && COMPILE_R7RS=${SCHEME} compile-r7rs -o test-program test.${SFX}
	cd .tmp && ./test-program

test-docker: testfiles package
	cd .tmp && \
		DOCKER_TAG=${DOCKER_TAG} \
		SNOW_PACKAGES="srfi.64 srfi.60 srfi.145 srfi.180 retropikzel.mouth foreign.c ${PKG}" \
		APT_PACKAGES="libcurl4-openssl-dev" \
		COMPILE_R7RS=${SCHEME} \
		TEST_R7RS_DEBUG=1 \
		CSC_OPIONS="-L -lcurl" \
		test-r7rs -o test-program test.${SFX}
