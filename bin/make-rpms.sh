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

export OCBDIR="${OCBDIR%/build-tools/bin/${0##*/}}"
[[ -x /.dockerinit ]] || \
    exec "$OCBDIR/core/tools/docker-admin" centos '/opt/opencrowbar/build-tools/bin/make-rpms.sh' "$@"

yum -y install rpm-build createrepo
"$OCBDIR/build-tools/bin/make-ocb-rpms.sh"
if [[ $1 = '--with-ruby' ]]; then
    yum -y install gdbm-devel db4-devel tk-devel systemtap-sdt-devel
    "$OCBDIR/build-tools/bin/make-ruby-rpm.sh"
fi

target_dir="/tftpboot/centos-6.5/ocb-packages"

mkdir -p "$target_dir"
rm -rf "$target_dir/"*.rpm "$target_dir/repodata"
find /rpmbuild/RPMS -name '*.rpm' -exec mv '{}' "$target_dir" ';'
(cd "$target_dir"; createrepo .)
chown -R crowbar:crowbar "$target_dir"
echo "Built RPMs are in \$HOME/.cache/opencrowbar/tftpboot/centos-6.5/ocb-packages"
