#!/bin/bash

source "${BASEDIR}/scripts/platform.inc"
source "${BASEDIR}/scripts/lib_versions.inc"
source "${BASEDIR}/scripts/util.inc"

THIS="libiodbc"
ARCHIVE_DESTINATION="${THIS}-${libiodbc_VERSION}"
URL_ROOT="https://github.com/openlink/iODBC/releases/download/v${libiodbc_VERSION}/${THIS}-${libiodbc_VERSION}.tar.gz"
FILE_DIRECTORY="../../thirdparty/${THIS}/src"

function copyLibrary {
    mkdir -p "${FILE_DIRECTORY}"
	pushd "${BUILDDIR}/${ARCHIVE_DESTINATION}"
	./configure
	popd
	echo "copying config files from ${BUILDDIR}/${ARCHIVE_DESTINATION} to ${FILE_DIRECTORY}"
	cp ${BUILDDIR}/${ARCHIVE_DESTINATION}/config.h ${FILE_DIRECTORY}/ 2>/dev/null || true
	cp ${BUILDDIR}/${ARCHIVE_DESTINATION}/libtool ${FILE_DIRECTORY}/ 2>/dev/null || true
	cp ${BUILDDIR}/${ARCHIVE_DESTINATION}/config.status ${FILE_DIRECTORY}/ 2>/dev/null || true
}

fetchBinary
untarBinary
copyLibrary
