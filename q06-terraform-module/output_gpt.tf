# variables.tf
variable "environment" {
  description = "Ambiente (ex: dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "hml", "homolog", "qa", "lab", "test", "sandbox"], var.environment)
    error_message = "O valor de environment deve ser um ambiente válido (dev, staging, prod, etc.)."
  }
}

variable "owner" {
  description = "Responsável pelo recurso (time ou pessoa)"
  type        = string
}

variable "cost_center" {
  description = "Centro de custo para alocação financeira"
  type        = string
}

variable "bucket_name" {
  description = "Nome base do bucket (sem prefixo hvt- e sem ambiente). Ex: logs, backups, data-lake"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name deve ser um nome S3 válido (apenas letras minúsculas, números e hífens, começando e terminando com letra/número)."
  }
}

variable "enable_versioning" {
  description = "Habilitar versionamento no bucket S3"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Habilitar logging de acesso ao bucket S3"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Nome do bucket de destino para logs (obrigatório se enable_logging = true). Deve existir previamente ou ser criado separadamente. Ex: hvt-logs-prod"
  type        = string
  default     = ""
  validation {
    condition = (
      var.enable_logging == false || (length(var.log_bucket_name) > 0 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.log_bucket_name)))
    )
    error_message = "log_bucket_name é obrigatório quando enable_logging = true e deve ser um nome S3 válido."
  }
}

variable "tags" {
  description = "Tags adicionais a serem aplicadas ao bucket (opcional). As tags obrigatórias Owner, CostCenter e Environment são sempre incluídas automaticamente."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Forçar destruição do bucket mesmo se houver objetos (cuidado em produção)"
  type        = bool
  default     = false
}

# main.tf
# Locals para tags comuns – segue padrão do módulo VPC de referência
locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
}

# Bucket S3 principal – nome com prefixo hvt- e ambiente
resource "aws_s3_bucket" "this" {
  bucket = "hvt-${var.bucket_name}-${var.environment}"
  # Tags: merge das comuns com tags adicionais (se houver)
  tags   = merge(local.common_tags, var.tags)

  # force_destroy controla se objetos podem ser perdidos na destruição
  force_destroy = var.force_destroy
}

# Versionamento – ativo conforme padrão da empresa
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Criptografia SSE-S3 (mínimo obrigatório)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueio total de acesso público (reforça segurança)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging condicional – só criado se enable_logging = true e log_bucket_name fornecido
resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging && length(var.log_bucket_name) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.log_bucket_name
  target_prefix = "hvt-${var.bucket_name}-${var.environment}/logs/"
}

# outputs.tf
output "bucket_id" {
  description = "ID do bucket S3 (nome)"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Região AWS onde o bucket foi criado"
  value       = aws_s3_bucket.this.region
}

output "bucket_domain_name" {
  description = "Nome de domínio do bucket (para uso com S3 endpoint)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Nome de domínio regional do bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_tags_all" {
  description = "Todas as tags associadas ao bucket (incluindo tags herdadas)"
  value       = aws_s3_bucket.this.tags_all
}

# example/main.tf
module "s3_bucket" {
  source = "../"  # ou o caminho do módulo

  environment       = "prod"
  owner             = "time-plataforma"
  cost_center       = "CC-1234"
  bucket_name       = "data-lake"
  enable_versioning = true
  enable_logging    = true
  log_bucket_name   = "hvt-logs-prod"  # Bucke de logs deve existir previamente
  tags = {
    Projeto = "DataLake"
    ManagedBy = "Terraform"
  }
  force_destroy = false
}

output "bucket_id" {
  value = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.bucket_arn
}

# Explicação final

'''
Este módulo foi projetado seguindo o padrão interno: prefixo hvt-, tags obrigatórias via locals e merge(), e todos os requisitos de segurança (criptografia, versionamento, bloqueio público e logging). A estrutura modular é reutilizável e auto-documentada, com validações que garantem conformidade antes do deploy. O logging condicional e o tratamento seguro da variável log_bucket_name evitam erros em tempo de execução. As saídas expõem informações essenciais para os times consumidores, e o exemplo simplifica a adoção imediata.
'''