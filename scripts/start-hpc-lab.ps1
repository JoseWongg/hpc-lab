# Start all lab VMs again

# How to run:
# 1. Open PowerShell
# 2. Connect to Azure with `az login`
# 3. Run this script with `.\start-hpc-lab.ps1`

az vm start --resource-group HPC_Lab --name hpc-login-ctl
az vm start --resource-group HPC_Lab --name hpc-compute-01
az vm start --resource-group HPC_Lab --name hpc-compute-02

az vm list --resource-group HPC_Lab --show-details --output table