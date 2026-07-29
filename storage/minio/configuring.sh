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
# 192.168.194.159 keycloak.local, где 192.168.194.159 есть актуальный CLUSTER_IP для nginx-ingress-controller
INGRESS_SVC="nginx-ingress-controller"
INGRESS_NS="nginx-ingress"
COREDNS_CM="coredns"
COREDNS_NS="kube-system"

# 1. Получаем CLUSTER_IP Ingress Controller'а
echo "🔍 Получение CLUSTER_IP для $INGRESS_SVC..."
CLUSTER_IP=$(kubectl get svc "$INGRESS_SVC" -n "$INGRESS_NS" -o jsonpath='{.spec.clusterIP}')
if [ -z "$CLUSTER_IP" ]; then
    echo "❌ Ошибка: Не удалось получить CLUSTER_IP. Проверьте, установлен ли ingress-nginx."
    exit 1
fi
echo "✅ CLUSTER_IP найден: $CLUSTER_IP"

# 2. Формируем новую запись
ENTRY="$CLUSTER_IP keycloak.local"
echo "📝 Проверка и обновление записи в NodeHosts..."

# 3. Получаем текущее содержимое NodeHosts
CURRENT_HOSTS=$(kubectl get configmap "$COREDNS_CM" -n "$COREDNS_NS" -o jsonpath='{.data.NodeHosts}')

# 4. Умная замена через awk (работает одинаково на macOS и Linux)
# Логика: если строка заканчивается на 'keycloak.local', заменяем её. Иначе добавляем в конец.
NEW_HOSTS=$(echo "$CURRENT_HOSTS" | awk -v entry="$ENTRY" '
BEGIN { found=0 }
/keycloak\.local[[:space:]]*$/ { 
    print entry; 
    found=1; 
    next 
}
{ print }
END { 
    if (!found && entry != "") print entry 
}')

# 5. Проверяем, изменилось ли содержимое (чтобы не перезапускать CoreDNS зря)
if [ "$CURRENT_HOSTS" = "$NEW_HOSTS" ]; then
    echo "✅ Запись уже актуальна ($ENTRY). Пропускаем обновление ConfigMap."
else
    echo "⚙️ Обновляем NodeHosts (заменяем старую запись или добавляем новую)..."
    
    # БЕЗОПАСНОЕ экранирование переносов строк для JSON (без sed, работает везде!)
    # Первая строка печатается как есть, все последующие начинаются с \n
    ESCAPED_HOSTS=$(printf '%s' "$NEW_HOSTS" | awk 'NR==1{printf "%s", $0; next} {printf "\\n%s", $0}')
    
    # Применяем патч
    kubectl patch configmap "$COREDNS_CM" -n "$COREDNS_NS" --type merge \
        -p "{\"data\":{\"NodeHosts\":\"$ESCAPED_HOSTS\"}}"
    
    echo "✅ ConfigMap успешно обновлен."
    
    # 6. Перезапускаем CoreDNS для применения изменений
    echo "🔄 Перезапуск CoreDNS..."
    DEPLOYMENT_NAME=$(kubectl get deployments -n "$COREDNS_NS" -o jsonpath='{.items[?(@.metadata.labels.k8s-app=="kube-dns")].metadata.name}' 2>/dev/null || echo "coredns")
    
    kubectl rollout restart deployment "$DEPLOYMENT_NAME" -n "$COREDNS_NS"
    kubectl rollout status deployment "$DEPLOYMENT_NAME" -n "$COREDNS_NS" --timeout=60s
    echo "✅ CoreDNS перезапущен и готов."
fi


kubectl create secret generic minio-credentials -n "${NAMESPACE}" \
    --from-literal=clientId=${CLIENT_ID} \
    --from-literal=clientSecret=${CLIENT_SECRET} \
    --dry-run=client -o yaml | kubectl apply -f -
