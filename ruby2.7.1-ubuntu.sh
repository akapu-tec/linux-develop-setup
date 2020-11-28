# Author: Gedean Dias
# Date: 11-2020
# Based on Ruby Docker Image:
# https://github.com/docker-library/ruby/blob/8e49e25b591d4cfa6324b6dada4f16629a1e51ce/2.7/buster/Dockerfile

set -eux; 
	mkdir -p /usr/local/etc; 
	{ 
		echo 'install: --no-document'; 
		echo 'update: --no-document'; 
	} >> /usr/local/etc/gemrc

LANG=C.UTF-8
RUBY_MAJOR=2.7
RUBY_VERSION=2.7.2
RUBY_DOWNLOAD_SHA256=6e5706d0d4ee4e1e2f883db9d768586b4d06567debea353c796ec45e8321c3d4

set -eux; 
	
	savedAptMark="$(apt-mark showmanual)"; 
	apt-get update; 
	apt-get install -y --no-install-recommends bison;
	apt-get install -y --no-install-recommends dpkg-dev;
	apt-get install -y --no-install-recommends libgdbm-dev;
	apt-get install -y --no-install-recommends ruby; 

  # added by Gedean Dias 
	apt-get install -y --no-install-recommends autoconf; 
	apt-get install -y --no-install-recommends build-essential;
	apt-get install -y --no-install-recommends zlib1g-dev; 
	apt-get install -y --no-install-recommends libssl-dev;
	apt-get install -y --no-install-recommends gcc;
	apt-get install -y --no-install-recommends libc6-dev;
	apt-get install -y --no-install-recommends libz-dev;
	
	# rails app specific	
	apt-get install -y --no-install-recommends libmysqlclient-dev;

	# NodeJS
	# apt-get install -y --no-install-recommends nodejs;
	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -;
	apt-get install -y nodejs;
	
	# Install Yarn
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -;
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list;
	sudo apt update && sudo apt install yarn;

	
  # Disabled by Gedean Dias
	# rm -rf /var/lib/apt/lists/*; 
	
	wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz"; 
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; 
	
	mkdir -p /usr/src/ruby; 
	tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; 
	rm ruby.tar.xz; 
	
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

# added by Gedean Dias
sudo apt-get autoremove

# adjust permissions of a few directories for running "gem install" as an arbitrary user
# RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"  