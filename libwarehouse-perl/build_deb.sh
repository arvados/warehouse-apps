#!/bin/bash

set -e -x

# Write changelog
git log --pretty="libwarehouse-perl (%ct.%h) hardy lucid maverick natty lenny squeeze; urgency=low%n  * %s%n    commit:%H%n -- %an <%ae>  %cD%n" --diff-filter='[A|C|D|M|R|T]' . > debian/changelog

perl Makefile.PL INSTALLDIRS=vendor
dpkg-buildpackage -rfakeroot -uc -us
