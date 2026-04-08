# SSH into the controller VM using the current public IP

# This script retrieves the public IP address of the controller VM and initiates an SSH connection using the specified private key.

# How to run:
# 1. Open PowerShell
# 2. Connect to Azure with `az login`. To connect type `az login --use-device-code` and follow the instructions to authenticate with your Azure account. Make sure you have access to the subscription where the HPC Lab resources are located.
# 3. Run this script with `.\scripts\ssh-controller.ps1`

# Prompt will change to this format: [azureuser@hpc-login-ctl ~]$ 
# From here you can run commands on the controller VM, and from there you can SSH into the compute nodes if needed.

# Note: If you have not set up your SSH keys or if the private key is not located at the default path, you may need to modify the path to your private key in the ssh command.

# To exit the SSH session, simply type `exit` and press Enter.

$ip = az vm show --resource-group HPC_Lab --name hpc-login-ctl --show-details --query publicIps --output tsv
ssh -i $env:USERPROFILE\.ssh\id_ed25519 azureuser@$ip