apiVersion: v1
kind: Secret
metadata:
  name: chronos-secret
  labels:
    app: chronos
type: Opaque
# As credenciais devem ser codificadas em base64.
# Exemplo: echo -n "senhadb" | base64
data:
  DB_PASSWORD: "c2VuaGFkYg=="   # valor real deve ser substituído
  JWT_SECRET: "andRc2VjcmV0"   # valor real deve ser substituído
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chronos-deployment
  labels:
    app: chronos
spec:
  # Alta disponibilidade com 3 réplicas
  replicas: 3
  selector:
    matchLabels:
      app: chronos
  template:
    metadata:
      labels:
        app: chronos
    spec:
      # Configuração de segurança para executar como usuário não-root
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: chronos
          # Imagem versionada (v1.2.3)
          image: chronos:v1.2.3
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
              protocol: TCP
          # Variáveis de ambiente obtidas do Secret
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: chronos-secret
                  key: DB_PASSWORD
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: chronos-secret
                  key: JWT_SECRET
          # Probes de saúde e prontidão
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
          # Recursos computacionais com limites e requisições
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          # Segurança adicional no container
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
---
apiVersion: v1
kind: Service
metadata:
  name: chronos-service
  labels:
    app: chronos
spec:
  # Exposição segura via ClusterIP (sem expor externamente)
  type: ClusterIP
  ports:
    - protocol: TCP
      port: 80          # porta interna do cluster
      targetPort: 3000  # porta do container
  selector:
    app: chronos