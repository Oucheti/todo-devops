#  TODO DevOps — Déploiement automatisé d'une application de gestion des tâches

##  Description du projet

Ce projet consiste à mettre en place une chaîne DevOps complète pour une application web de gestion de tâches de type **TODO List**.

L'objectif est d'automatiser :

* le provisionnement de l'infrastructure ;
* la préparation des machines virtuelles ;
* la conteneurisation de l'application avec Docker ;
* l'exécution des tests unitaires ;
* la construction et la publication de l'image Docker ;
* le déploiement automatique sur Kubernetes ;
* la gestion du code source avec Git ;
* l'intégration continue et le déploiement continu avec Jenkins.

---

#  Architecture du projet

L'architecture globale est la suivante :

```text
                         ┌─────────────────────┐
                         │      GitHub/GitLab   │
                         │                     │
                         │  Source Application │
                         └──────────┬──────────┘
                                    │
                                  Push
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │       Jenkins       │
                         │      jenkins-vm     │
                         │                     │
                         │  Checkout           │
                         │  Tests              │
                         │  Docker Build       │
                         │  Docker Push        │
                         │  kubectl deploy     │
                         └──────────┬──────────┘
                                    │
                              Docker Image
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │     Docker Hub      │
                         │                     │
                         │   todo-app:latest  │
                         └──────────┬──────────┘
                                    │
                                    │ Pull
                                    ▼
                  ┌──────────────────────────────────┐
                  │          Kubernetes              │
                  │             k8s-vm                │
                  │                                  │
                  │  ┌────────────────────────────┐  │
                  │  │       TODO Application     │  │
                  │  │        Node.js/Express     │  │
                  │  │                            │  │
                  │  │        2 replicas           │  │
                  │  └─────────────┬──────────────┘  │
                  │                │                 │
                  │                ▼                 │
                  │  ┌────────────────────────────┐  │
                  │  │        PostgreSQL           │  │
                  │  │                            │  │
                  │  │        Persistent PVC       │  │
                  │  └────────────────────────────┘  │
                  │                                  │
                  └──────────────────────────────────┘
```

---

#  Objectifs pédagogiques

Ce projet permet de mettre en pratique les concepts suivants :

* Infrastructure as Code (IaC)
* Terraform
* VirtualBox
* Linux / Ubuntu
* Docker
* Docker Hub
* Git / GitHub ou GitLab
* Jenkins
* CI/CD
* Kubernetes
* `kubectl`
* PostgreSQL
* Persistent Volume / Persistent Volume Claim
* Kubernetes Secrets
* automatisation du déploiement

---

#  Structure du projet

```text
todo-devops/
│
├── README.md
├── .gitignore
├── Dockerfile
├── .dockerignore
├── Jenkinsfile
│
├── package.json
├── package-lock.json
│
├── src/
│   ├── app.js
│   ├── routes/
│   ├── controllers/
│   └── database/
│
├── tests/
│   └── app.test.js
│
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── db-deployment.yaml
│   ├── db-pvc.yaml
│   └── secret.yaml
│
└── infrastructure/
    │
    └── terraform/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        │
        └── scripts/
            ├── common.sh
            ├── jenkins.sh
            └── kubernetes.sh
```

---

#  1. Prérequis

## Machine hôte

Le projet utilise une machine Windows avec :

* Windows 10/11 ;
* VirtualBox ;
* Terraform ;
* connexion Internet ;
* Git.

Versions utilisées pendant le projet :

```text
VirtualBox : 7.2.x
Terraform  : 1.15.x
```

Les machines virtuelles utilisent Ubuntu 22.04.

---

#  2. Infrastructure

L'infrastructure contient deux machines virtuelles.

| VM           | Rôle       | Services                                                 |
| ------------ | ---------- | -------------------------------------------------------- |
| `jenkins-vm` | CI/CD      | Jenkins, Docker, Git, Java                               |
| `k8s-vm`     | Kubernetes | kubeadm, kubelet, kubectl, Docker/containerd, PostgreSQL |

L'infrastructure est provisionnée avec Terraform et VirtualBox.

---

#  3. Terraform

## Initialisation

Depuis :

```powershell
cd infrastructure\terraform
```

Initialiser Terraform :

```powershell
terraform init
```

Vérifier la configuration :

```powershell
terraform validate
```

Formater les fichiers :

```powershell
terraform fmt
```

Afficher le plan :

```powershell
terraform plan
```

Créer l'infrastructure :

```powershell
terraform apply
```

Confirmer avec :

```text
yes
```

---

#  4. Vérification des machines virtuelles

Vérifier les VMs VirtualBox :

```powershell
VBoxManage list vms
```

Vérifier les VMs en fonctionnement :

```powershell
VBoxManage list runningvms
```

Les deux machines doivent être présentes :

```text
jenkins-vm
k8s-vm
```

---

#  5. Connexion SSH

## Jenkins

Exemple :

```powershell
ssh -i ".\scripts\.ssh\vagrant_insecure" `
    -o IdentitiesOnly=yes `
    vagrant@192.168.56.113
```

L'adresse IP peut être différente selon la configuration.

## Kubernetes

Exemple :

```powershell
ssh -i ".\scripts\.ssh\vagrant_insecure" `
    -o IdentitiesOnly=yes `
    vagrant@192.168.56.114
```

---

#  6. Vérification Docker

Sur `jenkins-vm` :

```bash
docker --version
```

Puis :

```bash
sudo systemctl status docker --no-pager
```

Tester Docker :

```bash
docker run --rm hello-world
```

Si le message suivant apparaît :

```text
Hello from Docker!
```

Docker fonctionne correctement.

---

#  7. Vérification Kubernetes

Sur `k8s-vm` :

```bash
kubectl version --client
```

Vérifier le cluster :

```bash
kubectl cluster-info
```

Vérifier les nœuds :

```bash
kubectl get nodes
```

Résultat attendu :

```text
NAME     STATUS   ROLES           AGE
k8s-vm   Ready    control-plane   ...
```

Vérifier les composants :

```bash
kubectl get pods -A
```

---

#  8. Communication Jenkins → Kubernetes

Jenkins doit pouvoir utiliser `kubectl` pour communiquer avec le cluster Kubernetes.

Depuis `jenkins-vm` :

```bash
sudo -u jenkins kubectl get nodes
```

Résultat attendu :

```text
NAME     STATUS   ROLES           AGE
k8s-vm   Ready    control-plane   ...
```

Cette étape est indispensable avant d'exécuter le pipeline CI/CD.

---

#  9. Application Web

L'application est une application web de gestion de tâches développée avec :

```text
Node.js
Express
PostgreSQL
```

Elle permet de gérer des tâches TODO.

Fonctionnalités principales :

* création d'une tâche ;
* consultation des tâches ;
* modification d'une tâche ;
* suppression d'une tâche ;
* connexion à PostgreSQL.

---

#  10. Installation de l'application

Cloner le dépôt :

```bash
git clone https://github.com/Oucheti/todo-devops.git
```

Entrer dans le projet :

```bash
cd todo-devops
```

Installer les dépendances :

```bash
npm install
```

---

#  11. Tests unitaires

Exécuter les tests :

```bash
npm test
```

Les tests permettent de vérifier le comportement de base de l'application.

Avant chaque build Docker, les tests doivent être exécutés.

---

#  12. Docker

## Construction de l'image

Depuis la racine du projet :

```bash
docker build -t USERNAME/todo-app:latest .
```

Vérifier l'image :

```bash
docker images
```

---

#  13. Exécution avec Docker

Lancer l'application :

```bash
docker run --rm \
  -p 3000:3000 \
  USERNAME/todo-app:latest
```

L'application est accessible sur :

```text
http://localhost:3000
```

---

#  14. Docker Hub

L'image Docker est publiée sur Docker Hub.

Connexion :

```bash
docker login
```

Construire :

```bash
docker build -t USERNAME/todo-app:latest .
```

Publier :

```bash
docker push USERNAME/todo-app:latest
```

Le repository Docker Hub doit avoir une structure similaire à :

```text
USERNAME/todo-app
```

---

# 15. Déploiement Kubernetes

Les manifests Kubernetes se trouvent dans :

```text
k8s/
```

Ils comprennent :

```text
deployment.yaml
service.yaml
db-deployment.yaml
db-pvc.yaml
secret.yaml
```

---

# 16. Secret PostgreSQL

Le fichier `secret.yaml` contient les informations nécessaires à PostgreSQL :

```text
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
```

 Les vrais mots de passe ne doivent pas être publiés dans un dépôt Git public.

Pour un environnement réel, utiliser une solution de gestion des secrets adaptée.

---

# 17. Persistance PostgreSQL

PostgreSQL utilise un :

```text
PersistentVolumeClaim
```

pour conserver les données même si le pod PostgreSQL est recréé.

Vérifier le PVC :

```bash
kubectl get pvc
```

Résultat attendu :

```text
NAME            STATUS   VOLUME   CAPACITY
postgres-pvc    Bound             2Gi
```

---

# 18. Déploiement manuel

Avant de mettre en place Jenkins, il est possible de tester le déploiement manuellement.

Depuis `k8s-vm` :

```bash
kubectl apply -f k8s/secret.yaml
```

Puis :

```bash
kubectl apply -f k8s/db-pvc.yaml
```

Puis :

```bash
kubectl apply -f k8s/db-deployment.yaml
```

Puis :

```bash
kubectl apply -f k8s/deployment.yaml
```

Enfin :

```bash
kubectl apply -f k8s/service.yaml
```

Ou simplement :

```bash
kubectl apply -f k8s/
```

---

# 19. Vérification du déploiement

Vérifier les pods :

```bash
kubectl get pods
```

Vérifier les deployments :

```bash
kubectl get deployments
```

Vérifier les services :

```bash
kubectl get services
```

Vérifier PostgreSQL :

```bash
kubectl get pods -l app=postgres
```

---

# 20. Accès à l'application

Identifier le NodePort :

```bash
kubectl get svc todo-app
```

Exemple :

```text
NAME       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
todo-app   NodePort   10.96.120.10    <none>        3000:30080/TCP
```

L'application sera accessible avec :

```text
http://IP_K8S_VM:30080
```

---

# 21. Pipeline CI/CD Jenkins

Le fichier :

```text
Jenkinsfile
```

définit automatiquement les étapes suivantes :

```text
Checkout
   ↓
Install dependencies
   ↓
Unit tests
   ↓
Docker build
   ↓
Docker push
   ↓
Kubernetes deployment
```

---

# 22. Configuration Jenkins

Dans Jenkins :

```text
Manage Jenkins
    ↓
Credentials
    ↓
Global credentials
    ↓
Add Credentials
```

Créer un credential Docker Hub :

```text
Kind : Username with password
ID   : dockerhub-credentials
```

Utiliser un **Docker Hub Access Token** plutôt que le mot de passe du compte.

---

# 23. Configuration Kubernetes dans Jenkins

Jenkins doit disposer d'un kubeconfig permettant d'accéder au cluster.

Vérifier depuis la VM Jenkins :

```bash
sudo -u jenkins kubectl get nodes
```

Si cette commande fonctionne, Jenkins pourra exécuter :

```bash
kubectl apply -f k8s/
```

et :

```bash
kubectl rollout status deployment/todo-app
```

---

# 24. Fonctionnement du pipeline

Lorsqu'un développeur pousse du code :

```text
git push
     │
     ▼
GitHub/GitLab
     │
     ▼
Jenkins
     │
     ├── Checkout
     │
     ├── npm ci
     │
     ├── npm test
     │
     ├── docker build
     │
     ├── docker push
     │
     └── kubectl deploy
             │
             ▼
        Kubernetes
```

---

# 25. Gestion des branches Git

Le projet utilise deux branches principales :

```text
main
dev
```

## Branche dev

La branche `dev` est utilisée pour le développement :

```bash
git checkout dev
```

Créer une branche de fonctionnalité :

```bash
git checkout -b feature/add-task
```

Après les modifications :

```bash
git add .
git commit -m "feat: add task functionality"
git push -u origin feature/add-task
```

---

# 26. Pull Request

Une Pull Request est créée :

```text
feature/add-task
        ↓
       dev
```

Après validation et tests :

```text
dev
 ↓
Pull Request
 ↓
main
```

La branche `main` représente la version stable.

---

# 27. .gitignore

Les fichiers suivants ne doivent pas être versionnés :

```text
node_modules/
.env
coverage/
*.log
.terraform/
terraform.tfstate
terraform.tfstate.*
crash.log
.vagrant/
```

Les credentials et secrets réels ne doivent jamais être commités.

---

# 28. Commandes utiles

## Git

```bash
git status
git branch
git pull
git add .
git commit -m "message"
git push
```

## Docker

```bash
docker images
docker ps
docker build -t todo-app .
docker run -p 3000:3000 todo-app
docker login
docker push USERNAME/todo-app:latest
```

## Kubernetes

```bash
kubectl get nodes
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get pvc
kubectl get secrets
kubectl logs POD_NAME
kubectl describe pod POD_NAME
```

Redémarrer un deployment :

```bash
kubectl rollout restart deployment/todo-app
```

Vérifier le déploiement :

```bash
kubectl rollout status deployment/todo-app
```

---

# 29. Suppression de l'infrastructure

Pour supprimer les ressources Terraform :

```powershell
cd infrastructure\terraform
terraform destroy
```

Confirmer :

```text
yes
```

⚠️ Cette commande supprime les ressources gérées par Terraform.

---

#  30. Scénario de démonstration

Pour présenter le projet, suivre ce scénario :

### Étape 1 — Modifier l'application

Modifier une fonctionnalité dans la branche :

```text
dev
```

### Étape 2 — Tester

```bash
npm test
```

### Étape 3 — Commit

```bash
git add .
git commit -m "feat: update todo application"
git push
```

### Étape 4 — Pull Request

Créer une Pull Request vers :

```text
main
```

### Étape 5 — Jenkins

Jenkins récupère le code :

```text
Checkout
```

Puis :

```text
Tests
```

Puis :

```text
Docker Build
```

Puis :

```text
Docker Push
```

Puis :

```text
Kubernetes Deploy
```

### Étape 6 — Vérification

Sur Kubernetes :

```bash
kubectl get pods
```

Puis :

```bash
kubectl get svc
```

Enfin accéder à l'application via le NodePort.

---

#  31. Livrables du projet

| Livrable                 | Statut |
| ------------------------ | ------ |
| Infrastructure Terraform | ok      |
| 2 VMs                    | ok      |
| Jenkins VM               | ok      |
| Kubernetes VM            | ok      |
| Docker                   | ok      |
| Git                      | ok      |
| Application TODO         | ok      |
| Dockerfile               | ok      |
| Tests unitaires          | ok      |
| Jenkinsfile              | ok     |
| Docker Hub               | ok     |
| Kubernetes manifests     | ok     |
| PostgreSQL + PVC         | ok     |
| Secret Kubernetes        | ok     |
| Pipeline CI/CD           | ok     |
| Branches main/dev        | ok     |
| Pull Request             | ok     |
| Documentation README     | ok      |

---

# 🎓 Conclusion

Ce projet met en œuvre une chaîne DevOps complète :

```text
              DEVELOPMENT
                   │
                   ▼
             Git / GitHub
                   │
                   ▼
                Jenkins
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
      Tests      Docker    Deployment
                   │          │
                   ▼          ▼
               Docker Hub  Kubernetes
                              │
                     ┌────────┴────────┐
                     ▼                 ▼
                 TODO App          PostgreSQL
                                       │
                                       ▼
                                      PVC
```

L'objectif final est d'obtenir un déploiement reproductible et automatisé de l'application, depuis le commit Git jusqu'à son exécution sur Kubernetes.
