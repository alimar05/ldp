#!/bin/bash

NAMESPACE="minio"
CLIENT_ID="minio"
CLIENT_SECRET="56CtYjbL52cwzFCwFSbFGSlC0GrPsdCr"
# coredns
INGRESS_NS="nginx-ingress"
INGRESS_SVC="nginx-ingress-controller"
COREDNS_NS="kube-system"
COREDNS_CM="coredns"

# MinIO (в отличие от JupyterHub, Vault и Airflow) не умеет разделять URL для браузера и для бэкенда. Он слепо следует спецификации OIDC и использует абсолютные URL из файла .well-known/openid-configuration, который отдает Keycloak.
# Что происходит без CoreDNS
# Keycloak настроен с KC_HOSTNAME: keycloak.local → генерирует .well-known с HTTPS-ссылками
# MinIO скачивает .well-known, видит там https://keycloak.local/.../token
# MinIO (изнутри пода) пытается сделать POST-запрос на https://keycloak.local
# Провал: под MinIO не может резолвить keycloak.local → i/o timeout
# Поэтому нужно добавить в NodeHosts (в ConfigMap coredns):
# 192.168.194.159 keycloak.local, где 192.168.194.159 есть CLUSTER_IP nginx-ingress-controller

# 1. Получаем CLUSTER_IP Ingress Controller'а
echo "🔍 Получение CLUSTER_IP для $INGRESS_SVC..."
CLUSTER_IP=$(kubectl get svc "$INGRESS_SVC" -n "$INGRESS_NS" -o jsonpath='{.spec.clusterIP}')
if [ -z "$CLUSTER_IP" ]; then
    echo "❌ Ошибка: Не удалось получить CLUSTER_IP. Проверьте, установлен ли ingress-nginx."
    exit 1
fi
echo "✅ CLUSTER_IP найден: $CLUSTER_IP"

# 2. Обновляем NodeHosts в ConfigMap coredns
ENTRY="$CLUSTER_IP keycloak.local"
echo "📝 Проверка записи в NodeHosts..."

# 3. Получаем текущее содержимое NodeHosts
CURRENT_HOSTS=$(kubectl get configmap "$COREDNS_CM" -n "$COREDNS_NS" -o jsonpath='{.data.NodeHosts}')

if echo "$CURRENT_HOSTS" | grep -qF "$ENTRY"; then
    echo "✅ Запись '$ENTRY' уже существует в NodeHosts. Пропускаем обновление."
else
    echo "⚙️ Добавляем запись '$ENTRY' в NodeHosts..."
    
    # Формируем новое содержимое (добавляем перенос строки и новую запись)
    NEW_HOSTS="${CURRENT_HOSTS}"$'\n'"${ENTRY}"
    
    # Экранируем переносы строк для JSON patch
    ESCAPED_HOSTS=$(echo "$NEW_HOSTS" | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
    
    # Применяем патч
    kubectl patch configmap "$COREDNS_CM" -n "$COREDNS_NS" --type merge \
        -p "{\"data\":{\"NodeHosts\":\"$ESCAPED_HOSTS\"}}"
    
    echo "✅ ConfigMap обновлен."
    
    # 3. Перезапускаем CoreDNS для применения изменений
    echo "🔄 Перезапуск CoreDNS..."
    # Пробуем найти deployment с именем coredns или kube-dns (зависит от версии k8s/orbstack)
    DEPLOYMENT_NAME=$(kubectl get deployments -n "$COREDNS_NS" -o jsonpath='{.items[?(@.metadata.labels.k8s-app=="kube-dns")].metadata.name}' || echo "coredns")
    
    kubectl rollout restart deployment "$DEPLOYMENT_NAME" -n "$COREDNS_NS"
    kubectl rollout status deployment "$DEPLOYMENT_NAME" -n "$COREDNS_NS" --timeout=60s
    echo "✅ CoreDNS перезапущен."
fi


kubectl create secret generic minio-credentials -n "${NAMESPACE}" \
    --from-literal=clientId=${CLIENT_ID} \
    --from-literal=clientSecret=${CLIENT_SECRET} \
    --dry-run=client -o yaml | kubectl apply -f -
