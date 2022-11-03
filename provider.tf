data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid  
}

# get the tenancy's home region
data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = ["YNY"]
  }
}

provider oci {
	region = var.region
}

provider oci {
	alias  = "home"
	region = lookup(data.oci_identity_regions.home_region.regions[0], "name")
}
