#!/bin/bash -e

# Add S6 for zombie reaping, boot-time coordination, signal transformation/distribution
# @see https://github.com/just-containers/s6-overlay
#
# Downloads, verifies, and extracts
# Requires curl, gpg (or gnupg on Alpine), and tar to be present

# Determined automatically to correctly select binary
ARCH="$(archstring --x64 amd64 --arm64 aarch64)"

S6_NAME=s6-overlay-${ARCH}.tar.gz
S6_VERSION=${S6_VERSION:="v2.1.0.2"}
PUBLIC_KEY=6101B2783B2FD161

curl -fL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_NAME} -o /tmp/${S6_NAME}
curl -fL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_NAME}.sig -o /tmp/${S6_NAME}.sig

gpg --keyserver pgp.surfnet.nl --recv-keys $PUBLIC_KEY
gpg --verify /tmp/${S6_NAME}.sig /tmp/${S6_NAME}

# Special handling - CentOS >= 7 + Ubuntu >= 20.04
# @see https://github.com/just-containers/s6-overlay#bin-and-sbin-are-symlinks
# Need to also exclude the symlink included in s6-overlay-amd64.tar.gz as the symlink would otherwise overwrite the binary
# $ tar tvzf s6-overlay-amd64.tar.gz |grep execlineb
# -rwxr-xr-x root/root     33856 2019-03-21 12:29 ./bin/execlineb
# lrwxrwxrwx root/root         0 2019-03-21 12:40 ./usr/bin/execlineb -> /bin/execlineb

if [[ -L /bin ]]; then
  tar xzf /tmp/${S6_NAME} -C / --exclude="./bin" --exclude="./usr/bin/execlineb"
  tar xzf /tmp/${S6_NAME} -C /usr ./bin --exclude="./usr/bin/execlineb"
else
  tar xzf /tmp/${S6_NAME} -C /
fi

rm /tmp/${S6_NAME} && rm /tmp/${S6_NAME}.sig
