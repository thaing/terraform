locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # D-41: size tier -> EKS node instance types (dev smallest, staging/prod larger)
  instance_types = {
    small  = ["t3.micro"]
    medium = ["t4g.medium"]
    large  = ["m6i.large"]
  }

  # Role ARN is deterministic (arn:aws:iam::<acct>:role/<name>) — referenced from the
  # trust policy via local so the policy document does not create a resource cycle
  cluster_role_name = "${var.project}-${var.environment}-eks-cluster"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# --- Cluster IAM role (D-38: EKS-owned, destroyed with the cluster) ---
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:TagSession:PrincipalArn"
      values = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_role_name}"
      ]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = local.cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# --- Node group IAM role (least-privilege, D-46: worker/CNI/ECR only, no admin) ---
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.project}-${var.environment}-eks-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_workers" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# --- EKS cluster (D-34/35: pinned version + STANDARD upgrade policy avoids $438/mo extended support) ---
resource "aws_eks_cluster" "this" {
  name     = "${var.project}-${var.environment}-eks"
  role_arn = aws_iam_role.cluster.arn
  version  = var.k8s_version

  upgrade_policy {
    support_type = "STANDARD"
  }

  # B1: both public subnets (2 AZs) — EKS rejects single-AZ subnet lists at apply
  vpc_config {
    subnet_ids = var.subnet_ids
  }

  # T-05-03: policy attachment must land before cluster creation or IAM is "not ready"
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = local.common_tags
}

# --- kubeconfig auth token (A5: derived via the cluster auth data source) ---
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

# --- IRSA OIDC provider (D-46: pods assume scoped IAM roles) ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  tags            = local.common_tags
}

# --- Node group (D-42: spot keeps node cost near-zero; B1: both AZs) ---
resource "aws_eks_node_group" "this" {
  cluster_name   = aws_eks_cluster.this.name
  node_role_arn  = aws_iam_role.node.arn
  subnet_ids     = var.subnet_ids
  capacity_type  = "SPOT"
  instance_types = local.instance_types[var.size]
  disk_size      = 20

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  # T-05-03: nodes must join only after all three role policies are attached
  depends_on = [
    aws_iam_role_policy_attachment.node_workers,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  tags = local.common_tags
}