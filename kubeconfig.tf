# Copyright 2017, 2019, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "oci_containerengine_cluster_kube_config" "kube_config" {
  cluster_id = oci_containerengine_cluster.oke-cluster.id
}

resource "null_resource" "create_local_kubeconfig" {
  provisioner "local-exec" {
    command = "rm -rf generated"
  }

  provisioner "local-exec" {
    command = "mkdir generated"
  }

  provisioner "local-exec" {
    command = "touch generated/kubeconfig"
  }
}

resource "local_file" "kube_config_file" {
  content         = data.oci_containerengine_cluster_kube_config.kube_config.content
  depends_on      = [null_resource.create_local_kubeconfig, oci_containerengine_cluster.oke-cluster]
  filename        = "${path.root}/generated/kubeconfig"
  file_permission = "0600"
}

data "template_file" "generate_kubeconfig" {
  template = file("${path.module}/scripts/generate_kubeconfig.template.sh")

  vars = {
    cluster-id = oci_containerengine_cluster.oke-cluster.id
    region     = var.region
  }

}

data "template_file" "token_helper" {
  template = file("${path.module}/scripts/token_helper.template.sh")

  vars = {
    cluster-id = oci_containerengine_cluster.oke-cluster.id
    region     = var.region
  }

}

data "template_file" "set_credentials" {
  template = file("${path.module}/scripts/kubeconfig_set_credentials.template.sh")

  vars = {
    cluster-id    = oci_containerengine_cluster.oke-cluster.id
    cluster-id-11 = substr(oci_containerengine_cluster.oke-cluster.id, (length(oci_containerengine_cluster.oke-cluster.id) - 11), length(oci_containerengine_cluster.oke-cluster.id))
    region        = var.region
  }

}

resource "null_resource" "write_kubeconfig_on_operator" {
  connection {
    host        = oci_core_instance.operator.public_ip
    private_key = file(var.operator_ssh_private_key_path)
    timeout     = "40m"
    type        = "ssh"
    user        = "opc"
  }

  // depends_on = [oci_containerengine_cluster.oke-cluster, null_resource.install_kubectl_operator, oci_identity_policy.operator_instance_principal]

  provisioner "file" {
    content     = data.template_file.generate_kubeconfig.rendered
    destination = "~/generate_kubeconfig.sh"
  }

  provisioner "file" {
    content     = data.template_file.token_helper.rendered
    destination = "~/token_helper.sh"
  }

  provisioner "file" {
    content     = data.template_file.set_credentials.rendered
    destination = "~/kubeconfig_set_credentials.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/generate_kubeconfig.sh",
      "$HOME/generate_kubeconfig.sh",
      "chmod +x $HOME/token_helper.sh",
      "sudo mv $HOME/token_helper.sh /usr/local/bin",
      "chmod +x $HOME/kubeconfig_set_credentials.sh",
      "$HOME/kubeconfig_set_credentials.sh",
      "rm -f $HOME/generate_kubeconfig.sh",
      "rm -f $HOME/kubeconfig_set_credentials.sh"
    ]
  }

}
