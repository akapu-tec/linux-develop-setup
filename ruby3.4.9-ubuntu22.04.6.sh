#!/usr/bin/env bash

# Install Ruby 3.4.9 and PDF handling tools
# Ubuntu 22.04.6 LTS
# Author: Gedean Dias
# Date: 2026-03-14
# Based on Ruby Docker Image:
# https://github.com/docker-library/ruby/blob/8e49e25b591d4cfa6324b6dada4f16629a1e51ce/2.7/buster/Dockerfile
# Release List: https://www.ruby-lang.org/en/downloads/releases/

# Tips: best ubuntu version is 22.04.2

# Read common issues of specific libs at the end of this file

### WSL Setup
# wsl -l -v
# wsl --set-version <distribution name> <version number>
# e.g.
# wsl --set-version Ubuntu-20.04 2

## Do prefer reset wsl installation:
## wsl --list (see all installed versions)
## wsl --unregister Ubuntu-22.04

set -euxo pipefail

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

export LANG=C.UTF-8

run_as_root mkdir -p /usr/local/etc
run_as_root tee /usr/local/etc/gemrc >/dev/null <<'EOF'
install: --no-document
update: --no-document
EOF

RUBY_DOWNLOAD_URI='https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.9.tar.gz'
RUBY_DOWNLOAD_SHA256='7bb4d4f5e807cc27251d14d9d6086d182c5b25875191e44ab15b709cd7a7dd9c'

run_as_root apt-get update

run_as_root apt-get install -y --no-install-recommends \
  autoconf \
  bison \
  build-essential \
  ca-certificates \
  dpkg-dev \
  firebird-dev \
  graphviz \
  imagemagick \
  img2pdf \
  libcurl4 \
  libcurl4-openssl-dev \
  libedit-dev \
  libffi-dev \
  libgdbm-dev \
  libmysqlclient-dev \
  libpq-dev \
  libsqlite3-dev \
  libssl-dev \
  libyaml-dev \
  nodejs \
  p7zip-full \
  pdfgrep \
  pdftk \
  poppler-utils \
  qpdf \
  sqlite3 \
  wget \
  zlib1g-dev

wget -O ruby.tar.gz "${RUBY_DOWNLOAD_URI}"
echo "${RUBY_DOWNLOAD_SHA256} *ruby.tar.gz" | sha256sum --check --strict

build_dir="$(mktemp -d)"
tar -xf ruby.tar.gz -C "${build_dir}" --strip-components=1
rm ruby.tar.gz

cd "${build_dir}"

# Disable the world-writable PATH warning inherited from the official Docker image.
{
  echo '#define ENABLE_PATH_CHECK 0'
  echo
  cat file.c
} > file.c.new
mv file.c.new file.c

autoconf
gnu_arch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
./configure --build="${gnu_arch}" --disable-install-doc --enable-shared
make -j"$(nproc)"
run_as_root make install

cd /
rm -rf "${build_dir}"

# Verify the source-built Ruby takes precedence on PATH.
[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]

# Rough smoke test.
ruby --version
gem --version
bundle --version

run_as_root tee /etc/profile.d/ruby-dev-env.sh >/dev/null <<'EOF'
export GEM_HOME="$HOME/.gem"
export BUNDLE_APP_CONFIG="$HOME/.bundle"

case ":$PATH:" in
  *":$GEM_HOME/bin:"*) ;;
  *) export PATH="$GEM_HOME/bin:$PATH" ;;
esac
EOF
run_as_root chmod 0644 /etc/profile.d/ruby-dev-env.sh

run_as_root gem update --system --no-document

echo "Ruby/Bundler environment configured in /etc/profile.d/ruby-dev-env.sh"
