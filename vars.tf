#identity  => you should modify this value according to your test environment
variable compartment_ocid { }
variable tenancy_ocid { }
variable region { }

#variable tenancy_ocid { default = "" }
#variable region { default = "ap-seoul-1" }

#network


#operator
variable operator_shape { default = "VM.Standard.E4.Flex" }
variable operator_shape_ocpus { default = 1 }
variable operator_shape_memory { default = 8 }
variable operator_ssh_public_key { default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvRZ6JUfI6qGFL5Y3Ql2/9Awr3stdOTUTK2dDbvppG0f8gSACQHK6qdJkuQMESRdaTlxhBAxBxBB46C6d9v2bYSroyNhGPf3Nk2vqaV5Sg75krHqnT4UTnRaTxGj3xj6xtpBsVFABIAK7fNwrrWvza+8MLyX83rwUGlm8CPoI5a32+EUuNEiOzWnPRCtuh+rnpozyRgEQyVD/r0Y/rQIwQVrvdTn2XziIkJ8gxGn39FtswUArwuo/iJ306WXaMxYzTpVVhiw+dzKPOoCz4R0D9PsuxL3EtZeXSi8B8di2Og5caURu4E5j3lsBvUkD/mUD3JTZap9KGImVjfM7B3/zn"}
variable operator_ssh_private_key_path { default = "./keys/id_rsa"}
variable operator_os { default = "Oracle Linux" }
variable operator_os_version { default = "8" }
variable operator_name { default = "HEATWAVE-Client" }

# MySQL Data Service
variable "mds_instance_name" {
  description = "Name of the MDS instance"
  default     = "HEATWAVE-Client"
}

variable "mysql_db_system_admin_username" {
  description = "MySQL Database Service Username"
  default     = "admin"
}

variable "mysql_db_system_admin_password" {
  description = "Password for the admin user for MySQL Database Service"
  type        = string
  default     = "Welcome#1"
}

variable "mysql_shape_name" {
  default = "MySQL.4"
}

variable "mysql_data_storage_in_gb" {
    default = 1024
}

variable "deploy_mds_ha" {
  description = "Deploy High Availability for MDS"
  type        = bool
  default     = false
}

variable "mysql_db_version" {
  default = "9.2.1"
}

variable "mysql_db_configuration" {
  default = "MySQL.4.Standalone_cust1"  
}

variable "mysql_heatwave_enabled" {
  description = "Defines whether a MySQL HeatWave cluster is enabled"
  default     = true
}

variable "mysql_lakehouse_enabled" {
  description = "Defines whether a MySQL Lakehouse is enabled or not"
  default     = true
}

variable "mysql_heatwave_cluster_size" {
  description = "Number of MySQL HeatWave nodes to be created"
  default     = 3
}

variable "mysql_heatwave_shape" {
  description = "The shape to be used instead of mysql_shape_name when mysql_heatwave_enabled = true."
  default     = "HeatWave.512GB"
}
