#!/usr/bin/env bash

set -Eeuo pipefail

VERSION="latest"
REPO="getibrasil/TacticalRMM"
INSTALL_PATH="/usr/local/bin/rmmagent"
SERVICE_NAME="tacticalagent"
SERVICE_PATH="/etc/systemd/system/tacticalagent.service"

usage() {
    cat <<EOF
Tactical RMM Linux Updater

Uso:
  sudo ./update.sh [opções]

Opções:
  --version VERSION   Versão da release (default: latest)
  --repo OWNER/REPO   Repositório GitHub
  -h, --help          Mostra esta ajuda
EOF
}

error() {
    echo "[ERRO] $*" >&2
    exit 1
}

cleanup() {
    rm -f "${TMP_BINARY:-}" "${TMP_SUMS:-}" "${BACKUP_BINARY:-}"
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VERSION="${2:-}"
            shift 2
            ;;
        --repo)
            REPO="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || error "Execute como root."

[[ -x "${INSTALL_PATH}" ]] ||
    error "Agente não encontrado em ${INSTALL_PATH}."

[[ -f "/etc/tacticalagent" ]] ||
    error "Configuração do agente não encontrada."

[[ -f "${SERVICE_PATH}" ]] ||
    error "Serviço systemd não encontrado."

command -v curl >/dev/null 2>&1 ||
    error "curl não está instalado."

command -v sha256sum >/dev/null 2>&1 ||
    error "sha256sum não está disponível."

ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64|amd64)
        ASSET="rmmagent-linux-amd64"
        ;;
    aarch64|arm64)
        ASSET="rmmagent-linux-arm64"
        ;;
    *)
        error "Arquitetura não suportada: ${ARCH}"
        ;;
esac

if [[ "${VERSION}" == "latest" ]]; then
    RELEASE_URL="https://github.com/${REPO}/releases/latest/download"
else
    RELEASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"
fi

TMP_BINARY="$(mktemp)"
TMP_SUMS="$(mktemp)"
BACKUP_BINARY="$(mktemp)"

echo "[+] Arquitetura: ${ARCH}"
echo "[+] Asset: ${ASSET}"
echo "[+] Release: ${VERSION}"

echo "[+] Baixando nova versão..."

curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    "${RELEASE_URL}/${ASSET}" \
    -o "${TMP_BINARY}" ||
    error "Falha ao baixar o agente."

curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    "${RELEASE_URL}/SHA256SUMS" \
    -o "${TMP_SUMS}" ||
    error "Falha ao baixar SHA256SUMS."

EXPECTED_HASH="$(
    awk -v file="${ASSET}" '
        $2 == file || $2 == "*" file {
            print $1
            exit
        }
    ' "${TMP_SUMS}"
)"

[[ -n "${EXPECTED_HASH}" ]] ||
    error "Hash SHA256 não encontrado."

ACTUAL_HASH="$(sha256sum "${TMP_BINARY}" | awk '{print $1}')"

[[ "${EXPECTED_HASH}" == "${ACTUAL_HASH}" ]] ||
    error "SHA256 inválido. A atualização foi cancelada."

echo "[+] SHA256 validado."

chmod 0755 "${TMP_BINARY}"

cp -a "${INSTALL_PATH}" "${BACKUP_BINARY}"

echo "[+] Parando agente..."

systemctl stop "${SERVICE_NAME}"

echo "[+] Instalando nova versão..."

install \
    -o root \
    -g root \
    -m 0755 \
    "${TMP_BINARY}" \
    "${INSTALL_PATH}"

systemctl daemon-reload
systemctl start "${SERVICE_NAME}"

sleep 2

if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo
    echo "========================================"
    echo " Atualização concluída!"
    echo "========================================"
    echo
    "${INSTALL_PATH}" -version
    echo
    exit 0
fi

echo
echo "[ERRO] Nova versão não iniciou."
echo "[+] Restaurando versão anterior..."

systemctl stop "${SERVICE_NAME}" || true

install \
    -o root \
    -g root \
    -m 0755 \
    "${BACKUP_BINARY}" \
    "${INSTALL_PATH}"

systemctl start "${SERVICE_NAME}"

sleep 2

if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "[+] Rollback concluído. Versão anterior restaurada."
else
    echo "[ERRO] Rollback também falhou."
    systemctl status "${SERVICE_NAME}" --no-pager || true
    journalctl -u "${SERVICE_NAME}" -n 50 --no-pager || true
    exit 1
fi
