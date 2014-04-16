#!/bin/bash
# Copyright 2014, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: JohnHTerpstra
#
### NOTES ###
# This will build ruby-2.0.0 specifically for RHEL/Centos 6.5 - no others at this time.
#
# Do not use this tool as the root user - use as a non-privileged user only.
#
# Start this command in the root directory containing the opencrowbar.org GIT clone trees
#   This script checks that the build-tools repo clone is in the current directory,
#   If not found, it checks for its existence in the $HOME/opencrowbar directory
#
# Building of ruby-2.0.0 requires the following packages to be pre-installed on the build
#   system: autoconf, gdbm-devel, ncurses-devel, db4-devel, libffi-devel, openssl-devel
#           libyaml-devel, readline-devel, tk-devel, procps, systemtap-sdt-devel (dtrace)
#
# This script currently only allows building of ruby-2.0.0.
###

set -e

# VARIABLES
RPMBUILD=$HOME/rpmbuild
RUBYVER=ruby-2.0.0
RUBYINFODIR=build-tools/syspackages/ruby/2.0.0

die () {
  echo $1
  exit -1
}

# create temp directory

# Check that we are in the root of the opencrowbar checkout tree
if [[ ! $OCBDIR ]]; then
    if [[ $0 = /* ]]; then
        OCBDIR="$0"
    elif [[ $0 = .*  || $0 = */* ]]; then
        OCBDIR="$(readlink -f "$PWD/$0")"
    else
        echo "Cannot figure out where we are!"
        exit 1
    fi
    OCBDIR="${OCBDIR%/build-tools/bin/${0##*/}}"
fi

# Create build tree, move ruby tarball into it, clean up mess
[[ -d $RPMBUILD ]] || mkdir -p "$RPMBUILD"/{SPECS,SOURCES}

# Prep destinfo, pull down ruby sources, create clean tarball
cd /opt/opencrowbar
if [[ ! -d ruby/.git ]]; then
    git clone https://github.com/ruby/ruby
    cd ruby
else
    cd ruby
    git fetch origin
fi

git checkout origin/ruby_2_0_0
RUBYPL=$(grep "^#define RUBY_PATCHLEVEL " version.h | awk '{print $3}')

# Now create the pristine tarball
bsdtar -C /opt/opencrowbar -cjf "$RPMBUILD/SOURCES/$RUBYVER-p$RUBYPL.tar.bz2" \
        -s "/^ruby/$RUBYVER-p$RUBYPL/" ruby || \

# Go back to where we started, move other parts of the build stuff into place
[[ -d $OCBDIR/$RUBYINFODIR ]] || die "Can't find critical ruby build files."
cp -a "$OCBDIR/$RUBYINFODIR/"* "$RPMBUILD/SOURCES/"
cd "$RPMBUILD/SOURCES" && sed "s/##PATCHLEVEL##/$RUBYPL/g" < ruby.spec > ../SPECS/ruby.spec

# Now check we are ready to go, then build the ruby packages and clean up
cd ../SPECS
grep -q "$RUBYPL" ruby.spec || die "Ruby patchlevel substitution did not validate."
rpmbuild -ba --clean ruby.spec || die "Ruby RPM Build failed"
