DRAFT:=rpl-comi
VERSION:=$(shell ./getver ${DRAFT}.mkd )
YANGDATE=2018-05-13
CWTDATE1=yang/ietf-roll-rpl-statistics@${YANGDATE}.yang
CWTSIDDATE1=ietf-roll-rpl-statistics@${YANGDATE}.sid
CWTSIDLIST1=ietf-roll-rpl-statistics-sid.txt
PYANG=./pyang.sh

# git clone this from https://github.com/mbj4668/pyang.git
# then, cd pyang/plugins;
#       wget https://raw.githubusercontent.com/core-wg/yang-cbor/master/sid.py
# sorry.
PYANGDIR=/sandel/src/pyang

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt

${CWTDATE1}: ietf-roll-rpl-statistics.yang
	mkdir -p yang
	sed -e"s/YYYY-MM-DD/${YANGDATE}/" ietf-roll-rpl-statistics.yang > ${CWTDATE1}

rpl-comi-tree.txt: ${CWTDATE1}
	${PYANG} -f tree --tree-print-groupings --tree-line-length=70 ${CWTDATE1} > rpl-comi-tree.txt

%.xml: %.mkd ${CWTDATE1} rpl-comi-tree.txt ${CWTSIDLIST1}
	kramdown-rfc2629 ${DRAFT}.mkd | ./insert-figures >${DRAFT}.xml
	: git add ${DRAFT}.xml

%.txt: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc $? $@

%.html: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $@ $?

submit: ${DRAFT}.xml
	curl -S -F "user=mcr+ietf@sandelman.ca" -F "xml=@${DRAFT}.xml" https://datatracker.ietf.org/api/submit

${CWTSIDLIST1} ${CWTSIDDATE1}: ${CWTDATE1}
	mkdir -p yang
	${PYANG} --list-sid --update-sid-file ${CWTSIDDATE1} ${CWTDATE1} | ./truncate-sid-table >rpl-comi-sid.txt

boot-sid1:
	${PYANG} --list-sid --generate-sid-file 1001100:50 ${CWTDATE1}

version:
	echo Version: ${VERSION}

clean:
	-rm -f ${DRAFT}.xml ${CWTDATE1}

.PRECIOUS: ${DRAFT}.xml
