ssh -oStrictHostKeyChecking=no uzer@$(terraform output -raw pip) ${@}
