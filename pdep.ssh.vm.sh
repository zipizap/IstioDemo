ssh -oStrictHostKeyChecking=no \
  -L 20080:172.18.255.200:80 \
  -L 8001:127.0.0.1:8001 \
  -L 8002:127.0.0.1:8002 \
  uzer@$(terraform output -raw pip_vm) ${@}
