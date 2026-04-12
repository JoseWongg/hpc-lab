# Use after stopping/deallocating the HPC lab to restart the VMs and restore the scratch directories on the compute nodes.

# Start all lab VMs again and restore the non-persistent scratch directories on the compute nodes.
#
# What this script does:
# 1. Starts the controller VM.
# 2. Starts both compute-node VMs.
# 3. Refreshes the controller public IP.
# 4. Waits until SSH to the controller is ready.
# 5. Recreates /scratch on both compute nodes because /mnt is Azure temporary local storage
#    and may be cleared after stop/deallocate.
#
# This script does not rebuild:
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
# This avoids the script continuing after an error and making the restart look successful when it was not.
$ErrorActionPreference = "Stop"

# Store the path to the external SSH key used from Windows to reach the controller.
# This avoids repeating the same long path multiple times in this script.
$ExternalKey = "$env:USERPROFILE\.ssh\id_ed25519"

# Start the controller VM.
az vm start --resource-group HPC_Lab --name hpc-login-ctl

# Start compute node 1.
az vm start --resource-group HPC_Lab --name hpc-compute-01

# Start compute node 2.
az vm start --resource-group HPC_Lab --name hpc-compute-02

# Show the current state of all lab VMs after issuing the start commands.
# This gives a quick visual check that Azure is bringing the machines up.
az vm list --resource-group HPC_Lab --show-details --output table

# Refresh the controller public IP after startup.
# This is needed because the public IP may change after stop/deallocate.
$CTL_IP = az vm show --resource-group HPC_Lab --name hpc-login-ctl --show-details --query publicIps --output tsv

# Display the controller public IP.
$CTL_IP

# Wait a short moment before trying SSH.
# A VM can show as running before SSH is actually ready.
# Try SSH to the controller repeatedly until it responds.
# This is safer than assuming SSH is ready immediately after the VM starts.
for ($i = 1; $i -le 24; $i++) {
    try {
        # Test whether the controller is ready to accept SSH connections.
        # BatchMode=yes prevents password prompts and makes the test fail cleanly if SSH is not ready.
        ssh -o BatchMode=yes -o ConnectTimeout=5 -i $ExternalKey azureuser@$CTL_IP "echo controller-ssh-ready"
        break
    }
    catch {
        # If this was the last retry, stop the script with a clear error.
        if ($i -eq 24) {
            throw "Controller SSH did not become ready in time."
        }

        # Wait a little before trying SSH again.
        Start-Sleep -Seconds 10
    }
}

# Build the Linux command block that will run on the controller.
# We do it this way because the internal SSH key for reaching the compute nodes exists on the controller, not on Windows.
$ControllerRestoreScript = @'
# Recreate the scratch backing directory on compute node 1.
# Azure temporary storage under /mnt may be cleared after stop/deallocate, so this directory may need to be recreated.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "sudo mkdir -p /mnt/local_scratch"

# Set the correct owner on the scratch backing directory on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "sudo chown root:root /mnt/local_scratch"

# Set the correct shared-temporary permissions on the scratch backing directory on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "sudo chmod 1777 /mnt/local_scratch"

# Remove any stale /scratch path on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "sudo rm -rf /scratch"

# Recreate /scratch as a symlink to the node-local scratch backing directory on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "sudo ln -s /mnt/local_scratch /scratch"

# Recreate the per-user scratch directory on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "mkdir -p /scratch/azureuser"

# Restore private permissions on the per-user scratch directory on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "chmod 700 /scratch/azureuser"

# Show the real backing-directory permissions and the restored scratch paths on compute node 1.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "stat -c '%A %a %n' /mnt/local_scratch && ls -ld /scratch /scratch/azureuser"

# Recreate the scratch backing directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "sudo mkdir -p /mnt/local_scratch"

# Set the correct owner on the scratch backing directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "sudo chown root:root /mnt/local_scratch"

# Set the correct shared-temporary permissions on the scratch backing directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "sudo chmod 1777 /mnt/local_scratch"

# Remove any stale /scratch path on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "sudo rm -rf /scratch"

# Recreate /scratch as a symlink to the node-local scratch backing directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "sudo ln -s /mnt/local_scratch /scratch"

# Recreate the per-user scratch directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "mkdir -p /scratch/azureuser"

# Restore private permissions on the per-user scratch directory on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "chmod 700 /scratch/azureuser"

# Show the real backing-directory permissions and the restored scratch paths on compute node 2.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "stat -c '%A %a %n' /mnt/local_scratch && ls -ld /scratch /scratch/azureuser"

# Verify that /scratch resolves correctly on compute node 1 and is backed by /mnt again.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-01 "df -h /scratch && ls -ld /scratch /scratch/azureuser"

# Verify that /scratch resolves correctly on compute node 2 and is backed by /mnt again.
ssh -i ~/.ssh/id_ed25519_hpc_internal azureuser@hpc-compute-02 "df -h /scratch && ls -ld /scratch /scratch/azureuser"
'@

# Send the Linux restore commands to the controller and run them there.
# The controller then uses its internal SSH key to reach the compute nodes and rebuild /scratch on both of them.
$ControllerRestoreScript | ssh -i $ExternalKey azureuser@$CTL_IP "bash -s"