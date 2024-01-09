variable "zone" {
  type    = string
  default = "KR-1"
}

resource "ncloud_vpc" "kubernetes_vpc" {
  name            = "kubernetes-vpc"
  ipv4_cidr_block = "10.0.0.0/16"
}

resource "ncloud_subnet" "private_node_subnet" {
  vpc_no         = ncloud_vpc.kubernetes_vpc.id
  subnet         = "10.0.1.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.kubernetes_vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "private-node-subnet"
  usage_type     = "GEN"
}

resource "ncloud_subnet" "private_lb_subnet" {
  vpc_no         = ncloud_vpc.kubernetes_vpc.id
  subnet         = "10.0.11.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.kubernetes_vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "private-lb-subnet"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "public_lb_subnet" {
  vpc_no         = ncloud_vpc.kubernetes_vpc.id
  subnet         = "10.0.12.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.kubernetes_vpc.default_network_acl_no
  subnet_type    = "PUBLIC"
  name           = "public-lb-subnet"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "nat_subnet" {
  vpc_no         = ncloud_vpc.kubernetes_vpc.id
  subnet         = "10.0.3.0/24"
  zone           = var.zone
  network_acl_no = ncloud_vpc.kubernetes_vpc.default_network_acl_no
  subnet_type    = "PUBLIC"
  name           = "nat-subnet"
  usage_type     = "NATGW"
}

resource "ncloud_nat_gateway" "kubernetes_nat_gw" {
  vpc_no    = ncloud_vpc.kubernetes_vpc.id
  subnet_no = ncloud_subnet.nat_subnet.id
  zone      = var.zone
  name      = "kubernetes-nat-gw"
}

resource "ncloud_route_table" "kubernetes_route_table" {
  vpc_no                = ncloud_vpc.kubernetes_vpc.id
  supported_subnet_type = "PRIVATE"
  name                  = "kubernetes-route-table"
}

resource "ncloud_route" "kubernetes_route" {
  route_table_no         = ncloud_route_table.kubernetes_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = ncloud_nat_gateway.kubernetes_nat_gw.name
  target_no              = ncloud_nat_gateway.kubernetes_nat_gw.id
}

resource "ncloud_route_table_association" "kubernetes_route_table_subnet" {
  route_table_no = ncloud_route_table.kubernetes_route_table.id
  subnet_no      = ncloud_subnet.private_node_subnet.id
}

resource "ncloud_login_key" "kubernetes_loginkey" {
  key_name = "kubernetes-loginkey"
}

resource "ncloud_nks_cluster" "terraform_cluster" {
  cluster_type         = "SVR.VNKS.STAND.C002.M008.NET.SSD.B050.G002"
  login_key_name       = ncloud_login_key.kubernetes_loginkey.key_name
  name                 = "terraform-cluster"
  lb_private_subnet_no = ncloud_subnet.private_lb_subnet.id
  lb_public_subnet_no  = ncloud_subnet.public_lb_subnet.id
  subnet_no_list       = [ncloud_subnet.private_node_subnet.id]
  vpc_no               = ncloud_vpc.kubernetes_vpc.id
  zone                 = var.zone
}

resource "ncloud_nks_node_pool" "node_pool" {
  cluster_uuid   = ncloud_nks_cluster.terraform_cluster.uuid
  node_pool_name = "terraform-node-1"
  node_count     = 2
  product_code   = "SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002"
  subnet_no_list = [ncloud_subnet.private_node_subnet.id]
}
