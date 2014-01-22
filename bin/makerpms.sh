#/bin/bash

#USERDEFINED
CROWBAR_HOME=${CROWBAR_HOME:-$HOME/opencrowbar}
CROWBAR_REPOS=${CROWBAR_REPOS:-"core openstack hadoop hardware build-tools template"}
WORK=${WORK:-/tmp/work}
RPMHOME=${RPMHOME:-$HOME/rpmbuild}

die() { echo "$(date '+%F %T %z'): $@"; exit 1; }

if [[ ! -d $RPMHOME || ! -d $RPMHOME/SOURCES || ! -d $RPMHOME/SPECS  || ! -d $RPMHOME/BUILD ]]
then
  mkdir -p $RPMHOME/SOURCES $RPMHOME/SPECS $RPMHOME/BUILD 
fi

#STATIC VARS
VERSION=2.0
TOPLEVEL=${CROWBAR_HOME}/.
PACKAGESPECS=${TOPLEVEL}/build-tools/pkginfo
PREFIX=/opt/opencrowbar
PKGPREFIX=opencrowbar

cd $TOPLEVEL
for repo in `echo $CROWBAR_REPOS`
do
  BLDSPEC=$RPMHOME/SPECS/$PKGPREFIX-$repo.spec
  ( 
    mkdir -p $WORK/$PKGPREFIX-$repo-$VERSION

    cp $PACKAGESPECS/$PKGPREFIX-$repo.spec.template $BLDSPEC
    ( cd $repo && rsync -a . $WORK/$PKGPREFIX-$repo-$VERSION/. )
    cd $WORK
    tar czvf $PKGPREFIX-$repo-$VERSION.tgz --exclude=.git\* $PKGPREFIX-$repo-$VERSION
    mv $PKGPREFIX-$repo-$VERSION.tgz $RPMHOME/SOURCES/
    cd $WORK/$PKGPREFIX-$repo-$VERSION
    find * -type d ! -xtype l | grep -v \.git | sed "s/^/\%dir $PREFIX\/${repo}\//g" >>  $BLDSPEC
    find * -type f | grep -v \.git | sed "s/^/$PREFIX\/${repo}\//g" >> $BLDSPEC
    find * -type l | grep -v \.git | sed "s/^/$PREFIX\/${repo}\//g" >> $BLDSPEC
    rm -rf $PKGPREFIX-$repo-$VERSION
  )

  cat $PACKAGESPECS/changelog.spec.template >> $BLDSPEC
  ( cd $RPMHOME/SPECS && rpmbuild -ba --define "_topdir=$RPMHOME" -v $PKGPREFIX-$repo.spec )
  rm -rf $WORK
done
exit 0 
