This file contains the recipe for setting up the project environment. You will need an Android device
with the following specs:

- Rooted device with recent AOSP installation (Android versions 11 and above)
- Quad/octa-core AARCH64 architecture (the more cores the better)
- >= 4 GB main memory
- >= 4 GB of available flash memory
- Linux/BSD host

1. Install Android SDK (for adb)
1. Install Termux (from F-Droid!)
1. Install & configure ssh in Termux
1. Get scrcpy (you need adb for this)
1. qemu installation: qemu-utils qemu-common qemu-system-aarch64-headless & wget
1. Download alpine iso: https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64 (go for *virt.iso => slimmed down kernel optimised for para-virtualisation only if your kernel supports this, otherwise choose *standard.iso) => storage/downloads
1. Get UEFI boot loader from https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd
1. Create storage: `termux-setup-storage` (either from via scrcpy or via ssh => grant storage permission first)
1. Create disk:  `qemu-img create -f qcow2 alpine.img 10G`
1. Start installation VM: `qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 2048M -smp 6 -nographic -bios QEMU_EFI.fd -drive format=raw,readonly=on,file=storage/downloads/alpine-virt-3.xx.x-aarch64.iso -drive file=alpine.img,media=disk,if=virtio -netdev user,id=n0,hostfwd=tcp::2222-:22,dns=1.1.1.1 -device virtio-net,netdev=n0`
1. Create /etc/udhcpc/udhcpc.conf : `RESOLV_CONF="no"`
1. /etc/resolv.conf: two nameservers (must be able to resolve via UDP!)

    `nameserver 8.8.8.8`

    `nameserver 1.1.1.1`

1. setup-alpine:
    - AllowRoot login / no key generation
    - vdb disk: sys option
  
2. Run VM: 
   `qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 2048M -smp 6 -nographic -bios QEMU_EFI.fd -drive file=alpine.img,media=disk,if=virtio -netdev user,id=n0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8081-:8081,dns=1.1.1.1 -device virtio-net,netdev=n0`
3. Enable community repo and update package index: vi /etc/apk/repositories; apk update
4. Install k3s dependencies: apk add k3s --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
5. Install curl, bash
6. Delete k3s installed from repo & set links: `rm /usr/bin/k3s; ln -s /usr/local/bin/k3s /usr/bin`
7. Update run-levels: `rc-update add iptables / rc-update add containerd`
8. Update run-levels: `rc-update del k3s`
9.  Create empty iptables config: `/etc/init.d/iptables save`
10. Reboot
11. Install k3s: `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable-cloud-controller --disable traefik --disable metrics-server" | bash -s`
12. Start services: `service [iptables containerd] k3s start`
13. Download kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux (ARM64!) & `chmod +x kubectl` moev into /usr/local/bin
14. Check if containers are running: `ctr -n k8s.io containers list`
15. Copy token to kubectl config: `cp /etc/rancher/k3s/k3s.yaml ~/.kube/config``
16. Check if control plane is OK: `kubectl get all -n kube-system`
17. Add gateway for host access in `/etc/hosts`:
    
	  `10.0.2.2	host`