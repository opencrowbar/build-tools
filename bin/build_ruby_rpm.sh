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

# VARIABLES
OCBDIR=${OCBDIR:-$HOME/opencrowbar}
TMPDIR=/tmp/work
RPMBUILD=$HOME/rpmbuild
RUBYVER=ruby-2.0.0
RUBYINFODIR=build-tools/syspackages/ruby/2.0.0
PKGTGT=$HOME/Ruby

die () {
  echo $1
  exit -1
}

# Identify present location so we can return to it, create temp directory
PWD=`pwd` && mkdir -p $TMPDIR

# Check that we are in the root of the opencrowbar checkout tree
if [[ -d build-tools ]]; then
  OCBDIR=$PWD
else
   [[ -d $OCBDIR/build-tools ]] || die "Can't find opencrowbar.org GIT local repository checkouts"
fi

# Prep destinfo, pull down ruby sources, create clean tarball
cd $TMPDIR && git clone https://github.com/ruby/ruby
cd ruby && git checkout origin/ruby_2_0_0
RUBYPL=`grep "^#define RUBY_PATCHLEVEL " version.h | awk '{print $3}'`
cd .. && mv ruby $RUBYVER-p$RUBYPL

# Now create the pristine tarball
tar cjf $RUBYVER-p$RUBYPL.tar.bz2 $RUBYVER-p$RUBYPL

# Create build tree, move ruby tarball into it, clean up mess
[[ -d $RPMBUILD ]] || mkdir -p $RPMBUILD/{SPECS,SOURCES}
mv $RUBYVER-p$RUBYPL.tar.bz2 $RPMBUILD/SOURCES/
cd $PWD && rm -rf $TMPDIR

# Go back to where we started, move other parts of the build stuff into place
[[ -d $OCBDIR/$RUBYINFODIR ]] || die "Can't find critical ruby build files."
cp -a $OCBDIR/$RUBYINFODIR/* $RPMBUILD/SOURCES/
cd $RPMBUILD/SOURCES && sed "s/##PATCHLEVEL##/$RUBYPL/g" < ruby.spec > ../SPECS/ruby.spec

# Now check we are ready to go, then build the ruby packages and clean up
cd ../SPECS
grep $RUBYPL ruby.spec
[[ $? ]] || die "Ruby patchlevel substitution did not validate."
rpmbuild -ba --clean ruby.spec
[[ $? ]] || die "Ruby RPM Build failed"

# Now move the built packages into the $PKGTGT directory, then clean up.
[[ -d $PKGTGT ]] || mkdir -p $PKGTGT
cd $RPMBUILD/RPMS
( cd noarch; cp * $PKGTGT/ )
( cd x86_64; cp * $PKGTGT/ )

exit 0
