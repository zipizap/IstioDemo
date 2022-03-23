#!/usr/bin/env bash
# Paulo Aleixo Campos
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
function shw_info { echo -e '\033[1;34m'"$1"'\033[0m'; }
function error { echo "ERROR in ${1}"; exit 99; }
trap 'error $LINENO' ERR
PS4='████████████████████████${BASH_SOURCE}@${FUNCNAME[0]:-}[${LINENO}]>  '
exec > >(tee -i /var/tmp/$(date +%Y%m%d%H%M%S.%N)__$(basename $1).log ) 2>&1
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

apt-get update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    tmux

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker uzer

snap install kubectl --classic
snap install helm --classic
curl -Ls https://api.github.com/repos/derailed/k9s/releases/latest | grep -wo "https.*k9s_Linux_x86_64.tar.gz" | xargs curl -sL | tar xvz k9s

curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.12.0/kind-$(uname)-amd64"
chmod +x ./kind
mv -v ./kind /usr/local/bin
