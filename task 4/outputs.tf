output "medical_domain_ip" {
  description = "Internal IP address of medical domain"
  value       = yandex_compute_instance.medical_domain.network_interface.0.ip_address
}

output "financial_domain_ip" {
  description = "Internal IP address of financial domain"
  value       = yandex_compute_instance.financial_domain.network_interface.0.ip_address
}

output "analytics_domain_ip" {
  description = "Internal IP address of analytics domain"
  value       = yandex_compute_instance.analytics_domain.network_interface.0.ip_address
}


output "postgresql_cluster_fqdn" {
  description = "PostgreSQL cluster FQDN"
  value       = yandex_mdb_postgresql_cluster.main_db.host[0].fqdn
}

output "load_balancer_ip" {
  description = "External IP address of load balancer"
  value       = yandex_lb_network_load_balancer.external_lb.listener[*].external_address_spec[*].address
}

output "storage_buckets" {
  description = "Created storage buckets"
  value = {
    medical   = yandex_storage_bucket.medical_bucket.bucket
    financial = yandex_storage_bucket.financial_bucket.bucket
    analytics = yandex_storage_bucket.analytics_bucket.bucket
  }
}

output "network_info" {
  description = "Network configuration"
  value = {
    vpc_id      = yandex_vpc_network.future_network.id
    medical_cidr = yandex_vpc_subnet.medical_subnet.v4_cidr_blocks[0]
    data_cidr   = yandex_vpc_subnet.data_subnet.v4_cidr_blocks[0]
    dmz_cidr    = yandex_vpc_subnet.dmz_subnet.v4_cidr_blocks[0]
  }
}