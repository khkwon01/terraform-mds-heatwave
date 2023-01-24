data "oci_core_images" "images_for_shape" {
    compartment_id = var.compartment_ocid
    operating_system = "Oracle Linux"
    operating_system_version = "8"
    shape = var.operator_shape
    sort_by = "TIMECREATED"
    sort_order = "DESC"
}

# cloud init for operator
data "cloudinit_config" "operator" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "operator.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit/operator.template.yaml", 
      {
        operator_sh_content = base64gzip(
          templatefile("${path.module}/scripts/operator.template.sh",
            {
              ol = var.operator_os_version
            }
          )
        ),
        upgrade_operator    = false,
      }
    )
  }
}

resource "oci_core_instance" "operator" {

  availability_domain = data.oci_identity_availability_domain.AD-1.name
  compartment_id      = var.compartment_ocid
  display_name        = var.operator_name
  shape               = var.operator_shape

  shape_config {
    memory_in_gbs = var.operator_shape_memory
    ocpus = var.operator_shape_ocpus
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.operator-subnet-regional.id
  }

  metadata = {
    ssh_authorized_keys = var.operator_ssh_public_key
    user_data           = data.cloudinit_config.operator.rendered
  }

  source_details {
    source_id   = data.oci_core_images.images_for_shape.images[0].id
    source_type = "image"
  }

}


