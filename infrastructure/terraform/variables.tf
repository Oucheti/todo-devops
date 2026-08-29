variable "box_image" {
  description = "Image Vagrant/VirtualBox utilisée pour les VM (Ubuntu 22.04)"
  type        = string
  default     = "http://127.0.0.1:18080/virtualbox.box"
}

variable "jenkins_cpus" {
  type    = number
  default = 4
}

variable "jenkins_memory" {
  type    = string
  default = "4048mib"
}

variable "k8s_cpus" {
  type    = number
  default = 4
}

variable "k8s_memory" {
  type    = string
  default = "8096mib"
}

variable "ssh_user" {
  description = "Utilisateur SSH par défaut de la box Vagrant"
  type        = string
  default     = "vagrant"
}

variable "ssh_password" {
  description = "Mot de passe SSH par défaut de la box Vagrant (insecure key)"
  type        = string
  default     = "vagrant"
  sensitive   = true
}
