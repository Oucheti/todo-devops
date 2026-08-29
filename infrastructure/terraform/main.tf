############################################
# VM 1 : Jenkins (CI/CD)
############################################
resource "virtualbox_vm" "jenkins" {
  name   = "jenkins-vm"
  image  = var.box_image
  cpus   = var.jenkins_cpus
  memory = var.jenkins_memory

  network_adapter {
    type                  = "nat"
    nat_dns_host_resolver = true
  }

  network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
  }
}

############################################
# VM 2 : Kubernetes (kubeadm) + PostgreSQL + NGINX
############################################
resource "virtualbox_vm" "kubernetes" {
  name   = "k8s-vm"
  image  = var.box_image
  cpus   = var.k8s_cpus
  memory = var.k8s_memory

  network_adapter {
    type                  = "nat"
    nat_dns_host_resolver = true
  }

  network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
  }
}

############################################
# Provisioning
############################################
resource "null_resource" "jenkins_provision" {
  depends_on = [virtualbox_vm.jenkins]

  triggers = {
    script_hash = filesha256("${path.module}/scripts/provision-jenkins.sh")
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}\\scripts\\wait-and-provision.ps1"
    environment = {
      VM_NAME     = "jenkins-vm"
      SCRIPT_PATH = "${path.module}/scripts/provision-jenkins.sh"
      SSH_USER    = var.ssh_user
    }
  }
}

resource "null_resource" "k8s_provision" {
  depends_on = [
    virtualbox_vm.kubernetes,
    null_resource.jenkins_provision
  ]

  triggers = {
    script_hash = filesha256("${path.module}/scripts/provision-k8s.sh")
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}\\scripts\\wait-and-provision.ps1"
    environment = {
      VM_NAME     = "k8s-vm"
      SCRIPT_PATH = "${path.module}/scripts/provision-k8s.sh"
      SSH_USER    = var.ssh_user
    }
  }
}
