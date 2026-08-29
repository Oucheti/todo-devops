#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

# Désactiver les prompts needrestart (services à redémarrer)
if [ -d /etc/needrestart/conf.d ]; then
    echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/50-autorestart.conf
fi

set -euo pipefail

APT_OPTS=(-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

########################################
# RÉSEAU
########################################

echo ">>> Configuration du réseau"

systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true

# Détecter automatiquement les interfaces Ethernet
INTERFACES=$(ip -o link show | awk -F': ' '$2 !~ /lo/ {print $2}' | cut -d'@' -f1)

echo "Interfaces détectées :"
echo "$INTERFACES"

# Configuration DHCP automatique
cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
EOF

for IFACE in $INTERFACES; do
cat >> /etc/netplan/01-netcfg.yaml <<EOF
    $IFACE:
      dhcp4: true
      optional: true
EOF
done

chmod 600 /etc/netplan/01-netcfg.yaml

echo ">>> Configuration Netplan :"
cat /etc/netplan/01-netcfg.yaml

netplan generate
netplan apply

sleep 5

echo ">>> Interfaces réseau"
ip addr

echo ">>> Routes"
ip route

########################################
# TEST INTERNET
########################################

echo ">>> Test de la connexion Internet"

for i in {1..12}; do
    if ip route | grep -q "^default"; then
        echo ">>> Route par défaut détectée."
        break
    fi

    echo "Attente de la route réseau... ($i/12)"
    sleep 2
done

if ! ping -c 3 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "ERREUR : la VM Kubernetes n'a pas accès à Internet."
    echo ">>> IP :"
    ip addr
    echo ">>> Routes :"
    ip route
    exit 1
fi

echo ">>> Internet OK"

if ping -c 3 -W 3 google.com >/dev/null 2>&1; then
    echo ">>> DNS OK"
else
    echo "ATTENTION : Internet fonctionne mais le DNS semble incorrect."
fi


########################################
# MISE À JOUR
########################################

echo ">>> Mise à jour du système"

apt-get update -y
apt-get "${APT_OPTS[@]}" upgrade -y


########################################
# PRÉREQUIS
########################################

echo ">>> Installation des prérequis"

apt-get install -y "${APT_OPTS[@]}" \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    apt-transport-https


########################################
# DOCKER
########################################

echo ">>> Installation de Docker"

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install -y "${APT_OPTS[@]}" \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable docker
systemctl start docker


########################################
# CONTAINERD / KUBERNETES
########################################

echo ">>> Configuration de containerd"

mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

# Kubernetes utilise systemd comme cgroup driver
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
    /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd


########################################
# DÉSACTIVATION DU SWAP
########################################

echo ">>> Désactivation du swap"

swapoff -a

sed -i '/[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab


########################################
# MODULES KERNEL
########################################

echo ">>> Configuration des modules kernel"

cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter


########################################
# SYSCTL KUBERNETES
########################################

echo ">>> Configuration sysctl"

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system


########################################
# INSTALLATION KUBEADM / KUBELET / KUBECTL
########################################

echo ">>> Installation de kubeadm/kubelet/kubectl"

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
    | gpg --dearmor \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' \
    | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

apt-get install -y "${APT_OPTS[@]}" \
    kubelet \
    kubeadm \
    kubectl

apt-mark hold kubelet kubeadm kubectl


########################################
# INITIALISATION KUBERNETES
########################################

echo ">>> Initialisation du cluster Kubernetes"

if [ ! -f /etc/kubernetes/admin.conf ]; then

    kubeadm init \
        --pod-network-cidr=10.244.0.0/16

else

    echo ">>> Kubernetes est déjà initialisé."

fi


########################################
# CONFIGURATION KUBECTL POUR VAGRANT
########################################

echo ">>> Configuration kubectl"

mkdir -p /home/vagrant/.kube

cp -f \
    /etc/kubernetes/admin.conf \
    /home/vagrant/.kube/config

chown -R vagrant:vagrant /home/vagrant/.kube

chmod 600 /home/vagrant/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf


########################################
# FLANNEL
########################################

echo ">>> Installation de Flannel"

kubectl \
    --kubeconfig=/etc/kubernetes/admin.conf \
    apply -f \
    https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml


########################################
# CONTROL-PLANE MONO-NŒUD
########################################

echo ">>> Autorisation du scheduling sur le control-plane"

kubectl \
    --kubeconfig=/etc/kubernetes/admin.conf \
    taint nodes --all \
    node-role.kubernetes.io/control-plane- \
    2>/dev/null || true


########################################
# POSTGRESQL
########################################

echo ">>> Installation de PostgreSQL"

apt-get install -y "${APT_OPTS[@]}" \
    postgresql \
    postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql \
    -c "CREATE USER taskapp WITH PASSWORD 'taskapp_pwd';" \
    2>/dev/null || true

sudo -u postgres psql \
    -c "CREATE DATABASE taskapp_db OWNER taskapp;" \
    2>/dev/null || true


########################################
# NGINX
########################################

echo ">>> Installation de NGINX"

apt-get install -y "${APT_OPTS[@]}" nginx

systemctl enable nginx
systemctl start nginx


########################################
# VÉRIFICATION KUBERNETES
########################################

echo ">>> Vérification du cluster"

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl get nodes || true

kubectl get pods -A || true


########################################
# FIN
########################################

echo ""
echo "=============================================="
echo " Provisioning Kubernetes terminé"
echo "=============================================="
echo ""
echo "Node :"
kubectl get nodes -o wide || true

echo ""
echo "Pods :"
kubectl get pods -A || true

echo ""
echo "IP de la VM :"
ip addr

echo ""
echo "Routes :"
ip route

echo ""