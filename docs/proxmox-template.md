# Proxmox VM Template

1. Download a cloud-init image into your Proxmox environment. You may do this
   from the Proxmox UI at Local > ISO Images > Download from URL. The following
   instructions assume the image is in the default ISO storage location at
   `/var/lib/vz/template/iso`.

2. Create a new VM following the usual steps, but be sure to apply the
   following settings:

   - **General**: Recommended to set a high VM ID to avoid the template getting
     mixed in with the rest of your VMs
   - **OS**: Select "Do not use any media"
   - **System**: Select "Qemu Agent"
   - **Disks**: Delete all disks from the side menu
   - **CPU/Memory/Network**: Choose reasonable defaults for your use case. You
     can adjust these later

3. Open a shell for the Proxmox node containing your VM. Attach the image as a
   disk to the VM with the following command:

   ```sh
   qm disk import <vm-id> <path-to-image> <storage-name> --format qcow2
   ```

   For example:

   ```sh
   qm disk import 9000 /var/lib/vz/template/iso/noble-server-cloudimg-amd64.img local-lvm --format qcow2
   ```

4. It's important to have `qemu-guest-agent` installed in the VMs so that
   Terraform can report IP addresses. Create a custom cloud-init configuration
   in the Proxmox local storage using the following commands:

   ```sh
   mkdir -p /var/lib/vz/snippets
   tee /var/lib/vz/snippets/qemu-guest-agent.yml <<EOF
   #cloud-config
   runcmd:
     - apt update
     - apt install -y qemu-guest-agent
     - systemctl start qemu-guest-agent
   EOF
   ```

   The Terraform scripts apply this custom configuration to clones created from
   the template.

5. Go to your VM's hardware settings in the Proxmox UI. Edit the newly attached
   disk, adding it as `scsi0`. If you are using an SSD, consider checking the
   "Discard" and "SSD emulation" options.

6. Add a cloud-init drive to your VM at `ide0`. Under the "Cloud-Init" settings,
   apply your desired setup and select "Regenerate Image."

7. Under Options > Boot Order, make sure `scsi0` is first the in priority and
   deselect any other devices.

8. Finally, right click your VM and select "Convert to template." Terraform
   scripts can now use this template to provision VMs.
