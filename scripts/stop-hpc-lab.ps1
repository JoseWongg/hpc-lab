# Stop and deallocate all lab VMs so Azure compute charges stop

# How to run:
# 1. Open PowerShell
# 2. Connect to Azure with `az login`. To connect type `az login --use-device-code` and follow the instructions to authenticate with your Azure account. Make sure you have access to the subscription where the HPC Lab resources are located.
# 3. Run this script with `.\scripts\stop-hpc-lab.ps1`

az vm deallocate --resource-group HPC_Lab --name hpc-login-ctl
az vm deallocate --resource-group HPC_Lab --name hpc-compute-01
az vm deallocate --resource-group HPC_Lab --name hpc-compute-02

az vm list --resource-group HPC_Lab --show-details --output table