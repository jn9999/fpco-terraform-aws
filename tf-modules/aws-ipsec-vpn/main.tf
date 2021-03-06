variable "name" {
  description = "Used to name the various VPN resources"
}
variable "vpc_id" {
  description = "ID of the VPC to associate the VPN with"
}
variable "remote_device_ip" {
  description = "The public IP address of the remote (client) device"
}
variable "static_routes" {
  type        = "list"
  description = "The list of CIDR blocks to create static routes for"
}
variable "extra_tags" {
  type        = "map"
  default     = {}
  description = "Extra tags to append to various AWS resources"
}

resource "aws_vpn_gateway" "main" {
  vpc_id = "${var.vpc_id}"
  tags   = "${merge(map("Name", "${var.name}"), "${var.extra_tags}")}"
}

resource "aws_customer_gateway" "main" {
  ip_address = "${var.remote_device_ip}"
  bgp_asn    = "65000" # required, but I don't think it's used with a static config
  type       = "ipsec.1"
  tags       = "${merge(map("Name", "${var.name}"), "${var.extra_tags}")}"
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.main.id}"
  customer_gateway_id = "${aws_customer_gateway.main.id}"
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = "${merge(map("Name", "${var.name}"), "${var.extra_tags}")}"
}

resource "aws_vpn_connection_route" "main" {
  count                  = "${length(var.static_routes)}"
  destination_cidr_block = "${element(var.static_routes, count.index)}"
  vpn_connection_id      = "${aws_vpn_connection.main.id}"
}
