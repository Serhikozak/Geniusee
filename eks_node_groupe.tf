resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.EKS_cluster.name
  node_group_name = "node_group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      =  [for s in aws_subnet.private : s.id]

  labels          = {
    "type" = "private"
  }
  instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = var.env
  }
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.EKS_cluster.name
  node_group_name = "public-node-group-${var.env}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = [for s in aws_subnet.public : s.id]

  labels          = {
    "type" = "public"
  }

  instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = var.env
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.eks_cluster_name}-${var.env}/ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.Geniusee_EKS.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.EKS_cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}-${var.env}/ClusterSharedNodeSecurityGroup"
    Environment = var.env
  }
}
