resource "aws_ami_from_instance" "this" {
  name               = "${var.name_prefix}-${var.environment}-app-${replace(var.source_instance_id, "i-", "")}"
  source_instance_id = var.source_instance_id

  # Reboot the verified source instance while creating the image so the EBS
  # snapshot is application-consistent for this training milestone.
  snapshot_without_reboot = false

  tags = {
    Name = "${var.name_prefix}-${var.environment}-app-ami"
    Tier = "application"
  }
}
