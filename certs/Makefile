CERTS?=sigsh.pem
EXPIRE?=365
KEY?=mykey.pem
CERT?=mycert.pem
DATE!=date +%Y-%m-%d
SDATE!=date +%s
EXPSECONDS!=echo '( ${EXPIRE} * 24 * 60 * 60 ) + ${SDATE}' | bc
EXPDATE!=date -j -f %s ${EXPSECONDS}

all: newcert

newcert:
	@openssl req -x509 -nodes -days ${EXPIRE} -newkey rsa:2048	\
		-batch -keyout key.tmp -out cert.tmp >/dev/null 2>&1
.for f in key cert
	@echo '#' > .$f
	@echo '# Generated on ${DATE} by ${USER}.' >> .$f
	@echo '# This key/cert will expire on ${EXPDATE}.' >> .$f
	@cat ${f}.tmp >> .$f
	@rm ${f}.tmp
.endfor
	@mv .key ${KEY}
	@mv .cert ${CERT}
	@echo "Your new key and cert have been generated."
	@echo "Please make sure to protect your private key with the necessary due diligence."
	@echo "If you're sure that that is the right thing to do, then you may add your public"
	@echo "cert to '${CERTS}' and commit that file."

help:
	@echo "The following targets are available:"
	@echo "all        synonym for 'newcert'"
	@echo "clean      remove any temporary files"
	@echo "newcert    generate a new certificate"

clean:
	@rm -f ${KEY} ${CERT}
