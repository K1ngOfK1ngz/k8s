data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    owners =[099720109477] # Canonical
}

resource "aws_instance" "bastion" {
    ami = dat.aws_ami.ubuntu.id
    instance_type = "t3.small"
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    key_name = var.key_name
    subnet_id = aws.subnet.utility.id
    root_block_device {
        volume_size = 20
    }
    tags = {
        Name = "bastion.${var.cluster_name}"
    }
}

resource "aws_elb" "api-k8s-local" {
    name = "api-${var.cluster_name}"
    
    listener {
        instance_port     = 6443
        instance_protocol = "TCP"
        lb_port           = 6443
        lb_protocol       = "TCP"
    }

    security_groups = [aws_security_group.api-elb-k8s-local.id]
    subnets         = [aws_subnet.public01.id]

    health_check {
        target              = "SSL:6443"
        healthy_treshold    = 2
        unhealthy_threshold = 2
        interval            = 10
        timeout             = 5
    }

    cross_zone_load_balancing = true
    idle_timeout              = 300

    tags = {
        KubernetesCluster                           = var.cluster_name
        Name                                        = "api.${var.cluster_name}"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
}

# Master Nodes ASG
resource "aws_launch_template" "masters-az01-lt" {
    name_prefix          = "masters.${var.cluster_name}"
    image_id             = var.ami
    instance_type        = var.master_instance_type
    key_name             = var.key_name
    iam_instance_profile = aws_iam_instance_profile.k8s_master_role-Instance-Profile.id
    security_groups      = [aws_security_group.master_node_sg.id]
    user_data            = var.user_data
    lifecycle {
        create_before_destroy = true
    }
    root_block_device {
        volume_size           = 20
        volume_type           = "gp2"
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "master-nodes-asg" {
    name = "${var.cluster_name}_masters"
    launch_template = aws_launch_template.masters-az01-lt.id
    max_size = 1
    min_size = 1
    vpc_zone_identifier = ["aws_subnet.private01.id"]
    load_balancers      = [aws_elb.api-k8s-local.id]

    tags = [{
        key = "KubernetesCluster"
        value = var.cluster_name
        propogate_at_launch = true
    },
    {
        key = "Name"
        value = "masters.${var.cluster_name}"
        propogate_at_launch = true
    },
    {
        key = "k8s.io/role/master"
        value = "1"
        propogate_at_launch = true
    },
    {
        key = "kubernetes.io/cluster/${var.cluster_name}"
        value = "1"
        propogate_at_launch = true
    }
    ]
}

# Worker Nodes ASG
resource "aws_launch_template" "workers-az01-lt" {
    name_prefix          = "workers.${var.cluster_name}"
    image_id             = var.ami
    instance_type        = var.workers_instance_type
    key_name             = var.key_name
    iam_instance_profile = aws_iam_instance_profile.k8s_workers_role-Instance-Profile.id
    security_groups      = [aws_security_group.workers_node_sg.id]
    user_data            = var.user_data
    lifecycle {
        create_before_destroy = true
    }
    root_block_device {
        volume_size           = 20
        volume_type           = "gp2"
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "worker-nodes-asg" {
    name = "${var.cluster_name}_workers"
    launch_template = aws_launch_template.workers-az01-lt.id
    max_size = 2
    min_size = 2
    vpc_zone_identifier = ["aws_subnet.private01.id"]
    load_balancers      = [aws_elb.api-k8s-local.id]

    tags = [{
        key = "KubernetesCluster"
        value = var.cluster_name
        propogate_at_launch = true
    },
    {
        key = "Name"
        value = "workers.${var.cluster_name}"
        propogate_at_launch = true
    },
    {
        key = "k8s.io/role/worker"
        value = "1"
        propogate_at_launch = true
    },
    {
        key = "kubernetes.io/cluster/${var.cluster_name}"
        value = "1"
        propogate_at_launch = true
    }
    ]
}