resource "oci_mysql_mysql_configuration" "MDSinstance_configuration" {
    compartment_id = var.compartment_ocid    
    shape_name = var.mysql_shape_name
    display_name = var.mysql_db_configuration
    variables {
        sql_require_primary_key = false
        binlog_expire_logs_seconds = 86400
#        sql_generate_invisible_primary_key = true
    }
}

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
    configuration_id = oci_mysql_mysql_configuration.MDSinstance_configuration.id
    hostname_label = var.mds_instance_name
    backup_policy {
        is_enabled = false
        retention_in_days = "10"
        window_start_time = "01:00-07:00"
    }
    maintenance {
        window_start_time = "fri 22:00"
    }
}

resource "oci_mysql_heat_wave_cluster" "HeatWave" {
    count        = var.mysql_heatwave_enabled ? 1 : 0
    db_system_id = oci_mysql_mysql_db_system.MDSinstance.id
    cluster_size = var.mysql_heatwave_cluster_size
    shape_name   = var.mysql_heatwave_shape
    is_lakehouse_enabled = var.mysql_lakehouse_enabled ? 1 : 0
}
