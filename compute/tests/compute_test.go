package tests

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

type requiredEnv struct {
	name  string
	usage string
}

func requireEnv(t *testing.T, vars []requiredEnv) map[string]string {
	t.Helper()

	values := make(map[string]string)
	missing := make([]string, 0, len(vars))

	for _, env := range vars {
		value := strings.TrimSpace(os.Getenv(env.name))
		if value == "" {
			missing = append(missing, env.name+" ("+env.usage+")")
			continue
		}
		values[env.name] = value
	}

	if len(missing) > 0 {
		t.Skip("missing env vars: " + strings.Join(missing, ", "))
	}

	return values
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func baseVars(env map[string]string) map[string]interface{} {
	return map[string]interface{}{
		"aws_region":                  env["AWS_REGION"],
		"vpc_id":                      env["VPC_ID"],
		"subnet_ids":                  splitCSV(env["SUBNET_IDS"]),
		"allowed_cidr_blocks":         splitCSV(env["ALLOWED_CIDR_BLOCKS"]),
		"associate_public_ip_address": true,
	}
}

func TestExampleBasicPlan(t *testing.T) {
	t.Parallel()

	env := requireEnv(t, []requiredEnv{
		{"AWS_REGION", "e.g. us-east-1"},
		{"VPC_ID", "e.g. vpc-0123456789abcdef0"},
		{"SUBNET_IDS", "comma-separated subnet IDs"},
		{"ALLOWED_CIDR_BLOCKS", "comma-separated CIDR blocks"},
		{"AMI_ID", "Linux AMI ID"},
	})

	vars := baseVars(env)
	vars["ami_id"] = env["AMI_ID"]
	vars["instance_type"] = "t3.micro"

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars:         vars,
		NoColor:      true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

func TestExampleHAPlan(t *testing.T) {
	t.Parallel()

	env := requireEnv(t, []requiredEnv{
		{"AWS_REGION", "e.g. us-east-1"},
		{"VPC_ID", "e.g. vpc-0123456789abcdef0"},
		{"SUBNET_IDS", "comma-separated subnet IDs"},
		{"ALLOWED_CIDR_BLOCKS", "comma-separated CIDR blocks"},
		{"AMI_ID", "Linux AMI ID"},
	})

	vars := baseVars(env)
	vars["ami_id"] = env["AMI_ID"]
	vars["instance_type"] = "t3.micro"
	vars["instance_count"] = 2

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/ha",
		Vars:         vars,
		NoColor:      true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

func TestExampleWindowsPlan(t *testing.T) {
	t.Parallel()

	env := requireEnv(t, []requiredEnv{
		{"AWS_REGION", "e.g. us-east-1"},
		{"VPC_ID", "e.g. vpc-0123456789abcdef0"},
		{"SUBNET_IDS", "comma-separated subnet IDs"},
		{"ALLOWED_CIDR_BLOCKS", "comma-separated CIDR blocks"},
		{"WINDOWS_AMI_ID", "Windows AMI ID"},
	})

	vars := baseVars(env)
	vars["ami_id"] = env["WINDOWS_AMI_ID"]
	vars["instance_type"] = "t3.large"

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/windows",
		Vars:         vars,
		NoColor:      true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}
