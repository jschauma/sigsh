# A Makefile to create html docs from the man pages.

PRODUCT=sigsh

MANPAGES=./${PRODUCT}.1

all: html

html: ${MANPAGES}
.for m in ${MANPAGES}
	nroff -man ${m} | rman -f html > ${m:S/.\///}.html
.endfor

clean:
.for m in ${MANPAGES}
	@rm -f ${m:S/.\///}.html
.endfor
