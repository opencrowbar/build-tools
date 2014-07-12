#!/bin/bash

set -e
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
[[ $TARGET_DIR ]] || TARGET_DIR="/tftpboot/centos-6.5/ocb-packages"

export OCBDIR="${OCBDIR%/build-tools/bin/${0##*/}}"
[[ -x /.dockerinit ]] || \
    exec "$OCBDIR/core/tools/docker-admin" \
    "$TARGET_OS" \
    '/opt/opencrowbar/build-tools/bin/make-rpms.sh' \
    "--target_dir=${TARGET_DIR}" "$@"

yum -y install rpm-build createrepo git bsdtar
"$OCBDIR/build-tools/bin/make-ocb-rpms.sh"
if [[ $1 = '--with-ruby' ]]; then
    yum -y install gdbm-devel db4-devel tk-devel systemtap-sdt-devel
    "$OCBDIR/build-tools/bin/make-ruby-rpm.sh"
fi

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR/"*.rpm "$TARGET_DIR/repodata"
find /rpmbuild/RPMS -name '*.rpm' -exec mv '{}' "$TARGET_DIR" ';'
(cd "$TARGET_DIR"; createrepo .)
chown -R crowbar:crowbar "$TARGET_DIR"
echo "Built RPMs are in \$HOME/.cache/opencrowbar${TARGET_DIR}"
