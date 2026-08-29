output "jenkins_ip" {
  value = virtualbox_vm.jenkins.network_adapter[1].ipv4_address
}

output "k8s_ip" {
  value = virtualbox_vm.kubernetes.network_adapter[1].ipv4_address
}
