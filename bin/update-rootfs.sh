#!/bin/bash

# A script to update the rootfs used for Finch on Windows.
#
# Usage: bash update-rootfs.sh -d <S3 bucket>

set -euxo pipefail

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${current_dir}/.." && pwd)"

source ${project_root}/bin/utility.sh

DEPENDENCY_CLOUDFRONT_URL="https://deps.runfinch.com/"
AARCH64_FILENAME_PATTERN="common/aarch64/finch-rootfs-production-arm64-[0-9].*\.tar.gz$"
AARCH64_SHASUM_FILENAME_PATTERN="common/aarch64/finch-rootfs-production-arm64-[0-9].*\.tar.gz.sha512sum$"
AMD64_FILENAME_PATTERN="common/x86-64/finch-rootfs-production-amd64-[0-9].*\.tar.gz$"
AMD64_SHASUM_FILENAME_PATTERN="common/x86-64/finch-rootfs-production-amd64-[0-9].*\.tar.sha512sum$"
PLATFORM="common"
AARCH64="aarch64"
X86_64="x86-64"

while getopts d: flag
do
        case "${flag}" in
            d) dependency_bucket=${OPTARG};;
         esac
done

[[ -z "$dependency_bucket" ]] && { echo "Error: Dependency bucket not set"; exit 1; }

aarch64_deps=$(find_latest_object_match_from_s3 "${AARCH64_FILENAME_PATTERN}" "${dependency_bucket}/${PLATFORM}/${AARCH64}")
if [[ $? -ne 0 ]]; then
    echo "$aarch64_deps"
    exit 1
fi

aarch64_deps_shasum=$(find_latest_object_match_from_s3 "${AARCH64_SHASUM_FILENAME_PATTERN}" "${dependency_bucket}/${PLATFORM}/${AARCH64}")
if [[ $? -ne 0 ]]; then
    echo "$aarch64_deps_shasum"
    exit 1
fi

amd64_deps=$(find_latest_object_match_from_s3 "${AMD64_FILENAME_PATTERN}" "${dependency_bucket}/${PLATFORM}/${X86_64}")
if [[ $? -ne 0 ]]; then
    echo "$amd64_deps"
    exit 1
fi

amd64_deps_shasum=$(find_latest_object_match_from_s3 "${AMD64_FILENAME_PATTERN}" "${dependency_bucket}/${PLATFORM}/${X86_64}")
if [[ $? -ne 0 ]]; then
    echo "$amd64_shasum_deps"
    exit 1
fi

# Update rootfs dependency in Makefile
sed -E  -i.bak  's|^([[:blank:]]*FINCH_ROOTFS_URL[[:blank:]]*\?=[[:blank:]]*'${DEPENDENCY_CLOUDFRONT_URL}')('${AARCH64_FILENAME_PATTERN}')|\1'$aarch64Deps'|' Makefile
sed -E  -i.bak  's|^([[:blank:]]*FINCH_ROOTFS_URL[[:blank:]]*\?=[[:blank:]]*'${DEPENDENCY_CLOUDFRONT_URL}')('${AMD64_FILENAME_PATTERN}')|\1'$amd64Deps'|'  Makefile

# Update stored hashes
rm hashes/finch-rootfs-production-*.tar.gz.sha512sum

curl -L --fail ${aarch64_deps_shasum} > hashes/${aarch64_deps_shasum}
curl -L --fail ${aarch64_deps_shasum} > hashes/${aarch64_deps_shasum}
