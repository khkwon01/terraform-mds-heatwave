# mysqlsh
data "template_file" "install_mysqlsh" {
  template = file("${path.module}/scripts/install_mysqlsh.template.sh")

  vars = {
    user = "opc"
  }
}

resource null_resource "install_mysqlsh" {
  connection {
    host        = oci_core_instance.operator.public_ip
    private_key = file(var.operator_ssh_private_key_path)
    timeout     = "40m"
    type        = "ssh"
    user        = "opc"

  }

  provisioner "file" {
    content     = data.template_file.install_mysqlsh.rendered
    destination = "~/install_mysqlsh.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/install_mysqlsh.sh",
      "bash $HOME/install_mysqlsh.sh",
      "rm -f $HOME/install_mysqlsh.sh"
    ]
  }
}

