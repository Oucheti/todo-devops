terraform {
  required_version = ">= 1.5.0"

  required_providers {
    virtualbox = {
      source  = "eran132/vbox"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "virtualbox" {
  # Le provider communique avec VirtualBox via VBoxManage.
  # Assurez-vous que VBoxManage est bien dans le PATH Windows :
  # C:\Program Files\Oracle\VirtualBox\
}
