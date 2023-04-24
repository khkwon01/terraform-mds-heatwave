# apache and php

data "template_file" "install_webphp" {
  template = file("${path.module}/scripts/install_web_php_template.sh")

  vars = {
    user = "opc"
  }
}

resource null_resource "install_webphp" {
  connection {
    host        = oci_core_instance.operator.public_ip
    private_key = file(var.operator_ssh_private_key_path)
    timeout     = "40m"
    type        = "ssh"
    user        = "opc"

  }

  provisioner "file" {
    content     = data.template_file.install_webphp.rendered
    destination = "~/install_web_php_template.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/install_web_php_template.sh",
      "bash $HOME/install_web_php_template.sh",
      "rm -f $HOME/install_web_php_template.sh"
    ]
  }
}
