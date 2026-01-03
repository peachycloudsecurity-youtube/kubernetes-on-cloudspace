#!/usr/bin/env bash
set -euo pipefail

echo "[+] Stopping k3s processes"
sudo pkill -9 k3s 2>/dev/null || true
sleep 2

echo "[+] Unmounting k3s/containerd mounts"
mount | grep '/run/k3s' | awk '{print $3}' | sort -r | while read -r m; do
  sudo umount -lf "$m" 2>/dev/null || true
done

echo "[+] Removing k3s runtime and state directories"
sudo rm -rf /run/k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s

echo "[+] Cleaning kubeconfig exports"
sed -i '/KUBECONFIG=\/etc\/rancher\/k3s\/k3s.yaml/d' ~/.bashrc || true

echo "[+] Cleaning kubectl cache"
rm -rf ~/.kube/cache || true

echo "[+] Verifying no k3s mounts remain"
if mount | grep -q '/run/k3s'; then
  echo "[!] Warning: some k3s mounts still exist"
  mount | grep '/run/k3s'
else
  echo "[✓] All k3s mounts cleaned"
fi

echo "[✓] k3s cleanup completed successfully"
