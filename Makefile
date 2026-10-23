.PHONY: test check-compliant check-noncompliant

test:
	opa test policy -v

check-compliant:
	@count=$$(opa eval --format raw --data policy --input examples/compliant-plan.json 'count(data.terraform.guardrails.deny)'); echo "Violations: $$count"; test "$$count" = "0"

check-noncompliant:
	@count=$$(opa eval --format raw --data policy --input examples/noncompliant-plan.json 'count(data.terraform.guardrails.deny)'); echo "Violations: $$count"; test "$$count" -ge "1"
