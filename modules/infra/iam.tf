data "aws_iam_policy_document" "assume-role-policy" {
    statement {
        action = ["sts:AssumeRole"]
        principals {
            identifiers = ["ec2.amazaonaws.com"]
            type        = "Service"
        }
    }
}

resource "aws_iam_role" "k8s_master_role" {
    name               = "terraform_master_role"
    assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

resource "aws_iam_role_policy" "master_policy" {
    name = "terraform_master_policy"
    role = aws_iam_role.k8s_master_role.id
    policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[

            ]
        }
    ]
}
}

resource "aws_iam_instance_profile" "k8s_master_role-Instance-Profile" {
    name = "master_role-Instance-Profile"
    role = aws_iam_role.k8s_master_role.name
}

resource "aws_iam_instance_profile" "k8s_worker_role-Instance-Profile" {
    name = "worker_role-Instance-Profile"
    role = aws_iam_role.k8s_worker_role.name
}