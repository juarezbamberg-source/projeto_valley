# ============================================
# variables.tf
# ============================================

# Variável: environment
# Descrição: Ambiente onde o bucket será criado (ex: dev, staging, prod)
variable "environment" {
  description = "Ambiente onde o bucket será criado (ex: dev, staging, prod)"
  type        = string
}

# Variável: owner
# Descrição: Nome ou equipe responsável pelo bucket
variable "owner" {
  description = "Nome ou equipe responsável pelo bucket"
  type        = string
}

# Variável: cost_center
# Descrição: Centro de custo para alocação financeira
variable "cost_center" {
  description = "Centro de custo para alocação financeira"
  type        = string
}

# Variável: bucket_name
# Descrição: Nome base do bucket (sem prefixo hvt-). Será concatenado automaticamente.
variable "bucket_name" {
  description = "Nome base do bucket (sem prefixo hvt-). Será concatenado automaticamente."
  type        = string
}

# Variável: enable_versioning
# Descrição: Habilita versionamento no bucket (default: true)
variable "enable_versioning" {
  description = "Habilita versionamento no bucket (default: true)"
  type        = bool
  default     = true
}

# Variável: enable_logging
# Descrição: Habilita logging de acesso ao bucket (default: true). Necessário informar log_bucket_name.
variable "enable_logging" {
  description = "Habilita logging de acesso ao bucket (default: true). Necessário informar log_bucket_name."
  type        = bool
  default     = true
}

# Variável: log_bucket_name
# Descrição: Nome do bucket de destino para logs (obrigatório se enable_logging = true)
variable "log_bucket_name" {
  description = "Nome do bucket de destino para logs (obrigatório se enable_logging = true)"
  type        = string
  default     = ""
}

# Variável: tags_extra
# Descrição: Tags adicionais que serão mescladas com as tags obrigatórias
variable "tags_extra" {
  description = "Tags adicionais que serão mescladas com as tags obrigatórias"
  type        = map(string)
  default     = {}
}

# ============================================
# main.tf
# ============================================

# Locals: tags comuns obrigatórias e merge com tags extras
locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
  all_tags = merge(local.common_tags, var.tags_extra)
  # Nome final do bucket com prefixo hvt-
  bucket_name_full = "hvt-${var.bucket_name}"
}

# Recurso: aws_s3_bucket
# Cria o bucket S3 com prefixo hvt- e tags mescladas
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name_full
  tags   = local.all_tags
}

# Recurso: aws_s3_bucket_versioning
# Habilita versionamento conforme variável enable_versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Recurso: aws_s3_bucket_server_side_encryption_configuration
# Configura criptografia SSE-S3 (AES256) por padrão
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Recurso: aws_s3_bucket_public_access_block
# Bloqueia todo acesso público ao bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Recurso: aws_s3_bucket_logging
# Configura logging condicionalmente (se enable_logging e log_bucket_name informado)
resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging && length(var.log_bucket_name) > 0 ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.log_bucket_name
  target_prefix = "logs/${local.bucket_name_full}/"
}

# ============================================
# outputs.tf
# ============================================

output "bucket_id" {
  description = "ID do bucket S3 criado"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3 criado"
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Região onde o bucket foi criado"
  value       = aws_s3_bucket.this.region
}

output "bucket_domain_name" {
  description = "Nome de domínio do bucket (para uso com CloudFront, etc)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Nome de domínio regional do bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "versioning_status" {
  description = "Status do versionamento (Enabled ou Suspended)"
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

# ============================================
# example/main.tf
# ============================================

# Exemplo de utilização do módulo hvt-s3
# Este exemplo cria um bucket com as configurações obrigatórias.

module "s3_example" {
  source = "../"  # Caminho relativo ao módulo (ajuste conforme necessário)

  # Variáveis obrigatórias
  environment = "prod"
  owner       = "Plataforma"
  cost_center = "CC-12345"
  bucket_name = "meu-bucket-aplicacao"

  # Variáveis opcionais (valores padrão já atendem às boas práticas)
  enable_versioning = true
  enable_logging    = true
  log_bucket_name   = "hvt-bucket-logs-global"  # Bucket de logs já existente

  # Tags extras (opcional)
  tags_extra = {
    Application = "MinhaApp"
    ManagedBy   = "Terraform"
  }
}

# Output do módulo para referência
output "example_bucket_id" {
  value = module.s3_example.bucket_id
}

output "example_bucket_arn" {
  value = module.s3_example.bucket_arn
}