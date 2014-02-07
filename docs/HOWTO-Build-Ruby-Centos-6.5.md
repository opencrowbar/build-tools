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

Centos 6.5 / RHEL 6.5 ships with Ruby 1.8.7. 
OpenCrowbar requires Ruby 1.9.3 or later.

To build the ruby-2.0.0 RPMS execute the following:

Start in a clean checkout directory.
  A. git clone https://github.com/opencrowbar/build-tools
  B. export CROWBAR_HOME=`pwd`
  C. ./build-tools/bin/makerpms.sh

At completion, if all went well, the RPMS needed will be located
in the $HOME/Ruby directory.  This directory will be created if
it does not exist.  The $HOME/Ruby directory is the Local RPM Cache.


========== NOTES ==========

The following steps outline the process for building Ruby 2.0.0
RPM packages that can replace the Centos 6.5 Ruby 1.8.7 packages.

1. PWD=`pwd` && mkdir -p /tmp/Work
2. cd /tmp/Work
3. git clone https://github.com/ruby/ruby.git
4. cd ruby
5. git checkout -b origin/ruby_2_0_0
6. cd ..
7. Filter from ruby_2_0_0/version.h the value of:
    #define RUBY_PATCHLEVEL 388
8. Rename:  mv ruby_2_0_0 to ruby-2.0.0.p${patchlevel}
9. tar cjvf ruby-2.0.0.p${patchlevel}.tar.bz2 ruby-2.0.0.p${patchlevel}
10. mkdir -p $HOME/rpmbuild/{SOURCES,SPECS}
11. mv ruby-2.0.0.p${patchlevel}.tar.bz2 $HOME/rpmbuild/SOURCES/
12. cd $PWD
13. cp -a build-tools/syspackages/ruby/2.0.0/ruby.spec $HOME/rpmbuild/SPECS
14. cp -a build-tools/syspackages/ruby/2.0.0/{*.stp,macros.*,oper*} $HOME/rpmbuild/SOURCES/.
15. In $HOME/rpmbuild/SPECS/ruby.spec replace ##PATCHLEVEL## with ${patchlevel}
16. cd $HOME/rpmbuild/SPECS
17. rpmbuild -ba -v ruby.spec
18. Copy $HOME/rpmbuild/RPMS/{noarch/ruby*rpm,x86_64/ruby*rpm} to Local RPM Cache.
