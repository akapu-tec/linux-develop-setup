# Install Ruby 3.2.2, Redis AND PDF Handling
# Ubuntu 22.04.2 LTS
# Author: Gedean Dias
# Date: 2023-08-26
# Based on Ruby Docker Image: https://github.com/docker-library/ruby/blob/8e49e25b591d4cfa6324b6dada4f16629a1e51ce/2.7/buster/Dockerfile
# Release List: https://www.ruby-lang.org/en/downloads/releases/

# Tips: best ubuntu version is 22.04.2

# Release Notes:
	# Installs Redis Stack Server 7.2

# Read commom issues of specific libs at the end of this file

### WSL Setup
# wsl -l -v
# wsl --set-version <distriubtion name> <version number>
# e.g.
# wsl --set-version Ubuntu-20.04 2

## Do prefer reset wsl installation: wsl --unregister Ubuntu-22.04

### Ubuntu
sudo apt update

set -eux; 
	mkdir -p /usr/local/etc; 
	{ 
		echo 'install: --no-document'; 
		echo 'update: --no-document'; 
	} >> /usr/local/etc/gemrc

LANG=C.UTF-8

RUBY_DOWNLOAD_URI='https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0.tar.gz'
RUBY_DOWNLOAD_SHA256=96518814d9832bece92a85415a819d4893b307db5921ae1f0f751a9a89a56b7d

set -eux; 
	
	savedAptMark="$(apt-mark showmanual)"; 

	apt-get install -y --no-install-recommends bison;
	apt-get install -y --no-install-recommends dpkg-dev;
	apt-get install -y --no-install-recommends libgdbm-dev;
	apt-get install -y --no-install-recommends ruby; 
	# due to newest ruby version no longer bundle 3rd party sources like libyaml, libffi.
	apt-get install -y --no-install-recommends libyaml-dev;

	# readline-ext requirements	
	apt-get install -y --no-install-recommends libedit-dev;
	# rever essa versão 14 no final.
	apt-get install -y --no-install-recommends libcurl4 libcurl4-openssl-dev;
	

  # added by Gedean Dias 
	apt-get install -y --no-install-recommends libpq-dev; 
	apt-get install -y --no-install-recommends autoconf; 
	apt-get install -y --no-install-recommends build-essential;
	apt-get install -y --no-install-recommends zlib1g-dev; 
	apt-get install -y --no-install-recommends libssl-dev;
	apt-get install -y --no-install-recommends gcc;
	apt-get install -y --no-install-recommends libc6-dev;
	apt-get install -y --no-install-recommends libz-dev;
	apt-get install -y --no-install-recommends libffi-dev;
	apt-get install -y --no-install-recommends sqlite3;

	apt-get install -y --no-install-recommends p7zip-full;

	# Firebird requirements
	apt-get install -y --no-install-recommends firebird-dev;

	# PDF Handing
	apt-get install -y --no-install-recommends pdfgrep;
	apt-get install -y --no-install-recommends pdftk;
	apt-get install -y --no-install-recommends qpdf;
	# pdftotext
	apt-get install -y --no-install-recommends poppler-utils;
	
	# Image to PDF
	# https://techpiezo.com/linux/convert-png-jpeg-to-pdf-in-ubuntu/
	# use: img2pdf *.png -o outcome.pdf
	apt-get install -y --no-install-recommends img2pdf;
	
	apt-get install -y --no-install-recommends imagemagick;

	# for PlantUml Viewers
	apt-get install -y --no-install-recommends graphviz;
	
	# rails app specific	
	apt-get install -y --no-install-recommends libmysqlclient-dev libsqlite3-dev;


	# NodeJS as a js runtime, for the sake of mini_racer gets bigger bundler
		#curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -;
	apt-get install -y --no-install-recommends nodejs;

	### Redis Stack Server 7.2
	# https://redis.io/docs/getting-started/install-stack/linux/
	
	curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
	sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
	sudo apt-get update
	sudo apt-get install redis-stack-server	
	
	wget -O ruby.tar.gz ${RUBY_DOWNLOAD_URI};
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum --check --strict;
	
	mkdir -p /usr/src/ruby; 
	tar -xf ruby.tar.gz -C /usr/src/ruby --strip-components=1;
	rm ruby.tar.gz; 
	
	cd /usr/src/ruby; 
	
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ 
		echo '#define ENABLE_PATH_CHECK 0'; 
		echo; 
		cat file.c; 
	} > file.c.new; 
	mv file.c.new file.c; 
	
	autoconf; 
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; 
	./configure --build="$gnuArch" --disable-install-doc --enable-shared; 
	make -j "$(nproc)"; 
	make install; 
	
	apt-mark auto '.*' > /dev/null; 
	apt-mark manual $savedAptMark > /dev/null; 
	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual; 
	# Removed by Gedean Dias
	# apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; 
	
	cd /; 
	rm -r /usr/src/ruby; 
# verify we have no "ruby" packages installed
	! dpkg -l | grep -i ruby; 
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; 
# rough smoke test
	ruby --version; 
	gem --version; 
	bundle --version  

# don't create ".bundle" in all our apps
GEM_HOME=/usr/local/bundle
BUNDLE_SILENCE_ROOT_WARNING=1
BUNDLE_APP_CONFIG=$GEM_HOME
PATH=$GEM_HOME/bin:$PATH

### added by Gedean Dias
	# Clean up garbage
	# sudo apt-get autoremove -y

# adjust permissions of a few directories for running "gem install" as an arbitrary user
	# RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"  

gem up --system --no-doc
