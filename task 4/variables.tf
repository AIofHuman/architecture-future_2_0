variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "./.ssh/id_rsa.pub"
}

variable "medical_domain_size" {
  description = "VM size for medical domain"
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    cores  = 4
    memory = 8
    disk   = 100
  }
}

variable "financial_domain_size" {
  description = "VM size for financial domain"
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    cores  = 4
    memory = 8
    disk   = 100
  }
}

variable "analytics_domain_size" {
  description = "VM size for analytics domain"
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    cores  = 8
    memory = 16
    disk   = 200
  }
}
