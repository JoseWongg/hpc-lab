# Start all lab VMs again

# How to run:
# 1. Open PowerShell
# 2. Connect to Azure with `az login`. To connect type `az login --use-device-code` and follow the instructions to authenticate with your Azure account. Make sure you have access to the subscription where the HPC Lab resources are located.
# 3. Run this script with `.\scripts\start-hpc-lab.ps1`

az vm start --resource-group HPC_Lab --name hpc-login-ctl
az vm start --resource-group HPC_Lab --name hpc-compute-01
az vm start --resource-group HPC_Lab --name hpc-compute-02

az vm list --resource-group HPC_Lab --show-details --output table