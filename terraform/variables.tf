variable "rgn" {
    description = "Resource Group for Virtual Machine"
    default = "udacity-capstone"
}



variable "location" {
  description = "azure region where resources will be located .e.g."
  default     = "East US"
}

variable "username" {
    description = "Enter username for the vm"
    default = "sadmin"
}

variable "password" {
    description = "Enter password for the vm"
    default = "letmein123"
}

variable "numbervm" {
    description = "number of Vm to create"
    default = 2 
    type = number 
}