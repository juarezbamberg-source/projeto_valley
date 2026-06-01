# Q06 - Módulo Terraform S3 no Padrão Interno | Prompt C-A-R-E

## Framework Utilizado
**C-A-R-E (Context, Action, Result, Example)**

## Prompt Estruturado

### CONTEXT:
A empresa segue um padrão interno obrigatório de IaC (Infrastructure as Code) 
para todos os módulos Terraform novos. O padrão estabelecido por Strickland 
(segurança e compliance) exige:

1. Tags obrigatórias em todo recurso: Owner, CostCenter, Environment
2. Prefixo hvt- nos nomes de recursos
3. Todo bucket S3 com:
   - Encryption habilitada (SSE-S3 mínimo)
   - Versioning ativo
   - Block public access total
   - Logging configurado
4. Variáveis de entrada em variables.tf com description e type obrigatórios
5. Estilo e estrutura: seguir o padrão do módulo VPC existente

O módulo será consumido por todos os times da empresa, então precisa ser 
reutilizável, bem documentado e fácil de usar.

### ACTION:
Crie um módulo Terraform reutilizável para criar buckets S3 aderentes ao padrão 
interno, executando as seguintes ações:

1. Criar variables.tf com:
   - environment (string, description obrigatória)
   - owner (string, description obrigatória)
   - cost_center (string, description obrigatória)
   - bucket_name (string, description obrigatória)
   - enable_versioning (bool, default true, description obrigatória)
   - enable_logging (bool, default true, description obrigatória)
   - log_bucket_name (string, optional, description obrigatória)
   - Outras variáveis necessárias para configuração completa

2. Criar main.tf com:
   - locals com common_tags (Owner, CostCenter, Environment)
   - aws_s3_bucket com prefixo hvt-, tags usando merge(local.common_tags, {...})
   - aws_s3_bucket_versioning (habilitado)
   - aws_s3_bucket_server_side_encryption_configuration (SSE-S3)
   - aws_s3_bucket_public_access_block (bloqueio total)
   - aws_s3_bucket_logging (se enable_logging = true)
   - Comentários explicando cada seção

3. Criar outputs.tf com:
   - bucket_id
   - bucket_arn
   - bucket_region
   - Outras saídas úteis

4. Criar exemplo de uso (example/main.tf) mostrando como consumir o módulo

5. Incluir comentários explicativos em todas as seções

### RESULT:
Um módulo Terraform S3 que:
- Segue exatamente o padrão interno de IaC
- É reutilizável por todos os times
- Implementa todas as práticas de segurança e compliance obrigatórias
- Está bem documentado e fácil de consumir
- Segue o mesmo estilo e estrutura do módulo VPC existente
- Está pronto para ser publicado e usado em produção

### EXAMPLE:
Referência de estilo do módulo VPC existente:

variable "environment" {
  description = "Nome do ambiente (dev, staging, production)"
  type        = string
}

locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = merge(local.common_tags, {
    Name = "hvt-vpc-${var.environment}"
  })
}

Siga este mesmo padrão para o módulo S3: use locals para common_tags, 
use merge() para combinar tags, use prefixo hvt- nos nomes de recursos, 
e mantenha a mesma estrutura e estilo de código.

## Componentes do Framework C-A-R-E

| Componente | Descrição | Aplicação na Q06 |
|-----------|-----------|------------------|
| **Context** | Contexto e padrões da empresa | Padrão interno de IaC, tags obrigatórias, prefixo hvt-, requisitos S3 |
| **Action** | Ações específicas a executar | Criar módulo Terraform S3 com variables.tf, main.tf, outputs.tf, exemplo |
| **Result** | Resultado esperado | Módulo reutilizável, aderente ao padrão, pronto para consumo |
| **Example** | Exemplo de referência | Módulo VPC existente (estilo, estrutura, naming, locals, merge de tags) |

## Contexto Técnico

- **Aplicação:** Módulo Terraform S3
- **Padrão:** Interno da empresa (Strickland - segurança e compliance)
- **Consumidores:** Todos os times da empresa
- **Requisitos:** Tags obrigatórias, prefixo hvt-, encryption, versioning, block public access, logging
- **Estilo de referência:** Módulo VPC existente
- **Formato de saída:** Módulo Terraform completo (variables.tf, main.tf, outputs.tf, example/main.tf)