#!/usr/bin/env bash
set -euo pipefail

echo "[+] Installing k3s"
curl -sfL https://get.k3s.io | sh -

echo "[+] Stopping any existing k3s processes"
sudo pkill -9 k3s 2>/dev/null || true
sleep 2

echo "[+] Cleaning previous k3s state"
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /run/k3s

echo "[+] Writing k3s config (native snapshotter)"
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/config.yaml > /dev/null << 'EOF'
snapshotter: native
write-kubeconfig-mode: "644"
EOF

echo "[+] Starting k3s"
sudo k3s server > /tmp/k3s.log 2>&1 &

echo "[+] Waiting for k3s to become ready"
timeout=120
until grep -q "k3s is up and running" /tmp/k3s.log 2>/dev/null; do
  sleep 2
  timeout=$((timeout - 2))
  if [ "$timeout" -le 0 ]; then
    echo "[!] k3s failed to start"
    tail -50 /tmp/k3s.log
    exit 1
  fi
done

echo "[+] Exporting KUBECONFIG"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
if ! grep -q KUBECONFIG ~/.bashrc 2>/dev/null; then
  echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
fi

echo "[+] Verifying node status"
sudo k3s kubectl get nodes

echo "[+] Verifying system pods"
sudo k3s kubectl get pods -A

echo "[✓] k3s bootstrap complete"
