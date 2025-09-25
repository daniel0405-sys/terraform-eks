# 1. Data source para obter o ID da conta AWS atual
data "aws_caller_identity" "current" {
   depends_on = [
     aws_eks_node_group.node
  ]
}

# 2. Data source para obter os dados do seu cluster EKS
data "aws_eks_cluster" "cluster" {
  name = "${var.cluster-name}"
  depends_on = [
     aws_eks_node_group.node
  ]
}

locals {
  eks_oidc_provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}

# ==============================================================================
# IAM Role e Associação para o EFS CSI Driver
# ==============================================================================

resource "aws_iam_role" "efs_csi_driver_role" {
  name = "AmazonEKS_EFS_CSI_DriverRole"
  # A associação é feita pelo recurso "aws_eks_pod_identity_association".
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Este é o principal de serviço correto para EKS Pod Identity
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
           "sts:AssumeRole",
           "sts:TagSession"
            ]
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_provider_url}"
                ]
            },
            "Action": "sts:AssumeRoleWithWebIdentity"
        }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver_role.name
}

resource "aws_eks_pod_identity_association" "efs_csi_pod_identity" {
  cluster_name = aws_eks_cluster.aws_eks.name
  namespace    = "kube-system" 
  service_account = "efs-csi-controller-sa" 
  role_arn     = aws_iam_role.efs_csi_driver_role.arn

  depends_on = [
    aws_eks_addon.aws_efs_csi_driver
  ]
}


# ==============================================================================
# IAM Role e Associação para o VPC CNI
# ==============================================================================
resource "aws_iam_role" "vpc_cni_role" {
  name = "AmazonEKS_CNI_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
}

resource "aws_eks_pod_identity_association" "vpc_cni_pod_identity" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  namespace       = "kube-system"
  # O Service Account padrão para o VPC CNI é 'aws-node'
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni_role.arn

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

# ==============================================================================
# IAM Role e Associação para o EBS CSI Driver
# ==============================================================================
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      },
      {
        Effect    = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_provider_url}"
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

resource "aws_eks_pod_identity_association" "ebs_csi_pod_identity" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  namespace       = "kube-system"
  # O Service Account padrão para o EBS CSI Driver é 'ebs-csi-controller-sa'
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver_role.arn

  depends_on = [
    aws_eks_addon.aws_ebs_csi_driver
  ]
}

# ==============================================================================
# IAM Role e Associação para o EBS CSI Driver
# ==============================================================================