#!/bin/bash
set -ex
cd $(dirname $0) || exit 1

# configure apt mirror
echo "$http_proxy $no_proxy" && set -x && [ -z "$MIRROR_DEBIAN" ] || \
     sed -i.orig -e "s|http://deb.debian.org\([^[:space:]]*\)|$MIRROR_DEBIAN/debian9|g ; s|http://security.debian.org\([^[:space:]]*\)|$MIRROR_DEBIAN/debian9-security|g" /etc/apt/sources.list

buildDeps="sudo make gcc g++ libc-dev ruby-dev build-essential git zlib1g-dev liblzma-dev" ; \
runDeps="net-tools"

apt-get update -qq && \
  apt-get install -qy --no-install-recommends $buildDeps $runDeps

# configure gem mirror
    echo 'gem: --no-document' >> /etc/gemrc ; \
    echo ':ssl_verify_mode: 0' >> /etc/gemrc ; \
    [ -z "$http_proxy" ] || export gem_proxy=" -p $http_proxy " ; \
    [ -z "$http_proxy" ] || export gem_args=" $gem_args -r $gem_proxy " ; \
    [ -z "$RUBY_URL" ] || sudo -E gem source -r https://rubygems.org/ ; \
    [ -z "$RUBY_URL" ] || sudo -E gem source -a $RUBY_URL ; \
    [ -z "$RUBY_URL" ] || sudo -E gem source -c ; \
    sudo -E gem sources ; \
    sudo -E gem install --no-rdoc --no-ri $gem_args bundler ; \
    [  -z "$RUBY_URL" ] || bundle config mirror.https://rubygems.org $RUBY_URL
    [  -z "$RUBY_URL" ] || bundle config ssl_verify_mode 0
# install gem package
#    sudo -E gem install  --file /Gemfile --no-rdoc --no-ri $gem_args
    bundler install --gemfile /Gemfile --retry=5

# install/build fluent gem swift plugin
    (
      echo "### TODO remplacer par l install gem depuis rubygems"
      git clone https://github.com/pli01/fluent-plugin-swift swift && \
      cd swift && \
      bundler install --gemfile Gemfile --retry=5 && \
      bundle exec rake test && \
      bundle exec rake build && \
      sudo -E gem install -V --no-rdoc --no-ri $gem_proxy pkg/fluent-plugin-swift-$(cat VERSION).gem
    ) || exit $?

# clean all
sudo -E gem sources --clear-all \
 && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
           /home/fluent/.gem/ruby/2.3.0/cache/*.gem
