#!/bin/bash
set -euxo pipefail

DEPENDENCY_CLOUDFRONT_URL="https://deps.runfinch.com/"
AARCH64_FILENAME_PATTERN="lima-and-qemu.macos-aarch64.[0-9].*\.gz$"
AARCH64_SHASUM_FILENAME_PATTERN="lima-and-qemu.macos.aarch64.[0-9]+.tar.gz.sha512sum$"
AMD64_FILENAME_PATTERN="lima-and-qemu.macos-x86_64.[0-9].*\.gz$"
AMD64_SHASUM_FILENAME_PATTERN="lima-and-qemu.macos.x86_64.[0-9]+.tar.gz.sha512sum$"
AARCH64="aarch64"
X86_64="x86-64"

while getopts d: flag
do
    case "${flag}" in
        d) dependency_bucket=${OPTARG};;
    esac
done

[[ -z "$dependency_bucket" ]] && { echo "Error: Dependency bucket not set"; exit 1; }


aarch64Deps=$(aws s3 ls s3://${dependency_bucket}/${AARCH64}/ --recursive | grep "$AARCH64_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')
[[ -z "$aarch64Deps" ]] && { echo "Error: aarch64 dependency not found"; exit 1; }

aarch64DepsShasum=$(aws s3 ls s3://${dependency_bucket}/${AARCH64}/ --recursive | grep "$AARCH64_SHASUM_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')
[[ -z "$aarch64DepsShasum" ]] && { echo "Error: aarch64 dependency shasum not found"; exit 1 }

amd64Deps=$(aws s3 ls s3://${dependency_bucket}/${X86_64}/ --recursive | grep "$AMD64_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')
[[ -z "$amd64Deps" ]] && { echo "Error: x86_64 dependency not found"; exit 1; }

amd64DepsShasum=$(aws s3 ls s3://${dependency_bucket}/${X86_64}/ --recursive | grep "$AMD64_SHASUM_FILENAME_PATTERN" | sort | tail -n 1 | awk '{print $4}')
[[ -z "$amd64DepsShasum" ]] && { echo "Error: x86_64 dependency shasum not found"; exit 1 }

# Update lima dependency in Makefile
sed -E -i.bak 's|^([[:blank:]]*LIMA_DEPENDENCY_ARCH_FILE_NAME[[:blank:]]*\?=[[:blank:]]*')('${AARCH64_FILENAME_PATTERN}')|\1'$aarch64Deps'|' Makefile
sed -E -i.bak 's|^([[:blank:]]*LIMA_DEPENDENCY_ARCH_FILE_NAME[[:blank:]]*\?=[[:blank:]]*')('${AMD64_FILENAME_PATTERN}')|\1'$amd64Deps'|' Makefile

# Update stored hashes
rm hashes/lima-and-qemu.macos-*.tar.gz.sha512sum

curl -L --fail ${aarch64DepsShasum} > hashes/${aarch64DepsShasum}
curl -L --fail ${amd64DepsShasum} > hashes/${amd64DepsShasum}
