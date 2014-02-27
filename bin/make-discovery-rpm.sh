#!/bin/bash
#
# This script generates the discovery agent tarball. This tool was formerly known as
#   Sledgehammer and consists of a PXE-loadable image that contains a shrunken
#   Linux system image and a few tools used by OpenCrowbar to perform hardware 
#   provisioning prior to commencing layered deployment.
#

#USERDEFINED
CROWBAR_HOME=${CROWBAR_HOME:-$HOME/opencrowbar}
PRODREL=${PRODREL:-"Dev"}
VERSION=${VERSION:-2.0.0}
RELEASE=${RELEASE:-1}
WORK=${WORK:-/tmp/work}
RPMHOME=${RPMHOME:-$HOME/rpmbuild}
[[ $CACHE_DIR ]] || CACHE_DIR="$WORK/opencrowbar/discovery"
[[ $SLEDGEHAMMER_PXE_DIR ]] || SLEDGEHAMMER_PXE_DIR="${CACHE_DIR}/tftpboot/discovery"
[[ $CHROOT ]] || CHROOT="$CACHE_DIR/chroot"
[[ $SLEDGEHAMMER_LIVECD_CACHE ]] || SLEDGEHAMMER_LIVECD_CACHE="$CACHE_DIR/livecd_cache"
[[ $SYSTEM_TFTPBOOT_DIR ]] || SYSTEM_TFTPBOOT_DIR="/mnt/tftpboot"


die(){
	echo "$(date '+%F %T %z'): $@"
        exit 1
}

if [[ ! -d $RPMHOME || ! -d $RPMHOME/SOURCES || ! -d $RPMHOME/SPECS  || ! -d $RPMHOME/BUILD ]]
then
  mkdir -p $RPMHOME/SOURCES $RPMHOME/SPECS $RPMHOME/BUILD 
fi

#STATIC VARS
repo="core"
PACKAGESPECS=$CROWBAR_HOME/build-tools/pkginfo
PREFIX="\/opt\/opencrowbar"
PKGPREFIX=opencrowbar
PRODNAME=$PKGPREFIX-$repo-discovery
BLDSPEC=$RPMHOME/SPECS/$PRODNAME.spec

get_patchlevel() {
    PATCHLEVEL=`git rev-list --no-merges HEAD | wc -l`
    if [[ $PRODREL == "Dev" ]]; then
        SRCVERS=$VERSION.$PATCHLEVEL
    else
        SRCVERS=$VERSION
    fi
}

  cd $repo || die "Can't find $repo Repository"
  get_patchlevel
  mkdir -p $WORK/$PRODNAME-$SRCVERS  || \
          die "Could not create work directory $WORK/$PRODNAME-$SRCVERS"
  rsync -a . $WORK/$PRODNAME-$SRCVERS/. || \
          die "Copying (rsync) of files to work directory failed."
  git log --pretty=oneline -n 10 >> $WORK/$PRODNAME-$SRCVERS/doc/README.Last10Merges
  cd $WORK || \
          die "Could not change to $WORK directory"
  tar czf $PRODNAME-$SRCVERS.tgz --exclude=.git\* $PRODNAME-$SRCVERS || \
          die "Creation of $PRODNAME-$SRCVERS.tgz tarball failed!"
  mv $PRODNAME-$SRCVERS.tgz $RPMHOME/SOURCES/ || \
          die "Could not move $PRODNAME-$SRCVERS.tgz to rpmbuild tree"
  cd $WORK/$PRODNAME-$SRCVERS || \
          die "$WORK/$PRODNAME-$SRCVERS directory not accessible!"

  # Create the opencrowbar-discovery package containing Sledgehammer
  ( cp $PACKAGESPECS/$PRODNAME.spec.template $BLDSPEC && \
      cat $PACKAGESPECS/changelog.spec.template >> $BLDSPEC ) || \
        die "Could not find $PKGPREFIX-$repo.spec.template"

  # Update package version info in SPEC file.
  sed -i "s/##OCBVER##/$SRCVERS/g" $BLDSPEC
  sed -i "s/##OCBRELNO##/$RELEASE/g" $BLDSPEC

  ( cd $RPMHOME/SPECS && rpmbuild -ba --define "_topdir $RPMHOME" -v --clean $PRODNAME.spec )
  cd $CROWBAR_HOME 

exit -1
