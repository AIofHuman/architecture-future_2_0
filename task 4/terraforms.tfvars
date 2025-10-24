yc_token      = "your_oauth_token_here"
yc_cloud_id   = "your_cloud_id_here"
yc_folder_id  = "your_folder_id_here"
yc_zone       = "ru-central1-a"

ssh_public_key_path = "./.ssh/id_rsa.pub"

# Domain configurations
medical_domain_size = {
  cores  = 4
  memory = 8
  disk   = 100
}

financial_domain_size = {
  cores  = 4
  memory = 8
  disk   = 100
}

analytics_domain_size = {
  cores  = 8
  memory = 16
  disk   = 200
}

kafka_cluster_size = {
  nodes  = 3
  cores  = 4
  memory = 8
  disk   = 200
}