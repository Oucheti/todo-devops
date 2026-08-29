#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Désactiver les prompts needrestart (services à redémarrer)
if [ -d /etc/needrestart/conf.d ]; then
    echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/50-autorestart.conf
fi

set -euo pipefail

APT_OPTS=(-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

echo ">>> Configuration du réseau"

# Désactiver l'attente bloquante du réseau au démarrage
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true

# Détecter automatiquement les interfaces Ethernet
INTERFACES=$(ip -o link show | awk -F': ' '$2 !~ /lo/ {print $2}' | cut -d'@' -f1)

echo "Interfaces détectées :"
echo "$INTERFACES"

# Créer une configuration Netplan DHCP pour toutes les interfaces Ethernet
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

echo ">>> Netplan configuré :"
cat /etc/netplan/01-netcfg.yaml

netplan generate
netplan apply

sleep 5

echo ">>> Interfaces réseau après configuration"
ip addr

echo ">>> Routes"
ip route

echo ">>> Test Internet"

# Attendre que la route par défaut soit disponible
for i in {1..12}; do
    if ip route | grep -q "^default"; then
        echo "Route par défaut détectée."
        break
    fi

    echo "Attente de la route réseau... ($i/12)"
    sleep 2
done

# Test IP
if ping -c 3 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo ">>> Internet OK : ping 8.8.8.8 réussi."
else
    echo "ERREUR : impossible d'atteindre Internet."
    ip addr
    ip route
    exit 1
fi

# Test DNS
if ping -c 3 -W 3 google.com >/dev/null 2>&1; then
    echo ">>> DNS OK : google.com accessible."
else
    echo "ATTENTION : Internet fonctionne mais le DNS semble incorrect."
fi


echo ">>> Mise à jour du système"

apt-get update -y
apt-get "${APT_OPTS[@]}" upgrade -y


echo ">>> Installation des prérequis"

apt-get install -y "${APT_OPTS[@]}" \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git


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

usermod -aG docker vagrant || true

systemctl enable docker
systemctl start docker


echo ">>> Installation de Java"

apt-get install -y "${APT_OPTS[@]}" openjdk-17-jre


echo ">>> Installation de Jenkins"

echo ">>> Nettoyage des anciennes clés/dépôts Jenkins éventuels"

rm -f /usr/share/keyrings/jenkins-keyring.asc \
      /usr/share/keyrings/jenkins-keyring.gpg \
      /etc/apt/sources.list.d/jenkins.list

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo ">>> Empreinte de la clé Jenkins importée :"
gpg --no-default-keyring --keyring /usr/share/keyrings/jenkins-keyring.gpg --list-keys

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
    | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y

apt-get install -y "${APT_OPTS[@]}" jenkins

systemctl enable jenkins
systemctl start jenkins


echo ">>> Jenkins installé"

sleep 15

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo ""
    echo "=========================================="
    echo "      MOT DE PASSE INITIAL JENKINS"
    echo "=========================================="
    cat /var/lib/jenkins/secrets/initialAdminPassword
    echo "=========================================="
    echo ""
else
    echo "Mot de passe Jenkins pas encore disponible."
    echo "Vérifiez avec :"
    echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

echo ">>> Provisioning Jenkins terminé."