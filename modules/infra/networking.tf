data "aws_availability_zones" "aws_az" {
    state = "available"
}

resource "aws_subnet" "private01" {
    vpc_id = aws_vpc.vpc.vpc_id
    map_public_ip_on_launch = false
    cidr_block = cidrsubnet(var.cidr_block, 8, var.private_subnet01_netnumber)
    availability_zone = element(data.aws_availability_zones.aws_az.names, 0)
    tags = {
        Name                                        = "private-subnet01-${var.cluster_name}"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb"           = 1
    }
}

resource "aws_subnet" "public01" {
    vpc_id = aws_vpc.vpc.vpc_id
    map_public_ip_on_launch = true
    cidr_block = cidrsubnet(var.cidr_block, 8, var.public_subnet01_netnumber)
    availability_zone = element(data.aws_availability_zones.aws_az.names, 0)
    tags = {
        Name                                        = "public-subnet01-${var.cluster_name}"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb"           = 1
    }
}

resource "aws_subnet" "utility" {
    vpc_id = aws_vpc.vpc.vpc_id
    map_public_ip_on_launch = true
    cidr_block = cidrsubnet(var.cidr_block, 8, 253)
    availability_zone = element(data.aws_availability_zones.aws_az.names, 1)
    tags = {
        Name                                        = "utility"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "eip" {
    vpc = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_nat_gateway" "natgw" {
    allocation_id = aws_eip.eip.id
    subnet_id     = aws_subnet.utility.id
}

# Define Routes
resource "aws_route" "public01_igw" {
    route_table_id         = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "natgw" {
    route_table_id         = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_nat_gateway.natgw.id
    depends_on             = [aws_nat_gateway.natgw]
}

# Associate route tables
resource "aws_route_table_association" "public_rt_assoc" {
    subnet_id      = aws_subnet.public01.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
    subnet_id      = aws_subnet.private01.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "utility_rt_assoc" {
    subnet_id      = aws_subnet.utility.id
    route_table_id = aws_route_table.public_rt.id
}