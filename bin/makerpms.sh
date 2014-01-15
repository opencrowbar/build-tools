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


cd $TOPLEVEL
for repo in `echo $CROWBAR_REPOS`
do
  BLDSPEC=$RPMHOME/SPECS/crowbar-$repo.spec
  ( 
    mkdir -p $WORK/crowbar-$repo-$VERSION

    cp $PACKAGESPECS/crowbar-$repo.spec.template $BLDSPEC
    ( cd $repo && rsync -a . $WORK/crowbar-$repo-$VERSION/. )
    cd $WORK
    tar czvf crowbar-$repo-$VERSION.tgz --exclude=.git\* crowbar-$repo-$VERSION
    mv crowbar-$repo-$VERSION.tgz $RPMHOME/SOURCES/
    cd $WORK/crowbar-$repo-$VERSION
    find * -type d ! -xtype l | grep -v \.git | sed "s/^/\%dir \/opt\/crowbar\/${repo}\//g" >>  $BLDSPEC
    find * -type f | grep -v \.git | sed "s/^/\/opt\/crowbar\/${repo}\//g" >> $BLDSPEC
    find * -type l | grep -v \.git | sed "s/^/\/opt\/crowbar\/${repo}\//g" >> $BLDSPEC
    rm -rf crowbar-$repo-$VERSION
  )

  cat $PACKAGESPECS/changelog.spec.template >> $BLDSPEC
  ( cd $RPMHOME/SPECS && rpmbuild -ba -v crowbar-$repo.spec )
  rm -rf $WORK
done
exit 0
