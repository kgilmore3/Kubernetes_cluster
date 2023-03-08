variable "ubuntu-ami" {
  default = "ami-0735c191cf914754d"
}
variable "redhat-ami" {
  default = "ami-0edab8d70528476d3"
}
variable "instance-type" {
  default = "t3.medium"
}
variable "kubernetes-key" {
  default     = "~/keypairs/kubernetes-key.pub"
  description = "path to my keypairs"
}
variable "keyname" {
  default = "kubernetes-key"
}