#!/bin/bash

# Указать домены где требуется сертификат и namespace в котором будет развёрнут k8s secret
# Если не хотите видеть в браузере Not Secure, придётся добавить домен в список
DOMAINS=("airflow.local" "flower.local" "gitlab.local" "minio.local")
namespaces=("airflow" "gitlab" "minio")
# В случае изменении SECRET_NAME, необходимо поменять во всех values-minimum.yaml для helm
SECRET_NAME="wildcard-local-tls"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Начинаем настройку TLS для локальных сервисов...${NC}"

# 1. Проверка наличия mkcert
if ! command -v mkcert &> /dev/null; then
    echo -e "${RED}❌ mkcert не установлен. Установите его:${NC}"
    echo "  macOS: brew install mkcert"
    echo "  Linux: https://github.com/FiloSottile/mkcert#installation"
    echo "  Windows: choco install mkcert"
    exit 1
fi

echo -e "${GREEN}✅ mkcert найден.${NC}"

# 2. Проверка, установлен ли CA
if ! mkcert -CAROOT &> /dev/null; then
    echo -e "${YELLOW}⚠️  CA ещё не установлен. Выполняем mkcert -install...${NC}"
    # После выполнения удостовертесь, что: The local CA is now installed in the system trust store! ⚡️
    mkcert -install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка при установке CA. Попробуйте выполнить вручную: mkcert -install${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ CA успешно установлен.${NC}"
else
    echo -e "${GREEN}✅ CA уже установлен.${NC}"
fi

# 3. Создание сертификата с несколькими доменами
CERT_NAME="wildcard-local"
echo -e "${YELLOW}📝 Генерируем сертификат для: ${DOMAINS[*]}${NC}"

# Удаляем старые файлы (если есть)
rm -f "${CERT_NAME}"*.pem "${CERT_NAME}"*.key.pem

mkcert -cert-file "${CERT_NAME}".pem -key-file "${CERT_NAME}"-key.pem "${DOMAINS[@]}"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при генерации сертификата.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Сертификат успешно создан: ${CERT_NAME}.pem и ${CERT_NAME}-key.pem${NC}"

# 4. Создание TLS-секретов в namespace'ах
for ns in "${namespaces[@]}"; do
    echo -e "\n${YELLOW}📦 Создаём TLS-секрет для namespace '${ns}'...${NC}"

    # Проверяем, существует ли namespace
    if ! kubectl get namespace "$ns" &> /dev/null; then
        echo -e "${RED}❌ Namespace '$ns' не существует. Пропускаем.${NC}"
        continue
    fi

    # Создаём секрет
    kubectl create secret tls "$SECRET_NAME" \
      --namespace "$ns" \
      --cert="${CERT_NAME}.pem" \
      --key="${CERT_NAME}-key.pem" \
      --dry-run=client -o yaml | kubectl apply -f -

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Секрет '$SECRET_NAME' успешно создан в namespace '$ns'.${NC}"
    else
        echo -e "${RED}❌ Ошибка при создании секрета в namespace '$ns'.${NC}"
    fi
done

echo -e "\n${GREEN}🎉 Все действия завершены успешно!${NC}"