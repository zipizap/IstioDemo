#!/usr/bin/env bash
# Paulo Aleixo Campos
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
function shw_info { echo -e '\033[1;34m'"$1"'\033[0m'; }
function error { echo "ERROR in ${1}"; exit 99; }
trap 'error $LINENO' ERR
exec > >(tee -i /tmp/$(date +%Y%m%d%H%M%S.%N)__$(basename $0)_${1:-}.log ) 2>&1
PS4='████████████████████████${BASH_SOURCE}@${FUNCNAME[0]:-}[${LINENO}]>  '
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

load_gitignoreme.Backend.Provider.source() {
  [[ -r ./gitignoreme.Backend.Provider.source ]] || { echo "Missing file gitignoreme.Backend.Provider.source - aborting!"; exit 1; }
  set +x
  source ./gitignoreme.Backend.Provider.source
  set -x
  terraform version
}

terraform_init() {
  load_gitignoreme.Backend.Provider.source

  if [[ "$BACKEND_PROVIDER" == "RemoteBackend_ProviderViaSPN" ]]; then
    terraform init \
      -input=false \
      -backend-config=resource_group_name=$AZURERM_Backend_RG_NAME \
      -backend-config=tenant_id=$AZURERM_Backend_TENANT_ID \
      -backend-config=subscription_id=$AZURERM_Backend_SUBSCRIPTION_ID \
      -backend-config=client_id=$AZURERM_Backend_CLIENT_ID \
      -backend-config=client_secret="$AZURERM_Backend_CLIENT_SECRET" \
      -backend-config=storage_account_name=$AZURERM_Backend_STA_NAME \
      -backend-config=container_name=$AZURERM_Backend_STA_CONTAINER_NAME \
      -backend-config=key=$AZURERM_Backend_STA_CONTAINER_KEY_NAME
  elif [[ "$BACKEND_PROVIDER" == "LocalBackend_ProviderAzLogin" ]]; then
    terraform init \
      -input=false
  fi
}
terraform_reinit() {
  load_gitignoreme.Backend.Provider.source
  # force cleanup  (-reconfigure should do this, but it seemes not quite in fact... this is easier...)
  [[ -d ./.terraform ]] && rm -rf ./.terraform
  rm -rfv ./.terraform .terraform.lock.hcl *.tfstate *.tfstate.backup "${THE_TFPLAN_FILE}" || true
  terraform_init
}

terraform_plan() {
  load_gitignoreme.Backend.Provider.source
  THE_TFVARS_FILE="${THE_TFVARS_FILE?missing env-var}"
  THE_TFPLAN_FILE="${THE_TFPLAN_FILE?missing env-var}"
  terraform validate \
     -no-color
  [[ -r "${THE_TFPLAN_FILE}" ]] && rm -f "${THE_TFPLAN_FILE}" &>/dev/null
  terraform plan \
     -input=false \
     -var-file=$THE_TFVARS_FILE \
     -out="${THE_TFPLAN_FILE}"
}


terraform_apply() {
  load_gitignoreme.Backend.Provider.source
  terraform apply \
     -input=false \
     "${THE_TFPLAN_FILE}"
}

terraform_destroy_plan() {
  load_gitignoreme.Backend.Provider.source
  THE_TFVARS_FILE="${THE_TFVARS_FILE?missing env-var}"
  terraform plan -destroy \
     -input=false \
     -var-file=$THE_TFVARS_FILE
}

terraform_destroy() {
  load_gitignoreme.Backend.Provider.source
  THE_TFVARS_FILE="${THE_TFVARS_FILE?missing env-var}"
  terraform destroy \
     -input=false -auto-approve \
     -var-file=$THE_TFVARS_FILE
}

show_args_and_exit() {
  cat <<EOT
$(basename $0)
    init|reinit
    plan
    apply
    destroy_plan|destroy
EOT
  exit 1
}

main() {
  [[ "$#" -eq 0 ]] && show_args_and_exit
  while test $# -gt 0
  do
    case "$1" in
      init)
        terraform_init
        ;;
      reinit)
        terraform_reinit
        ;;
      plan)
        terraform_plan
        ;;
      apply)
        terraform_apply
        ;;
      destroy_plan)
        terraform_destroy_plan
        ;;
      destroy)
        terraform_destroy
        ;;
      *)
        show_args_and_exit
        ;;
    esac
    shift
  done
  shw_info "=== Completed successfully ==="
}
main "$@"

