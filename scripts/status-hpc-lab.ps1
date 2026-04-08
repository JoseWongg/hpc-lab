# Show overall VM state, IPs, and key resources for the HPC lab

# To run:
# 1. Open PowerShell
# 2. Connect to Azure with `az login`. To connect type `az login --use-device-code` and follow the instructions to authenticate with your Azure account. Make sure you have access to the subscription where the HPC Lab resources are located.
# 3. Run this script with `.\scripts\status-hpc-lab.ps1`


Write-Host "=== VM STATUS ===" -ForegroundColor Cyan
az vm list --resource-group HPC_Lab --show-details --output table

Write-Host "`n=== PUBLIC IP ===" -ForegroundColor Cyan
az network public-ip list --resource-group HPC_Lab --output table

Write-Host "`n=== NICs ===" -ForegroundColor Cyan
az network nic list --resource-group HPC_Lab --output table

Write-Host "`n=== DATA DISKS (controller) ===" -ForegroundColor Cyan
az vm show --resource-group HPC_Lab --name hpc-login-ctl --query "storageProfile.dataDisks[].name" --output table