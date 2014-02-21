#!/bin/bash
#
# This script will build development (ephemeral) RPM packages and can build release RPM packages
#   - if you want to build release code execute:
#                                              PRODREL="RELEASE" ./build-tools/bin/makerpms.sh
#   - if you want to build emphemeral RPMS:
#                                              ./build-tools/bin/makerpms/sh

#USERDEFINED
CROWBAR_HOME=${CROWBAR_HOME:-$HOME/opencrowbar}
CROWBAR_REPOS=${CROWBAR_REPOS:-"core openstack hadoop hardware build-tools template"}
PRODREL=${PRODREL:-"Dev"}
VERSION=${VERSION:-2.0.0}
RELEASE=${RELEASE:-1}
WORK=${WORK:-/tmp/work}
RPMHOME=${RPMHOME:-$HOME/rpmbuild}

die() { echo "$(date '+%F %T %z'): $@"; exit 1; }

if [[ ! -d $RPMHOME || ! -d $RPMHOME/SOURCES || ! -d $RPMHOME/SPECS  || ! -d $RPMHOME/BUILD ]]
then
  mkdir -p $RPMHOME/SOURCES $RPMHOME/SPECS $RPMHOME/BUILD 
fi

#STATIC VARS
PACKAGESPECS=$CROWBAR_HOME/build-tools/pkginfo
PREFIX="\/opt\/opencrowbar"
PKGPREFIX=opencrowbar

get_patchlevel() {
#   PATCHLEVEL=`git log --abbrev-commit --pretty=oneline -n 1 | awk '{print $1}'`
    PATCHLEVEL=`git rev-list --no-merges HEAD | wc -l`
    if [[ $PRODREL == "Dev" ]]; then
        SRCVERS=$VERSION.$PATCHLEVEL
    else
        SRCVERS=$VERSION
    fi
}

cd $CROWBAR_HOME
for repo in $CROWBAR_REPOS
do
  BLDSPEC=$RPMHOME/SPECS/$PKGPREFIX-$repo.spec
  ( 
    cp $PACKAGESPECS/$PKGPREFIX-$repo.spec.template $BLDSPEC || \
            die "Could not find $PKGPREFIX-$repo.spec.template"
    cd $repo || die "Can't find $repo"
    get_patchlevel
    sed -i "s/##OCBVER##/$SRCVERS/g" $BLDSPEC
    sed -i "s/##OCBRELNO##/$RELEASE/g" $BLDSPEC
    mkdir -p $WORK/$PKGPREFIX-$repo-$SRCVERS  || \
            die "Could not create work directory $WORK/$PKGPREFIX-$repo-$SRCVERS"
    rsync -a . $WORK/$PKGPREFIX-$repo-$SRCVERS/. || \
            die "Copying (rsync) of files to work directory failed."
    git log --pretty=oneline -n 10 >> $WORK/$PKGPREFIX-$repo-$SRCVERS/doc/README.Last10Merges
    cd $WORK || \
            die "Could not change to $WORK directory"
    tar czf $PKGPREFIX-$repo-$SRCVERS.tgz --exclude=.git\* $PKGPREFIX-$repo-$SRCVERS || \
            die "Creation of $PKGPREFIX-$repo-$SRCVERS.tgz tarball failed!"
    mv $PKGPREFIX-$repo-$SRCVERS.tgz $RPMHOME/SOURCES/ || \
            die "Could not move $PKGPREFIX-$repo-$SRCVERS.tgz to rpmbuild tree"
    cd $WORK/$PKGPREFIX-$repo-$SRCVERS || \
            die "$WORK/$PKGPREFIX-$repo-$SRCVERS directory not accessible!"
    find . -type d ! -xtype l | grep -v \.git | sed "s/^/\%dir $PREFIX\/${repo}\//g" >>  $BLDSPEC
    find . -type f | grep -v \.git | sed "s/^/$PREFIX\/${repo}\//g" >> $BLDSPEC
    find . -type l | grep -v \.git | sed "s/^/$PREFIX\/${repo}\//g" >> $BLDSPEC
    rm -rf $PKGPREFIX-$repo-$SRCVERS || \
            die "Could not clean up $PKGPREFIX-$repo-$SRCVERS after creation of pristine sources"
  )
  cat $PACKAGESPECS/changelog.spec.template >> $BLDSPEC
  sed -i 's/\.py/\.p\*/g' $BLDSPEC
  ( cd $RPMHOME/SPECS && rpmbuild -ba --define "_topdir $RPMHOME" -v --clean $PKGPREFIX-$repo.spec )
  cd $CROWBAR_HOME && rm -rf $WORK
done

# Create the opencrowbar-discovery package containing Sledgehammer
  repo=core
  BLDSPEC=$RPMHOME/SPECS/$PKGPREFIX-$repo-discovery.spec
  ( 
    cp $PACKAGESPECS/$PKGPREFIX-$repo.spec.template $BLDSPEC || \
            die "Could not find $PKGPREFIX-$repo.spec.template"
    cd $repo || die "Can't find $repo"
    get_patchlevel
    sed -i "s/##OCBVER##/$SRCVERS/g" $BLDSPEC
    sed -i "s/##OCBRELNO##/$RELEASE/g" $BLDSPEC
  )
  cat $PACKAGESPECS/changelog.spec.template >> $BLDSPEC
  ( cd $RPMHOME/SPECS && rpmbuild -ba --define "_topdir $RPMHOME" -v --clean $PKGPREFIX-$repo-discovery.spec )
  cd $CROWBAR_HOME 

exit 0 
