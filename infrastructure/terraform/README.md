# Infrastructure as Code — Terraform + VirtualBox (Windows 11)

Ce projet provisionne 2 VM locales via VirtualBox (provider `eran132/vbox`) :

| VM | Rôle | CPU | RAM |
|---|---|---|---|
| `jenkins-vm` | Jenkins (CI/CD), Docker, Git | 2 | 2 Go |
| `k8s-vm` | Kubernetes (kubeadm), Docker, PostgreSQL, NGINX | 2 | 4 Go |

## Prérequis sur votre PC Windows 11

1. **VirtualBox 7.2.8** installé, avec `VBoxManage.exe` accessible dans le PATH
   (normalement `C:\Program Files\Oracle\VirtualBox\`).
2. **Terraform 1.15.8** installé et dans le PATH.
3. Un **réseau Host-Only** créé dans VirtualBox :
   - Ouvrir VirtualBox → Fichier → Outils Réseau Hôte → Créer.
   - Vérifier le nom exact (ex. `VirtualBox Host-Only Ethernet Adapter`) et l'aligner
     avec `host_interface` dans `main.tf` si différent chez vous.
4. Connexion internet active (téléchargement de la box Vagrant Ubuntu 22.04
   au premier `terraform apply`, environ 500-800 Mo).

## Installation du provider (version 2.0.8)

Le fichier `versions.tf` épingle déjà la version 2.0.8. Depuis PowerShell,
dans le dossier du projet :

```powershell
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .terraform -ErrorAction SilentlyContinue
terraform init
```

Si l'erreur `provider binary not found` réapparaît même en 2.0.8, c'est que
cette version aussi n'a pas de binaire Windows publié sur le registre — dans
ce cas il faut installer le provider manuellement (voir section "Installation
manuelle" plus bas).

## Déploiement

```powershell
terraform plan
terraform apply
```

Terraform va :
1. Télécharger la box Ubuntu 22.04 et créer les 2 VM dans VirtualBox.
2. Se connecter en SSH à chaque VM (utilisateur `vagrant` / mot de passe `vagrant`
   par défaut sur les box génériques — à adapter si votre box utilise une clé SSH).
3. Copier et exécuter les scripts de provisioning (`scripts/provision-jenkins.sh`
   et `scripts/provision-k8s.sh`).

Les adresses IP des VM (interface host-only) sont affichées en sortie
(`jenkins_ip`, `k8s_ip`).

## Accès aux services après déploiement

- **Jenkins** : `http://<jenkins_ip>:8080` (mot de passe initial affiché dans
  les logs de provisioning, ou récupérable via
  `ssh vagrant@<jenkins_ip> sudo cat /var/lib/jenkins/secrets/initialAdminPassword`)
- **Kubernetes** : `ssh vagrant@<k8s_ip>` puis `kubectl get nodes`
- **PostgreSQL** (sur k8s-vm) : base `taskapp_db`, utilisateur `taskapp`
- **NGINX** (sur k8s-vm) : `http://<k8s_ip>` (page par défaut, à remplacer par
  votre configuration de reverse proxy vers l'app)

## Installation manuelle du provider (si le binaire Windows est absent du registre)

1. Aller sur https://github.com/eran132/terraform-provider-vbox/releases
2. Télécharger l'archive `windows_amd64` de la version souhaitée (si elle existe).
3. Extraire le binaire `.exe` dans :
   ```
   %APPDATA%\terraform.d\plugins\registry.terraform.io\eran132\vbox\<version>\windows_amd64\
   ```
4. Relancer `terraform init`.

## Nettoyage

```powershell
terraform destroy
```
