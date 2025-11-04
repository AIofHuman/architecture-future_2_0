terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.96"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Создание VPC сети
resource "yandex_vpc_network" "future_network" {
  name        = "future-network"
  description = "Network for Future 2.0 domains"
}

# Создание подсетей
resource "yandex_vpc_subnet" "medical_subnet" {
  name           = "medical-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  v4_cidr_blocks = ["10.130.0.0/24"]
}

resource "yandex_vpc_subnet" "data_subnet" {
  name           = "data-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  v4_cidr_blocks = ["10.130.1.0/24"]
}

resource "yandex_vpc_subnet" "dmz_subnet" {
  name           = "dmz-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  v4_cidr_blocks = ["10.130.2.0/24"]
}

# NAT Gateway для исходящего интернет-трафика
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route" {
  name       = "nat-route"
  network_id = yandex_vpc_network.future_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id        = yandex_vpc_gateway.nat_gateway.id
  }
}

# Security Groups
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for web applications"
  network_id  = yandex_vpc_network.future_network.id

  ingress {
    description    = "HTTP"
    port           = 80
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Outgoing traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Security group for application servers"
  network_id  = yandex_vpc_network.future_network.id

  ingress {
    description       = "Internal HTTP"
    port              = 8080
    protocol          = "TCP"
    predefined_target = "self_security_group"
  }

  ingress {
    description       = "SSH"
    port              = 22
    protocol          = "TCP"
    v4_cidr_blocks    = ["10.130.0.0/16"]
  }
}

resource "yandex_vpc_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Security group for databases"
  network_id  = yandex_vpc_network.future_network.id

  ingress {
    description       = "PostgreSQL"
    port              = 5432
    protocol          = "TCP"
    predefined_target = "self_security_group"
  }

  ingress {
    description       = "Kafka"
    port              = 9092
    protocol          = "TCP"
    predefined_target = "self_security_group"
  }
}

# Виртуальные машины для доменов
resource "yandex_compute_instance" "medical_domain" {
  name        = "medical-domain"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 100
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.medical_subnet.id
    security_group_ids = [
      yandex_vpc_security_group.app_sg.id,
      yandex_vpc_security_group.db_sg.id
    ]
    nat = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "financial_domain" {
  name        = "financial-domain"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 100
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.medical_subnet.id
    security_group_ids = [
      yandex_vpc_security_group.app_sg.id,
      yandex_vpc_security_group.db_sg.id
    ]
    nat = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

resource "yandex_compute_instance" "analytics_domain" {
  name        = "analytics-domain"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = 8
    memory = 16
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 200
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.data_subnet.id
    security_group_ids = [
      yandex_vpc_security_group.app_sg.id,
      yandex_vpc_security_group.db_sg.id
    ]
    nat = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}


# PostgreSQL кластер
resource "yandex_mdb_postgresql_cluster" "main_db" {
  name        = "future-main-db"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.future_network.id

  config {
    version = 15
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 100
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.data_subnet.id
  }
}

# Object Storage для данных
resource "yandex_storage_bucket" "medical_bucket" {
  bucket = "future-medical-data"
  acl    = "private"

  anonymous_access_flags {
    read = false
    list = false
  }
}

resource "yandex_storage_bucket" "financial_bucket" {
  bucket = "future-financial-data"
  acl    = "private"

  anonymous_access_flags {
    read = false
    list = false
  }
}

resource "yandex_storage_bucket" "analytics_bucket" {
  bucket = "future-analytics-data"
  acl    = "private"

  anonymous_access_flags {
    read = false
    list = false
  }
}

# Load Balancer
resource "yandex_lb_network_load_balancer" "external_lb" {
  name = "external-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "https-listener"
    port = 443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/health"
      }
    }
  }
}

resource "yandex_lb_target_group" "app_tg" {
  name = "app-target-group"

  target {
    subnet_id = yandex_vpc_subnet.medical_subnet.id
    address   = yandex_compute_instance.medical_domain.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.medical_subnet.id
    address   = yandex_compute_instance.financial_domain.network_interface.0.ip_address
  }
}