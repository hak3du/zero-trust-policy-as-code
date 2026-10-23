package terraform.guardrails

import rego.v1

test_public_ssh_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_security_group.admin", "type": "aws_security_group",
        "change": {"actions": ["create"], "after": {"ingress": [{
            "from_port": 22, "to_port": 22, "protocol": "tcp",
            "cidr_blocks": ["0.0.0.0/0"], "ipv6_cidr_blocks": []
        }]}}
    }]}
}

test_unencrypted_ebs_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_ebs_volume.data", "type": "aws_ebs_volume",
        "change": {"actions": ["create"], "after": {"encrypted": false}}
    }]}
}

test_private_ssh_is_allowed if {
    count(deny) == 0 with input as {"resource_changes": [{
        "address": "aws_security_group.admin", "type": "aws_security_group",
        "change": {"actions": ["create"], "after": {"ingress": [{
            "from_port": 22, "to_port": 22, "protocol": "tcp",
            "cidr_blocks": ["10.0.0.0/16"], "ipv6_cidr_blocks": []
        }]}}
    }]}
}

test_destroy_only_change_is_ignored if {
    count(deny) == 0 with input as {"resource_changes": [{
        "address": "aws_ebs_volume.old", "type": "aws_ebs_volume",
        "change": {"actions": ["delete"], "after": null}
    }]}
}

test_public_ssh_over_ipv6_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_security_group.admin", "type": "aws_security_group",
        "change": {"actions": ["create"], "after": {"ingress": [{
            "from_port": 22, "to_port": 22, "protocol": "tcp",
            "cidr_blocks": [], "ipv6_cidr_blocks": ["::/0"]
        }]}}
    }]}
}

test_public_rdp_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_security_group.rdp", "type": "aws_security_group",
        "change": {"actions": ["create"], "after": {"ingress": [{
            "from_port": 3389, "to_port": 3389, "protocol": "tcp",
            "cidr_blocks": ["0.0.0.0/0"], "ipv6_cidr_blocks": []
        }]}}
    }]}
}

test_public_rdp_over_ipv6_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_security_group.rdp", "type": "aws_security_group",
        "change": {"actions": ["create"], "after": {"ingress": [{
            "from_port": 3389, "to_port": 3389, "protocol": "tcp",
            "cidr_blocks": [], "ipv6_cidr_blocks": ["::/0"]
        }]}}
    }]}
}

test_s3_block_public_acls_disabled_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {"actions": ["create"], "after": {
            "block_public_acls": false,
            "ignore_public_acls": true,
            "block_public_policy": true,
            "restrict_public_buckets": true
        }}
    }]}
}

test_s3_ignore_public_acls_disabled_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {"actions": ["create"], "after": {
            "block_public_acls": true,
            "ignore_public_acls": false,
            "block_public_policy": true,
            "restrict_public_buckets": true
        }}
    }]}
}

test_s3_restrict_public_buckets_disabled_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {"actions": ["create"], "after": {
            "block_public_acls": true,
            "ignore_public_acls": true,
            "block_public_policy": true,
            "restrict_public_buckets": false
        }}
    }]}
}

test_s3_block_public_policy_disabled_is_denied if {
    count(deny) == 1 with input as {"resource_changes": [{
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {"actions": ["create"], "after": {
            "block_public_acls": true,
            "ignore_public_acls": true,
            "block_public_policy": false,
            "restrict_public_buckets": true
        }}
    }]}
}

test_unknown_security_group_ingress_is_not_assumed_safe if {
    count(deny) >= 1 with input as {
        "resource_changes": [{
            "address": "aws_security_group.unknown",
            "type": "aws_security_group",
            "change": {
                "actions": ["create"],
                "after": {},
                "after_unknown": {
                    "ingress": true
                }
            }
        }]
    }
}

test_unknown_ingress_with_omitted_configuration_is_allowed if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "aws_security_group.no_ingress",
            "type": "aws_security_group",
            "change": {
                "actions": ["create"],
                "after": {},
                "after_unknown": {"ingress": true}
            }
        }],
        "configuration": {
            "root_module": {
                "resources": [{
                    "address": "aws_security_group.no_ingress",
                    "expressions": {}
                }]
            }
        }
    }
}

test_unknown_ingress_with_explicit_configuration_is_denied if {
    count(deny) >= 1 with input as {
        "resource_changes": [{
            "address": "aws_security_group.configured_ingress",
            "type": "aws_security_group",
            "change": {
                "actions": ["create"],
                "after": {},
                "after_unknown": {"ingress": true}
            }
        }],
        "configuration": {
            "root_module": {
                "resources": [{
                    "address": "aws_security_group.configured_ingress",
                    "expressions": {"ingress": {"constant_value": []}}
                }]
            }
        }
    }
}

