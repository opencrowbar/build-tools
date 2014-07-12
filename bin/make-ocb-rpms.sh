#!/bin/bash
#
# This script will build development (ephemeral) RPM packages and can build release RPM packages
#   - if you want to build release code execute:
#                                              PRODREL="RELEASE" ./build-tools/bin/makerpms.sh
#   - if you want to build emphemeral RPMS:
#                                              ./build-tools/bin/makerpms/sh

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

PRODREL=${PRODREL:-"Dev"}
VERSION=${VERSION:-2.0.0}
RELEASE=${RELEASE:-1}
WORK=${WORK:-/tmp/work}
RPMHOME=${RPMHOME:-$HOME/rpmbuild}
set -x -e

die() { echo "$(date '+%F %T %z'): $@"; exit 1; }

mkdir -p "$RPMHOME/SOURCES" "$RPMHOME/SPECS" "$RPMHOME/BUILD"

#STATIC VARS
PACKAGESPECS=$OCBDIR/build-tools/pkginfo
PREFIX="\/opt\/opencrowbar"
PKGPREFIX=opencrowbar
# Make sure we start with a clean slate.
[[ -d "$WORK" ]] && rm -rf "$WORK"

for repodir in "$OCBDIR/"*; do
    repo="${repodir##*/}"
    spec_template="$PACKAGESPECS/$PKGPREFIX-$repo.spec.template"
    final_spec="$RPMHOME/SPECS/$PKGPREFIX-$repo.spec"
    [[ -f $spec_template ]] || continue
    cd "$repodir" || die "Can't find $repo"
    git clean -f -x -d || die "Cannot clean $repo"
    PATCHLEVEL=$(git rev-list --no-merges HEAD | wc -l)
    if [[ $PRODREL == "Dev" ]]; then
        SRCVERS=$VERSION.$PATCHLEVEL
    else
        SRCVERS=$VERSION
    fi
    pkgname="$PKGPREFIX-$repo-$SRCVERS"
    target="$WORK/$pkgname"
    cp "$spec_template" "$final_spec"
    # 
    mkdir -p "$target/opt/opencrowbar/$repo" || die "Could not create work directory $target"
    cp -a * "$target/opt/opencrowbar/$repo/". || die "Copying files to $target failed."
    mkdir -p "$target/opt/opencrowbar/$repo/doc/"
    git log --pretty=oneline -n 10 >> "$target/opt/opencrowbar/$repo/doc/README.Last10Merges"
    bsdtar -C "$target/opt/opencrowbar" -czf "$RPMHOME/SOURCES/$pkgname.tgz" \
        -s "/^$repo/$pkgname/" "$repo" || die "Creation of $pkgname.tgz tarball failed!"
    # Populate the %files section of the specfile
    (   cd "$target"
        declare -A dirs
        declare -a files links
        while read file; do
            file=${file#.}
            dirs["${file%/*}"]=true
            files+=($file)
        done < <(find . -type f \! -xtype l |sort -u)
        while read link; do
            link=${link#.}
            dirs["${link%/*}"]=true
            links+=($link)
        done < <(find . -type l|sort -u)
        printf '%s\n' "/opt/opencrowbar/$repo"  "${!dirs[@]}"  |sort -u >> "$final_spec"
        printf '%s\n' "${files[@]}" "${links[@]}" >> "$final_spec"
    )
    # Add our changelog
    cat "$PACKAGESPECS/changelog.spec.template" >> "$final_spec"
    # Fix up template-ized sections of the specfile.
    sed -i -e "s/##OCBVER##/$SRCVERS/g" \
        -e "s/##OCBRELNO##/$RELEASE/g" \
        -e 's/\.py/\.p\*/g' "$final_spec"
    (   cd "$RPMHOME/SPECS"
        rpmbuild --buildroot "$target" -ba --define "_topdir $RPMHOME" \
            -v --clean "$PKGPREFIX-$repo.spec" )
    rm -rf "$target"
done
cd "$OCBDIR" && rm -rf "$WORK"
exit 0
