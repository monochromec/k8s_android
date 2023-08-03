This file contains the recipe for setting up the project environment. You will need an Android device
with the following specs:

- Rooted device with recent AOSP installation (Android versions 11 and above)
- Quad/octa-core AARCH64 architecture (the more cores the better)
-   $\ge$ 4 GB main memory
-   $\ge$ 4 GB of available flash memory
- Linux/BSD host

**Bold text** means execute on the device in the Termux environment, _italics_ means execute inside the VM.

1. Install the Android SDK (for adb), Docker, curl, kubectl and Golang on your host machine
2. Configure adb for USB/wireless device access
3. Create a local container [image registry](https://docs.docker.com/registry/deploying) running on port 6000 on your host
4. Install Termux (from F-Droid! The PlayStore version has an outdated repo config.) and [setup storage](https://wiki.termux.com/wiki/Termux-setup-storage)
5. **Install & configure ssh in Termux**
6. Get [scrcpy](https://github.com/Genymobile/scrcpy) (you need adb for this)
7. **qemu installation**: qemu-utils qemu-common qemu-system-aarch64-headless & wget
8. **Download** [alpine iso](https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64) (go for *virt.iso => slimmed down kernel optimised for para-virtualisation only if your kernel supports this, otherwise choose *standard.iso) => storage/downloads
9. **Get an** [UEFI boot loader](https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd)
10. **Create disk**:  `qemu-img create -f qcow2 alpine.img 10G`
11. **Start installation VM**: `qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 2048M -smp 6 -nographic -bios QEMU_EFI.fd -drive format=raw,readonly=on,file=storage/downloads/alpine-virt-3.xx.x-aarch64.iso -drive file=alpine.img,media=disk,if=virtio -netdev user,id=n0,hostfwd=tcp::2222-:22,dns=1.1.1.1 -device virtio-net,netdev=n0`
12. _Create_ /etc/udhcpc/udhcpc.conf : `RESOLV_CONF="no"`
13. /etc/resolv.conf: two nameservers (must be able to resolve via UDP!)

    `nameserver 8.8.8.8`

    `nameserver 1.1.1.1`

14. _setup-alpine_:
    
    - AllowRoot login / no key generation

    - vdb disk: sys option
      
1.  **Run VM**:
   `qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 2048M -smp 6 -nographic -bios QEMU_EFI.fd -drive file=alpine.img,media=disk,if=virtio -netdev user,id=n0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8081-:8081,dns=1.1.1.1 -device virtio-net,netdev=n0`
2.  _Enable community repo and update package index_: `vi /etc/apk/repositories; apk update`
3.  _Install k3s dependencies_: `apk add k3s --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community`
4.  _Install curl & bash_
5.  _Delete k3s installed from repo & set links_: `rm /usr/bin/k3s; ln -s /usr/local/bin/k3s /usr/bin`
6.  _Update run-levels_: `rc-update add iptables / rc-update add containerd`
7.  _Update run-levels_: `rc-update del k3s`
8.  _Create empty iptables config_: `/etc/init.d/iptables save`
9.  _Reboot_
10. _Install k3s_: `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable-cloud-controller --disable traefik --disable metrics-server" | bash -s`
11. _Start services_: `service [iptables containerd k3s] start`
12. _Download_ [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux) (ARM64!) & `chmod +x kubectl` & move into /usr/local/bin
13. _Check if containers are running_: `ctr -n k8s.io containers list`
14. _Copy token to kubectl config_: `cp /etc/rancher/k3s/k3s.yaml ~/.kube/config`
15. _Check if control plane is OK_: `kubectl get all -n kube-system`
16. _Add gateway for host access in_ `/etc/hosts` (for local image registry access):
    
	  `10.0.2.2	host`

17. Using build.sh build the webserver container image and push to the local image registry
18. Setup host/android port connections (adb_fwd.sh)
19. `kubectl proxy --address=0.0.0.0` _for control plane access from the host via adb_
20. Setup your host's .kube/config to have an "android" section (or similar) pointing to the newly created cluster using the config created on the device earlier; using `server: http://127.0.0.1:8080` in the cluster definition to reflect the adb / proxy configuration
21. Deploy depl.yml and svc.yml to create deplyoment and service on device using the host's local kubectl command
22. Pre-flight check: `kubectl get all` should show the deployment with two pods and the service created and running
23. `kubectl port-forward --address=0.0.0.0 svc/miniserv-service 8081:8081` _for access to the service via adb_
24. `curl http://localhost:8081` on the host should now give a response back from a pod running inside the Android k8s deployment

Troubleshooting tips: 
- curl doesn't connect from the host: Can you access the service from the VM / inside Termux? If so, double-check your adb port config. If you
can access the service from within the VM but not from Termux, double-check your qemu invocation (the hostfwd part) and your `kubectl port-forward` invocation.
- kubectl from the host times out: Does an invocation of the same command work inside the VM? If so: Is the the host's .kube/config correct and pointing to the right instance? If not, check core utilisation in Termux using htop or similar tools (`su -` first, otherwise you will only see the utilisation of your sandbox). If most of the device's cores are running at maximum or the swap space is at a critical utilisation, use a device
with a more performant spec. or get used to waiting :-). Depending on your specific device specification, it may take a couple of minutes after you log into the VM for the k8s cluster to get operational and responsive.
