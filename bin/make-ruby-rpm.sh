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
# This will build ruby-2.0.0 specifically for RHEL/Centos 6.6 - no others at this time.
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

set -e -x

# VARIABLES
RPMBUILD=$HOME/rpmbuild

die () {
  echo $1
  exit -1
}

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
SPECDIR="$OCBDIR/ruby-2.1.x-rpm"
# Make sure we have an rpmbuild tree
[[ -d $RPMBUILD ]] || mkdir -p "$RPMBUILD"/{SPECS,SOURCES}

if [[ ! -d $SPECDIR/.git ]]; then
    (cd "$OCBDIR" && git clone https://github.com/opencrowbar/ruby-2.1.x-rpm) || \
        die "Cannot clone our ruby specfile repo!"
fi
which rpmbuild || yum -y install rpm-build
which spectool || yum -y install rpmdevtools
which yum-builddep || yum -y install yum-utils

# Fetch our latest specfile.
( cd "$SPECDIR" && git fetch && git checkout -f master ) || \
    die "Could not get our latest Ruby specfile."
cd "$RPMBUILD/SPECS"
cp "$SPECDIR/ruby21x.spec" .
yum-builddep -y ruby21x.spec
spectool -A -R -g ruby21x.spec
rpmbuild -ba --clean --rmsource ruby21x.spec
