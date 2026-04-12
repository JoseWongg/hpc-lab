# Use after stopping/deallocating the HPC lab to restart the VMs and restore the scratch directories on the compute nodes.

# Start all lab VMs again and restore the non-persistent scratch directories on the compute nodes.
# Use after stopping/deallocating the HPC lab to restart the VMs and restore the scratch directories on the compute nodes.
#
# What this script does:
# 1. Starts the controller VM.
# 2. Starts both compute-node VMs.
# 3. Refreshes the controller public IP.
# 4. Waits until SSH to the controller is ready.
# 5. Recreates /scratch on both compute nodes because /mnt is Azure temporary local storage
#    and may be cleared after stop/deallocate.
# 6. Verifies the scratch layout on both compute nodes before finishing.
#
# What this script does not rebuild:
# - Slurm installation
# - MUNGE configuration
# - firewall rules
# - slurm.conf
#
# Those parts live on persistent storage and should still be present after restart.
#
# How to run:
# 1. Open PowerShell.
# 2. Authenticate to Azure:
#    az login --use-device-code
# 3. Run the script:
#    .\scripts\start-hpc-lab.ps1

# Stop the PowerShell script immediately if any command fails.
$ErrorActionPreference = "Stop"

# Store the path to the external SSH key used from Windows to reach the controller.
$ExternalKey = "$env:USERPROFILE\.ssh\id_ed25519"

# Start the controller VM.
az vm start --resource-group HPC_Lab --name hpc-login-ctl

# Start compute node 1.
az vm start --resource-group HPC_Lab --name hpc-compute-01

# Start compute node 2.
az vm start --resource-group HPC_Lab --name hpc-compute-02

# Show the current state of all lab VMs after issuing the start commands.
az vm list --resource-group HPC_Lab --show-details --output table

# Refresh the controller public IP after startup.
$CTL_IP = az vm show --resource-group HPC_Lab --name hpc-login-ctl --show-details --query publicIps --output tsv

# Display the controller public IP so you can see which address the script will use.
$CTL_IP

# Try SSH to the controller repeatedly until it responds.
for ($i = 1; $i -le 24; $i++) {
    try {
        ssh -o BatchMode=yes -o ConnectTimeout=5 -i $ExternalKey azureuser@$CTL_IP "echo controller-ssh-ready"
        break
    }
    catch {
        if ($i -eq 24) {
            throw "Controller SSH did not become ready in time."
        }

        Start-Sleep -Seconds 10
    }
}


# Try internal SSH to compute node 1 repeatedly until it responds.
for ($i = 1; $i -le 24; $i++) {
    ssh -i $ExternalKey azureuser@$CTL_IP "ssh -o BatchMode=yes -o ConnectTimeout=5 -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 'echo compute01-ssh-ready'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        break
    }

    if ($i -eq 24) {
        throw "Compute node 1 SSH did not become ready in time."
    }

    Start-Sleep -Seconds 10
}


# Try internal SSH to compute node 2 repeatedly until it responds.
for ($i = 1; $i -le 24; $i++) {
    ssh -i $ExternalKey azureuser@$CTL_IP "ssh -o BatchMode=yes -o ConnectTimeout=5 -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 'echo compute02-ssh-ready'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        break
    }

    if ($i -eq 24) {
        throw "Compute node 2 SSH did not become ready in time."
    }

    Start-Sleep -Seconds 10
}



# Restore /scratch on compute node 1 through the controller.
ssh -i $ExternalKey azureuser@$CTL_IP "ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 'sudo mkdir -p /mnt/local_scratch && sudo chown root:root /mnt/local_scratch && sudo chmod 1777 /mnt/local_scratch && sudo rm -rf /scratch && sudo ln -sfn /mnt/local_scratch /scratch && mkdir -p /scratch/azureuser && chmod 700 /scratch/azureuser'"

# Verify /scratch on compute node 1 through the controller.
ssh -i $ExternalKey azureuser@$CTL_IP "ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 'ls -ld /mnt/local_scratch /scratch /scratch/azureuser && df -h /scratch'"

# Restore /scratch on compute node 2 through the controller.
ssh -i $ExternalKey azureuser@$CTL_IP "ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 'sudo mkdir -p /mnt/local_scratch && sudo chown root:root /mnt/local_scratch && sudo chmod 1777 /mnt/local_scratch && sudo rm -rf /scratch && sudo ln -sfn /mnt/local_scratch /scratch && mkdir -p /scratch/azureuser && chmod 700 /scratch/azureuser'"

# Verify /scratch on compute node 2 through the controller.
ssh -i $ExternalKey azureuser@$CTL_IP "ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 'ls -ld /mnt/local_scratch /scratch /scratch/azureuser && df -h /scratch'"