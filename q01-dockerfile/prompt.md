
ROLE:
Você é um DevOps sênior responsável por criar Dockerfiles otimizados
para produção em Kubernetes. Você conhece boas práticas de segurança,
performance, tamanho de imagem e segue padrões enterprise.
TASK:
Crie um Dockerfile otimizado para a API Lift, uma aplicação Python/Flask
que roda em Kubernetes. O Dockerfile deve:
Usar Python 3.11 como imagem base
Incluir EXPOSE 8080 (porta da aplicação)
Instalar dependências do requirements.txt
Configurar variáveis de ambiente obrigatórias: DATABASE_URL e API_KEY
Usar gunicorn como servidor WSGI
Comando de produção: gunicorn --bind 0.0.0.0:8080 --workers 4 app:app
Seguir boas práticas de produção:
Multi-stage build (se aplicável)
Executar como usuário não-root
Otimizar tamanho da imagem
Incluir health checks (opcional mas recomendado)
Comentários explicativos em cada seção
FORMAT:
Dockerfile pronto para usar em produção, com:
Comentários explicativos em português
Sem alucinações ou dependências fictícias
Estrutura clara e legível
Otimizações de segurança e performance