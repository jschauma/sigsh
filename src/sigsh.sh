#! /bin/sh
#
# Copyright (c) 2010,2011 Yahoo! Inc.
# All rights reserved.
#
# Originally written by Jan Schaumann <jschauma@yahoo-inc.com> in October
# 2010.
#
# sigsh is a non-interactive, signature requiring and verifying command
# interpreter. More accurately, it is a signature verification wrapper
# around a given shell. It reads input in PKCS#7 format from standard in,
# verifies the signature and, if the signature matches, pipes the decoded
# input into the command interpreter.
#
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the following
# conditions are met:
#
# * Redistributions of source code must retain the above
#   copyright notice, this list of conditions and the
#   following disclaimer.
#
# * Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the
#   following disclaimer in the documentation and/or other
#   materials provided with the distribution.
#
# * Neither the name of Yahoo! Inc. nor the names of its
#   contributors may be used to endorse or promote products
#   derived from this software without specific prior
#   written permission of Yahoo! Inc.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Yes, the author is aware that we have more lines of comments than actual
# code, since the latter can be condensed into a single command like
#
# openssl smime -verify -inform pem -CAfile mycert.pem

PATH="/bin:/usr/bin:/sbin/:/usr/sbin"

###
### Globals
###
CERTS="/etc/sigsh.pem"
PROGRAM="bash"
SSL_VERIFY="openssl smime -verify -inform pem -CAfile"
PROGNAME="${0##*/}"
XTRACE=0

###
### Functions
###

# function : error
# purpose  : print given message to STDERR and exit unsuccessfully
# inputs   : msg

error() {
	local msg="$@"

	echo "${PROGNAME}: $msg" >&2
	exit 1
}

# function : usage
# purpose  : print usage statement

usage() {
	cat <<EOH
Usage: ${PROGNAME} [-x] [-c certs] [-p program]
         -c certs    Read certs to trust from this file.
         -p program  Pipe commands into 'program'.
         -x          Enabled debugging.
EOH
}

# function : verifyArg
# purpose  : ensure given arg is sane for shell evaluation by matching it
#            against a simple restrictive RE
# inputs   : a string
# returns  : the given string if it matches, errors out otherwise

verifyArg() {
	local arg="${1}"

	if expr "${arg}" : "[a-zA-Z0-9/_.-]*$" >/dev/null 2>&1 ; then
		echo "${arg}"
	else
		error "Argument must match ^[a-zA-Z0-9/_.-]*$."
		# NOTREACHED
	fi
}

# function : xtrace
# purpose  : print given message prepended with "+ " if xtrace is set
# inputs   : a string

xtrace() {
	local msg="$1"

	if [ ${XTRACE} -gt 0 ]; then
		echo "+ ${msg}" >&2
	fi
}

###
### Main
###

while getopts 'c:p:x' opt; do
	case ${opt} in
		c)
			CERTS=$(verifyArg ${OPTARG})
		;;
		p)
			PROGRAM=$(verifyArg ${OPTARG})
		;;
		x)
			XTRACE=1
		;;
		*)
			usage
			exit 1
			# NOTREACHED
		;;
	esac
done
shift $(($OPTIND - 1))

if [ $# -gt 0 ]; then
	usage
	exit 1
	# NOTREACHED
fi

verify="${SSL_VERIFY} ${CERTS}"
xtrace "${verify}"

if [ ${XTRACE} -eq 0 ]; then
	verify="${verify} 2>/dev/null"
fi

# We could just do something like
#
# eval ${verify} | while read -r line; do
#
# but that would return 0 even if the verification failed.  If we want to
# return the special exit code on verification failure, we need to keep
# the whole output in memory, but that seems reasonable compared to the
# unreadable shenanigans we'd otherwise have to play with shell redirection
# etc.  Ditching the special exit code is the other option, but I think
# it'd be useful to be able to discern verification failure based on $?.

output=$(eval ${verify})
if [ $? -gt 0 ]; then
	echo "Unable to verify given input." >&2
	exit 127
fi

IFS='
'
for line in ${output}; do
	xtrace "${line}"
	echo "${line}" | tr -d '\r'
done | ${PROGRAM}
