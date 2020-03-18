#!/usr/bin/env bash
# set -eu

dep_version() {
    grep $1 .requirements | sed -e 's/.*=//' | tr -d '\n'
}

OPENRESTY=$(dep_version RESTY_VERSION)
LUAROCKS=$(dep_version RESTY_LUAROCKS_VERSION)
OPENSSL=$(dep_version RESTY_OPENSSL_VERSION)

#---------
# Download
#---------

DEPS_HASH=$(cat .ci/setup_env.sh .travis.yml .requirements | md5sum | awk '{ print $1 }')
DOWNLOAD_ROOT=${DOWNLOAD_ROOT:=/download-root}
BUILD_TOOLS_DOWNLOAD=$DOWNLOAD_ROOT/openresty-build-tools

# These are CI tests, so always use latest unless said otherwise
KONG_NGINX_MODULE_BRANCH=${KONG_NGINX_MODULE_BRANCH:-master}
KONG_BUILD_TOOLS_BRANCH=${KONG_BUILD_TOOLS_BRANCH:-master}

if [[ $KONG_BUILD_TOOLS_BRANCH == "master" ]]; then
  KONG_BUILD_TOOLS_BRANCH="origin/master"
fi

if [ ! -d $BUILD_TOOLS_DOWNLOAD ]; then
    git clone https://github.com/Kong/kong-build-tools.git $BUILD_TOOLS_DOWNLOAD
fi

pushd $BUILD_TOOLS_DOWNLOAD
    git fetch --all
    git reset --hard $KONG_BUILD_TOOLS_BRANCH || git reset --hard origin/$KONG_BUILD_TOOLS_BRANCH
popd

export PATH=$BUILD_TOOLS_DOWNLOAD/openresty-build-tools:$PATH

#--------
# Install
#--------
INSTALL_CACHE=${INSTALL_CACHE:=/install-cache}
INSTALL_ROOT=$INSTALL_CACHE/$DEPS_HASH

#    XXX no longer supported, for next release, use kong-build-tools
#    --openresty-patches $OPENRESTY_PATCHES_BRANCH \
kong-ngx-build \
    --work $DOWNLOAD_ROOT \
    --prefix $INSTALL_ROOT \
    --openresty $OPENRESTY \
    --kong-nginx-module $KONG_NGINX_MODULE_BRANCH \
    --luarocks $LUAROCKS \
    --openssl $OPENSSL \
    -j $JOBS

OPENSSL_INSTALL=$INSTALL_ROOT/openssl
OPENRESTY_INSTALL=$INSTALL_ROOT/openresty
LUAROCKS_INSTALL=$INSTALL_ROOT/luarocks

export OPENSSL_DIR=$OPENSSL_INSTALL # for LuaSec install

export PATH=$OPENSSL_INSTALL/bin:$OPENRESTY_INSTALL/nginx/sbin:$OPENRESTY_INSTALL/bin:$LUAROCKS_INSTALL/bin:$PATH
export LD_LIBRARY_PATH=$OPENSSL_INSTALL/lib:$LD_LIBRARY_PATH # for openssl's CLI invoked in the test suite


eval `luarocks path`

# -------------------------------------
# Install ccm & setup Cassandra cluster
# -------------------------------------
if [[ "$KONG_TEST_DATABASE" == "cassandra" ]]; then
  echo "Setting up Cassandra"
  docker run -d --name=cassandra --rm -p 7199:7199 -p 7000:7000 -p 9160:9160 -p 9042:9042 cassandra:$CASSANDRA
  grep -q 'Created default superuser role' <(docker logs -f cassandra)
fi

# -------------------
# Install Test::Nginx
# -------------------
if [[ "$TEST_SUITE" == "pdk" ]]; then
  CPAN_DOWNLOAD=$DOWNLOAD_ROOT/cpanm
  mkdir -p $CPAN_DOWNLOAD
  wget -O $CPAN_DOWNLOAD/cpanm https://cpanmin.us
  chmod +x $CPAN_DOWNLOAD/cpanm
  export PATH=$CPAN_DOWNLOAD:$PATH

  echo "Installing CPAN dependencies..."
  cpanm --notest Test::Nginx &> build.log || (cat build.log && exit 1)
  cpanm --notest --local-lib=$TRAVIS_BUILD_DIR/perl5 local::lib && eval $(perl -I $TRAVIS_BUILD_DIR/perl5/lib/perl5/ -Mlocal::lib)
fi

# ----------------
# Run gRPC server |
# ----------------
if [[ "$TEST_SUITE" =~ integration|dbless|plugins ]]; then
  docker run -d --name grpcbin -p 15002:9000 -p 15003:9001 moul/grpcbin
fi

nginx -V
resty -V
luarocks --version
openssl version
