resource "aws_security_group" "api-elb-k8s-local" {
    name        = "api-elb.${var.cluster_name}.k8s.local"
    vpc_id      = aws_vpc.vpc.id
    description = "SG for API ELB"
    ingress {
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 3
        to_port     = 4
        protocol    = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name              = "api-elb.${cluster_name}.k8s.local"
        KubernetesCluster = "${var.cluster_name}.k8s.local"
    }
}

# Bastion SG
resource "aws_security_group" "bastion_sg" {
    name        = "bastion-sg"
    vpc_id      = aws_vpc.vpc.id
    description = "Allow traffic to the bastion host"
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH from external"
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "sg_bastion"
    }
}

# Worker Nodes SG
resource "aws_security_group" "worker_nodes_sg" {
    name        = "worker_nodes_${var.cluster_name}_sg"
    vpc_id      = aws_vpc.vpc.id
    description = "SG for worker nodes"
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [aws_vpc.vpc.cidr_block]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name                                        = "${var.cluster_name}_nodes"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
}

# Master Nodes SG
resource "aws_security_group" "master_nodes_sg" {
    name        = "master_nodes_${var.cluster_name}"
    vpc_id      = aws_vpc.vpc.id
    description = "Master nodes SG"
    tags = {
        Name = "${var.cluster_name}_master_nodes"
    }
}

resource "aws_security_group_rule" "traffic_from_lb" {
    type                     = ingress
    description              = "Allow API traffic from the lb"
    from_port                = 6443
    to_port                  = 6443
    protocol                 = "TCP"
    source_security_group_id = aws_security_group.api-elb-k8s-local.id
    security_group_id        = aws_security_group.master_nodes_sg.id
}

resource "aws_security_group_rule" "traffic_from_workers_to_master" {
    type                     = ingress
    description              = "Allow API traffic from the worker to master nodes"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = aws_security_group.worker_nodes_sg.id
    security_group_id        = aws_security_group.masters_node_sg.id
}

resource "aws_security_group_rule" "traffic_from_bastion_to_master" {
    type                     = ingress
    description              = "Allow API traffic from the bastion to master"
    from_port                = 22
    to_port                  = 22
    protocol                 = "TCP"
    source_security_group_id = aws_security_group.bastion_sg.id
    security_group_id        = aws_security_group.master_node_sg.id
}

resource "aws_security_group_rule" "masters_egress" {
    type                     = egress
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    cider_blocks             = ["0.0.0.0/0"]
    security_group_id        = aws_security_group.master_node_sg.id
}