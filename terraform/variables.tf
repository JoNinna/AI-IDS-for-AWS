variable "key_name" {
  description = "SSH key name in AWS"
  type        = string
}

variable "public_key_path" {
  description = "Path to the local public key file"
  type        = string
}

variable "private_key_path" {
  description = "Path to the local private key file"
  type        = string
}