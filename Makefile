.POSIX:
.DEFAULT: all
SCHEME=chibi
SRFI=170
PKG=srfi-${SRFI}-${VERSION}.tgz
VERSION=$$(cat srfi/${SRFI}/VERSION)
TESTFILE=srfi/${SRFI}/test.scm
DOCFILE=srfi/${SRFI}/index.html

all: package

package: srfi/${SRFI}/LICENSE srfi/${SRFI}/VERSION
	cp srfi/${SRFI}/test.scm test.scm
	snow-chibi package \
		--license="$$(cat srfi/${SRFI}/LICENSE)" \
		--version="${VERSION}" \
		--authors="$$(cat srfi/${SRFI}/AUTHORS 2>/dev/null || echo 'Retropikzel')" \
		--doc=${DOCFILE} \
		--test=${TESTFILE} \
		--description="$$(cat srfi/${SRFI}/DESCRIPTION)" \
		srfi/${SRFI}.sld

git-index: package
	snow-chibi git-index ${PKG}

install:
	snow-chibi install --impls=${SCHEME} --skip-tests?=1 ${PKG}

test:
	cp srfi/${SRFI}/test.scm test.scm
	COMPILE_R7RS=${SCHEME} compile-r7rs -o test-program test.scm
	./test-program

test-docker: testfiles
	DOCKER_TAG=${DOCKER_TAG} \
	SNOW_PACKAGES="srfi.64 ${PKG}" \
	AKKU_PACKAGES=${AKKU_PACKAGES} \
	APT_PACKAGES="libcurl4-openssl-dev" \
	COMPILE_R7RS=${SCHEME} \
	TEST_R7RS_DEBUG=1 \
	CSC_OPIONS="-L -lcurl" \
		test-r7rs -o test-program test.scm

update-info:
	curl -L -o srfi/${SRFI}/index.html https://srfi.schemers.org/srfi-${SRFI}/srfi-${SRFI}.html
	printf "(foreign c) $$(cat srfi/${SRFI}/index.html | grep '<title>' | sed 's/<title>//' | sed 's/<\/title>//' | sed 's/^[ \t]*//' | tr -d '\n')" > srfi/${SRFI}/DESCRIPTION

clean:
	git clean -X -f
