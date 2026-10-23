package terraform.guardrails

import rego.v1

planned_changes contains rc if {
    some rc in input.resource_changes
    rc.change.actions[_] != "delete"
    is_object(rc.change.after)
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_security_group"
    some ingress in object.get(rc.change.after, "ingress", [])
    ingress.from_port <= 22
    ingress.to_port >= 22
    some cidr in object.get(ingress, "cidr_blocks", [])
    cidr == "0.0.0.0/0"
    msg := sprintf("SSH (TCP/22) exposed to the public internet: %s", [rc.address])
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_security_group"
    some ingress in object.get(rc.change.after, "ingress", [])
    ingress.from_port <= 3389
    ingress.to_port >= 3389
    some cidr in object.get(ingress, "cidr_blocks", [])
    cidr == "0.0.0.0/0"
    msg := sprintf("RDP (TCP/3389) exposed to the public internet: %s", [rc.address])
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_security_group"
    some ingress in object.get(rc.change.after, "ingress", [])
    ingress.from_port <= 22
    ingress.to_port >= 22
    some cidr in object.get(ingress, "ipv6_cidr_blocks", [])
    cidr == "::/0"
    msg := sprintf("SSH (TCP/22) exposed to the public internet over IPv6: %s", [rc.address])
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_security_group"
    some ingress in object.get(rc.change.after, "ingress", [])
    ingress.from_port <= 3389
    ingress.to_port >= 3389
    some cidr in object.get(ingress, "ipv6_cidr_blocks", [])
    cidr == "::/0"
    msg := sprintf("RDP (TCP/3389) exposed to the public internet over IPv6: %s", [rc.address])
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_ebs_volume"
    object.get(rc.change.after, "encrypted", true) == false
    msg := sprintf("EBS volume encryption explicitly disabled: %s", [rc.address])
}

deny contains msg if {
    some rc in planned_changes
    rc.type == "aws_s3_bucket_public_access_block"
    some setting in ["block_public_acls", "ignore_public_acls", "block_public_policy", "restrict_public_buckets"]
    object.get(rc.change.after, setting, false) == false
    msg := sprintf("S3 public-access protection '%s' disabled: %s", [setting, rc.address])
}

violations := sort([msg | some msg in deny])

deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_security_group"
    rc.change.actions[_] != "delete"
    is_object(rc.change.after)
    object.get(object.get(rc.change, "after_unknown", {}), "ingress", false) == true

    msg := sprintf(
        "Security group ingress is unresolved in the Terraform plan; cannot verify exposure: %s",
        [rc.address],
    )
}

