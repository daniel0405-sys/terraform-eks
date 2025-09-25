
resource "aws_eks_cluster" "aws_eks" {
  name     = "${var.cluster-name}"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
    endpoint_public_access = false
    endpoint_private_access = true
    security_group_ids = [aws_security_group.eks_control_plane_sg.id]
  }


  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
  ]

  tags = {
    Name = "${var.cluster-name}"
  }
}

resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix = "${var.cluster-name}-lt-"
  
  instance_type = "t3.medium" 

  vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name"                                      = "${var.cluster-name}-node"
      "kubernetes.io/cluster/${var.cluster-name}" = "owned"
    }
  }
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "node_${var.cluster-name}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.eks_nodes_lt.id
    version = aws_launch_template.eks_nodes_lt.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
