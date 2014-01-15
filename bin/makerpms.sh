#/bin/bash

VERSION=2.0
LIST="core openstack hadoop hardware build-tools template"
WORK=/tmp/work
RPMHOME=$HOME/rpmbuild
TOPLEVEL=../..
PACKAGESPECS=$TOPLEVEL/build-tools/pkginfo


cd $TOPLEVEL
for repo in `echo $LIST`
do
  ( 
    BLDSPEC=$RPMHOME/SPECS/crowbar-$repo.spec
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
