#!/usr/bin/env bash
# Paulo Aleixo Campos
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
function shw_info { echo -e '\033[1;34m'"$1"'\033[0m'; }
function error { echo "ERROR in ${1}"; exit 99; }
trap 'error $LINENO' ERR
PS4='████████████████████████${BASH_SOURCE}@${FUNCNAME[0]:-}[${LINENO}]>  '
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

LxdVmName=ciDnsAuth1

cd "${__dir}"
cat > cloudinit.userdata.yaml <<EOT
#cloud-config

## Order of execution (cat /etc/cloud/cloud.cfg)
## 1) write_files  
## (before packages are installed and bind-user created and package-dirs created with proper permitions...)
write_files:
- path: /var/lib/cloud/scripts/per-once/01.scripts-per-once.sh
  owner: root:root
  permissions: '0544'
  encoding: gz
  content: !!binary |
$(cat ./01.scripts-per-once.sh | gzip | base64 | sed 's/^/    /g')

## 3) packages
package_upgrade: true
packages:
- dnsutils

## 4) scripts-per-once
## ie, scripts in /var/lib/cloud/scripts/per-once 
## as our crafted /var/lib/cloud/scripts/per-once/01.scripts-per-once.sh
## :)

EOT
cat cloudinit.userdata.yaml




