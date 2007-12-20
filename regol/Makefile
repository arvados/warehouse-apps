PREFIX?=/usr/local
INSTALLBIN?=$(PREFIX)/bin
INSTALLETC?=/etc
INSTALLWWW?=/var/www
A_SITES_AVAILABLE?=/etc/apache2/sites-available
A_SITES_ENABLED?=/etc/apache2/sites-enabled

all:
	perl -pe 's/{([A-Z_]+)}/$ENV{$1}/eg' < src/regol-www.conf.in > regol-www.conf
test:
install:
	install -g 0 -o 0 src/regol-service $(INSTALLBIN)/
	install -g 0 -o 0 regol-www.conf $(A_SITES_AVAILABLE)/
	install -g 0 -o 0 src/regol.conf.sample $(INSTALLETC)/
	cp -irp regol-www $(INSTALLWWW)/regol-www
enable-service: /etc/regol.conf
	./scripts/enable-service.sh
enable-www: /etc/regol.conf
	ln -s $(A_SITES_AVAILABLE)/regol-www.conf $(A_SITES_ENABLED)/
	apache2ctl graceful
	@echo >&2 "Check web interface at http://`hostname`/regol/"
/etc/regol.conf:
	@echo >&2 "***"
	@echo >&2 "*** You need to create $@ -- see $@.sample"
	@echo >&2 "***"
	@false
