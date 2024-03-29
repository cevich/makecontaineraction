

set -eo pipefail

echo "Executing $0"

die() {
    echo "Error: ${1:-No error message specified}"
    exit 1
}

[[ "$DOCKERFILE" == "true" ]] || \
    # Left-align penultimate lines with 'Error: ' prefix.
    die "This script is intended to be executed from a run instruction in a
       Dockerfile. It configures the container environment as required to
       produce the intended image.  Execution outside of this context,
       with \$DOCKERFILE != 'true' is unsupported and may cause harm"

[[ -r "$1" ]] || \
    die "This script must be called with the path to a line-delimited file
       containing the names of RPMs to install."

PACKAGES=("$(<$1)")

[[ "${#PACKAGES[@]}" -gt "0" ]] || \
    die "Did not find any packages to install from packages.txt"

(
    set -x
    dnf install -y ${PACKAGES[@]}
    dnf clean all
    rm -rf /var/cache/dnf

    echo "Configuring container-in-container storage"
    sed -i -r -e 's/^(driver = .+)/driver = "vfs"/' /etc/containers/storage.conf
    sed -i -r -e 's/^(mountopt = .+)/mountopt = ""/' /etc/containers/storage.conf
) |& tee /root/$(basename "$0" | cut -d '.' -f 1).log
