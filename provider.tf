
provider oci {
	region = var.region
}

provider oci {
	alias  = "home"
	region = "ap-chuncheon-1"       # This value can modify according to your region
}
