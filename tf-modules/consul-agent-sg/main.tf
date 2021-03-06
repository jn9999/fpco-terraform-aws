/**
 *## Ingress Rules for Consul Agents
 *
 *This module creates `aws_security_group_rule` resources, defining an ingress
 *rule to allow port `8301`, for TCP and UDP each. Use with a security
 *group on any nodes you wish to use the consul agent on.
 *
 *
 *### Example
 *
 * UPDATE THESE DOCS
 *
 *```
 *# boxed security group for consul leader services, no egress/custom rules
 *module "consul-agent-sg" {
 *    source      = "../tf-modules/consul-agent-sg"
 *    cidr_blocks = ["${module.test-vpc.cidr_block}"]
 *}
 *
 *module "my-cluster" {
 *    source = "../tf-modules/consul-cluster"
 *    ...
 *    cluster_security_group_ids = "${module.consul-agent-sg.id}, ${aws_security_group.worker-service.id}, ${module.public-ssh-sg.id}"
 *```
 */

# ingress rules for consul agents. Required by all agents. 

variable "security_group_id" {
  description = "security group to attach the ingress rules to"
}

variable "cidr_blocks" {
  description = "The list of CIDR IP blocks allowed to access the consul ports"
  type        = "list"
}

variable "description" {
  description = "use this string to generate a description for the SG rules"
  default     = "Allow ingress, consul LAN serf port 8301"
}

# Serf LAN, used to handle gossip in the LAN. TCP and UDP.
resource "aws_security_group_rule" "serf_lan_tcp" {
  type              = "ingress"
  description       = "${var.description} (TCP)"
  from_port         = "8301"
  to_port           = "8301"
  protocol          = "tcp"
  cidr_blocks       = ["${var.cidr_blocks}"]
  security_group_id = "${var.security_group_id}"
}

resource "aws_security_group_rule" "serf_lan_udp" {
  type              = "ingress"
  description       = "${var.description} (UDP)"
  from_port         = "8301"
  to_port           = "8301"
  protocol          = "udp"
  cidr_blocks       = ["${var.cidr_blocks}"]
  security_group_id = "${var.security_group_id}"
}
