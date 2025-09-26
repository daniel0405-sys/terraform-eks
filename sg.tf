resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.cluster-name}-nodes-sg"
  description = "Security Group para os nos de trabalho do EKS"
  vpc_id      = module.vpc.vpc_id

  # Regra de Saída: Permite toda a comunicação para o exterior. Essencial.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.cluster-name}-nodes-sg"
  }
}

# 2. Grupo de Segurança para o CONTROL PLANE
resource "aws_security_group" "eks_control_plane_sg" {
  name        = "${var.cluster-name}-control-plane-sg"
  description = "Security Group principal para o control plane do EKS"
  vpc_id      = module.vpc.vpc_id

  # Regra de Saída: Permite toda a comunicação para o exterior.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}-control-plane-sg"
  }
}


# 3. REGRAS DE COMUNICAÇÃO ENTRE ELES

# Regra A: Permite que o Control Plane se comunique com os Nós
# (Ex: para o apiserver se conectar ao kubelet)
resource "aws_security_group_rule" "control_plane_to_nodes" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1" # Todo o tráfego
  security_group_id        = aws_security_group.eks_control_plane_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Permite que o Control Plane acesse os Nos"
}

# Regra B: Permite que os Nós se comuniquem com o Control Plane
# (Ex: para o kubelet se registrar no apiserver na porta 443)
resource "aws_security_group_rule" "nodes_to_control_plane" {
  type                     = "ingress"
  from_port                = 443 # HTTPS
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_control_plane_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Permite que os Nos acessem a API do K8s"
}

# 4. SUAS REGRAS PERSONALIZADAS (AGORA NO GRUPO DO CONTROL PLANE)

# Regra: "VPC do Rancher"
resource "aws_security_group_rule" "rancher_vpc_to_control_plane" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_control_plane_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.10.0.0/16"]
  description       = "Permite acesso da VPC do Rancher"
}

# Regra: ""
resource "aws_security_group_rule" "to_control_plane" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_control_plane_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["172.16.0.0/12"]
  description       = "Permite acesso HTTPS"

}
