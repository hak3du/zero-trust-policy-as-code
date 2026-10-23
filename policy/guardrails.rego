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

# Fail closed when Terraform plan JSON does not include configuration metadata.
# Without configuration.resources, we cannot determine whether ingress was
# explicitly omitted or configured but unresolved.
deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_security_group"
    rc.change.actions[_] != "delete"
    is_object(rc.change.after)
    object.get(object.get(rc.change, "after_unknown", {}), "ingress", false) == true
    not is_array(object.get(object.get(object.get(input, "configuration", {}), "root_module", {}), "resources", null))

    msg := sprintf(
        "Security group ingress is unresolved in the Terraform plan; cannot verify exposure: %s",
        [rc.address],
    )
}

# If configuration metadata exists, only flag unresolved ingress when the
# corresponding root-module resource explicitly contains an ingress expression.
# The AWS provider may mark an omitted ingress attribute as unknown in planned
# state even when the user did not configure any ingress block.
deny contains msg if {
    some rc in input.resource_changes
    rc.type == "aws_security_group"
    rc.change.actions[_] != "delete"
    is_object(rc.change.after)
    object.get(object.get(rc.change, "after_unknown", {}), "ingress", false) == true

    configured_resources := object.get(
        object.get(object.get(input, "configuration", {}), "root_module", {}),
        "resources",
        [],
    )
    some r in configured_resources
    r.address == rc.address
    object.get(r.expressions, "ingress", null) != null

    msg := sprintf(
        "Security group ingress is unresolved in the Terraform plan; cannot verify exposure: %s",
        [rc.address],
    )
}
