#!/bin/bash

set -e -x

# Write changelog
git log --pretty=format:"libwarehouse-perl (%ct.%h) hardy lucid maverick natty precise lenny squeeze wheezy; urgency=low%n  * %s%n    commit:%H%n -- %an <%ae>  %cD%n" . > debian/changelog

perl Makefile.PL INSTALLDIRS=vendor
dpkg-buildpackage -rfakeroot -uc -us
