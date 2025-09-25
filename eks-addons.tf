
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.aws_eks.name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.3-eksbuild.6"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.aws_eks.name
  addon_name    = "coredns"
  addon_version = "v1.12.4-eksbuild.1"

  depends_on = [
    aws_eks_node_group.node,aws_eks_addon.aws_efs_csi_driver
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.aws_eks.name
  addon_name    = "vpc-cni"
  addon_version = "v1.20.1-eksbuild.3"
}

resource "aws_eks_addon" "aws_efs_csi_driver" {
  cluster_name  = aws_eks_cluster.aws_eks.name
  addon_name    = "aws-efs-csi-driver"
  addon_version = "v2.1.11-eksbuild.1"

  # Garante que a role do IAM seja criada antes do add-on
  depends_on = [
    aws_eks_node_group.node
  ]
}

# O "Agente de Identidade de Pods do Amazon EKS" (eks-pod-identity-agent)
# também pode ser adicionado se você planeja usar EKS Pod Identities.
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = aws_eks_cluster.aws_eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.8-eksbuild.2"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.aws_eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.48.0-eksbuild.2"

  # Adiciona a configuração avançada para incluir tags em todos os volumes EBS criados
  configuration_values = jsonencode({
    controller = {
      extraVolumeTags = {
        "cnj-env"         = "staging"
        "cnj-nature"      = "operation"
        "backup-required" = "false"
      }
    }
  })

  # Garante que a role do IAM seja criada antes do add-on
  depends_on = [
    aws_eks_node_group.node
  ]
}