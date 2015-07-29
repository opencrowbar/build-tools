#!/bin/bash

set -e -x
export RPMHOME=${RPMHOME:-$HOME/rpmbuild}
export PS4='${BASH_SOURCE}@${LINENO}(${FUNCNAME[0]}): '
# Check that we are in the root of the opencrowbar checkout tree
if [[ $0 = /* ]]; then
    OCBDIR="$0"
elif [[ $0 = .*  || $0 = */* ]]; then
    OCBDIR="$(readlink -f "$PWD/$0")"
else
    echo "Cannot figure out where we are!"
    exit 1
fi
if [[ $1 = --target_dir=* ]]; then
    TARGET_DIR="${1#*=}"
    shift
fi
[[ $TARGET_OS ]] || TARGET_OS="centos"
[[ $TARGET_DIR ]] || TARGET_DIR="/tftpboot/centos-6.6/"

export OCBDIR="${OCBDIR%/build-tools/bin/${0##*/}}"
[[ -x /.dockerinit ]] || \
    exec "$OCBDIR/core/tools/docker-admin" \
    "$TARGET_OS" \
    --no-shell \
    '/opt/opencrowbar/build-tools/bin/make-rpms.sh' \
    "--target_dir=${TARGET_DIR}" "$@"

make_repo() {
    mkdir -p "$TARGET_DIR/$1/"
    rm -rf "$TARGET_DIR/"*.rpm "$TARGET_DIR/$1/repodata"
    find $RPMHOME/RPMS -name '*.rpm' -exec mv '{}' "$TARGET_DIR/$1" ';'
    (cd "$TARGET_DIR/$1"; createrepo .)
}

# We do not want the raw_pkgs package info here.
rm -f /etc/yum.repos.d/crowbar-raw_pkgs.repo || :
yum -y downgrade libyaml # epel is messed up and missing libyaml-devel for 1.6
yum -y install rpm-build createrepo git bsdtar libyaml-devel
"$OCBDIR/build-tools/bin/make-ocb-rpms.sh"
make_repo ocb-packages

if [[ $1 = '--with-ruby' ]]; then
    yum -y install gdbm-devel db4-devel tk-devel systemtap-sdt-devel
    "$OCBDIR/build-tools/bin/make-ruby-rpm.sh"
    make_repo ruby
fi
chown -R crowbar:crowbar "$TARGET_DIR"
echo "Built RPMs are in \$HOME/.cache/opencrowbar${TARGET_DIR}"
