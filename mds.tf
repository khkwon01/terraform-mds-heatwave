resource "oci_mysql_mysql_db_system" "MDSinstance" {
    admin_password = var.mysql_db_system_admin_password
    admin_username = var.mysql_db_system_admin_username
    availability_domain = data.oci_identity_availability_domain.AD-1.name
    compartment_id = var.compartment_ocid
    shape_name = var.mysql_shape_name
    subnet_id = oci_core_subnet.mds-subnet-regional.id
    data_storage_size_in_gb = var.mysql_data_storage_in_gb
    display_name = var.mds_instance_name
    is_highly_available = var.deploy_mds_ha
    mysql_version = var.mysql_db_version
}

resource "oci_mysql_mysql_configuration" "MDSinstance_configuration" {
    compartment_id = var.compartment_ocid    
    shape_name = var.mysql_shape_name
    display_name = var.mysql_db_configuration
    variables {
        sql_require_primary_key = true
    }
}
