To build the OpenCrowbar RPMS (optionally including Ruby), perform the
following steps:

1. Start in a clean checkout directory.  We recommend
   `$HOME/opencrowbar`.
2. Clone the core and build-tools repos if you have not already done
so with `git clone https://github.com/opencrowbar/<reponame>`
3. Clone any workload repositories you want to use.  You can see the
full list at https://github.com/opencrowbar
4. Run the RPM build process with
   `$HOME/opencrowbar/build-tools/bin/make-rpms.sh`.  This will build
   RPM files for all the opencrowbar components.  If you want to build
   our Ruby RPMs, add ` --with-ruby` to the end of that command.
5. Use the fully-populated yum repository at
   `$HOME/.cache/opencrowbar/tftpboot/centos-6.6/ocb-packages` to
   install your new admin node.  How to get the repo onto your
   already-built admin node is left as an excercise for the reader.
