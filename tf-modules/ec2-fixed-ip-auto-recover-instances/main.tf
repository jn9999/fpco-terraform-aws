/**
 * ## Fixed-IP and Auto-Recovering EC2 Instances
 *
 * Use the `aws_instance` and `aws_cloudwatch_metric_alarm` resources in the
 * following pattern:
 *
 * * run N instances, where N is the number of IP addresses in the `private_ips`
 *   list parameter to the module
 * * set the private IP addresses, don't get something random from AWS
 * * accept arbitrary `user_data`
 * * setup a metric alarm and action to auto-recover instances that fail the
 *   health check
 * * no use of instance store, or dedicated EBS volumes which follow an instance
 *
 * This pattern is useful for:
 *
 * * DNS servers
 * * a server that needs a fixed IP address
 * * a server which should be automatically replaced
 * * a server that does not need some dedicated EBS volume to follow (state is
 *   not important
 *
 * Also note that the number of subnets provided does not need to match the
 * number of private IP addresses. Specifically, the `element()` interpolation
 * function is used for `aws_instance.subnet_id`, and that function will wrap
 * using a standard mod algorithm.
 *
 * ### Example
 *
 *     # The DNS servers
 *     module "dns" {
 *       source = "../../vendor/fpco-terraform-aws/tf-modules/ec2-fixed-ip-auto-recover-instances"
 *       name_prefix         = "${var.name}"
 *       ami                 = "${data.aws_ami.ubuntu-xenial.id}"
 *       key_name            = "${aws_key_pair.main.id}"
 *       subnet_ids          = ["${module.private-subnets.ids}"]
 *       private_ips         = ["${var.list_of_ips}"]
 *       security_group_ids  = [
 *         "${module.dns-server-sg.id}",
 *         "${module.public-ssh-sg.id}",
 *         "${module.open-egress-sg.id}",
 *       ]
 *       user_data = <<END_INIT
 *     ufw allow 53
 *     echo "10.10.0.10 foobar.${var.private_dns_zone_name}" >> /etc/hosts
 *     END_INIT
 *       alarm_actions = []
 *     }
 */

# The instance running the DNS server
resource "aws_instance" "auto-recover" {
  count                  = "${length(var.private_ips)}"
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_type}"
  iam_instance_profile   = "${element(var.iam_profiles, count.index)}"
  subnet_id              = "${element(var.subnet_ids, count.index)}"
  vpc_security_group_ids = ["${var.security_group_ids}"]
  private_ip             = "${var.private_ips[count.index]}"
  key_name               = "${var.key_name}"
  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }
  # Instance auto-recovery (see cloudwatch metric alarm below) doesn't support
  # instances with ephemeral storage, so this disables it.
  # See https://github.com/hashicorp/terraform/issues/5388#issuecomment-282480864
  ephemeral_block_device {
    device_name = "/dev/sdb"
    no_device   = true
  }
  ephemeral_block_device {
    device_name = "/dev/sdc"
    no_device   = true
  }
  tags {
    Name = "${format(var.name_format, var.name_prefix, count.index + 1)}"
  }
  lifecycle {
    ignore_changes = ["ami"]
  }
  user_data = "${element(var.user_data, count.index)}"
}

# Current AWS region
data "aws_region" "current" {
  current = true
}

# Cloudwatch alarm that recovers the instance after two minutes of system status
# check failure
resource "aws_cloudwatch_metric_alarm" "auto-recover" {
  count = "${length(compact(var.private_ips))}"
  alarm_name = "${format(var.name_format, var.name_prefix, count.index + 1)}"
  metric_name = "StatusCheckFailed_System"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "2"
  dimensions {
    InstanceId = "${aws_instance.auto-recover.*.id[count.index]}"
  }
  namespace = "AWS/EC2"
  period    = "60"
  statistic = "Minimum"
  threshold = "0"
  alarm_description = "Auto-recover the instance if the system status check fails for two minutes"
  alarm_actions     = ["${compact(concat(list("arn:${var.aws_cloud}:automate:${data.aws_region.current.name}:ec2:recover"), "${var.alarm_actions}"))}"]
}
