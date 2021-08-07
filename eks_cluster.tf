resource "aws_eks_cluster" "EKS_cluster" {
  name     = "${var.eks_cluster_name}-${var.env}"
  role_arn = aws_iam_role.eks_cluster.arn

  version = "1.21"

  vpc_config {
    security_group_ids      = [aws_security_group.For_EKS.id]
    #subnet_ids = [aws_subnet.private[each.value["name"]].id, aws_subnet.public["public_eks_1"].id, aws_subnet.public["public_eks_1"].id]
    subnet_ids = concat([for s in aws_subnet.private : s.id], [for s in aws_subnet.public : s.id])
    endpoint_private_access = true
    endpoint_public_access  = true

  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.assign_policy_to_role_AmazonEKSServicePolicy
  ]

  tags = {
    Environment = "core"
  }

}