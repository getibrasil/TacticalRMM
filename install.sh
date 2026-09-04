#!/usr/bin/env bash

set -Eeuo pipefail

VERSION="v2.11.0"
REPO="getibrasil/TacticalRMM"
INSTALL_PATH="/usr/local/bin/rmmagent"
SERVICE_PATH="/etc/systemd/system/tacticalagent.service"

API=""
CLIENT_ID=""
SITE_ID=""
AGENT_TYPE="server"
AUTH=""
DESCRIPTION=""
NO_MESH="false"
INSECURE="false"

usage() {
    cat <<EOF
Tactical RMM Linux Installer

Uso:
  sudo ./install.sh [opções]

Obrigatórios:
  --api URL
  --client-id ID
  --site-id ID
  --auth TOKEN

Opcionais:
  --agent-type TYPE       server ou workstation (default: server)
  --description TEXT      Descrição do agente
  --version VERSION       Versão da release (default: ${VERSION})
  --repo OWNER/REPO       Repositório GitHub
  --no-mesh               Não instalar Mesh
  --insecure              Insecure para testes
  -h, --help              Mostra esta ajuda

Exemplo:
  sudo ./install.sh \\
    --api https://api.getibrasil.com.br \\
    --client-id 3 \\
    --site-id 3 \\
    --agent-type server \\
    --auth 'SEU_TOKEN'
EOF
}

log() {
    echo "[+] $*"
}

error() {
    echo "[ERRO] $*" >&2
    exit 1
}

cleanup() {
    rm -f "${TMP_BINARY:-}" "${TMP_SUMS:-}"
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --api)
            API="${2:-}"
            shift 2
            ;;
        --client-id)
            CLIENT_ID="${2:-}"
            shift 2
            ;;
        --site-id)
            SITE_ID="${2:-}"
            shift 2
            ;;
        --agent-type)
            AGENT_TYPE="${2:-}"
            shift 2
            ;;
        --auth)
            AUTH="${2:-}"
            shift 2
            ;;
        --description)
            DESCRIPTION="${2:-}"
            shift 2
            ;;
        --version)
            VERSION="${2:-}"
            shift 2
            ;;
        --repo)
            REPO="${2:-}"
            shift 2
            ;;
        --no-mesh)
            NO_MESH="true"
            shift
            ;;
        --insecure)
            INSECURE="true"
            shift
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

[[ -n "${API}" ]] || error "--api é obrigatório."
[[ -n "${CLIENT_ID}" ]] || error "--client-id é obrigatório."
[[ -n "${SITE_ID}" ]] || error "--site-id é obrigatório."
[[ -n "${AUTH}" ]] || error "--auth é obrigatório."

case "${AGENT_TYPE}" in
    server|workstation)
        ;;
    *)
        error "--agent-type deve ser 'server' ou 'workstation'."
        ;;
esac

if [[ -e "${SERVICE_PATH}" || -d "/etc/tacticalagent" ]]; then
    error "Este computador já possui uma instalação Tactical RMM. Use update.sh para atualizar ou uninstall.sh para remover."
fi

if ! command -v curl >/dev/null 2>&1; then
    log "Instalando curl..."
    apt-get update
    apt-get install -y curl
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    error "sha256sum não encontrado."
fi

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

log "Arquitetura detectada: ${ARCH}"
log "Asset: ${ASSET}"
log "Release: ${VERSION}"
log "Repositório: ${REPO}"

log "Baixando agente..."

curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    "${RELEASE_URL}/${ASSET}" \
    -o "${TMP_BINARY}" \
    || error "Falha ao baixar o agente."

log "Baixando SHA256SUMS..."

curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    "${RELEASE_URL}/SHA256SUMS" \
    -o "${TMP_SUMS}" \
    || error "Falha ao baixar SHA256SUMS."

EXPECTED_HASH="$(
    awk -v file="${ASSET}" '
        $2 == file || $2 == "*" file {
            print $1
            exit
        }
    ' "${TMP_SUMS}"
)"

[[ -n "${EXPECTED_HASH}" ]] ||
    error "Hash SHA256 do asset não encontrado em SHA256SUMS."

ACTUAL_HASH="$(sha256sum "${TMP_BINARY}" | awk '{print $1}')"

if [[ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]]; then
    error "Falha na validação SHA256!"
fi

log "SHA256 validado."

chmod 0755 "${TMP_BINARY}"

log "Instalando ${INSTALL_PATH}..."

install -o root -g root -m 0755 "${TMP_BINARY}" "${INSTALL_PATH}"

log "Executando instalador oficial do Tactical RMM..."

INSTALL_ARGS=(
    -m install
    -api "${API}"
    -client-id "${CLIENT_ID}"
    -site-id "${SITE_ID}"
    -agent-type "${AGENT_TYPE}"
    -auth "${AUTH}"
)

if [[ -n "${DESCRIPTION}" ]]; then
    INSTALL_ARGS+=(
        -desc "${DESCRIPTION}"
    )
fi

if [[ "${NO_MESH}" == "true" ]]; then
    INSTALL_ARGS+=(
        -nomesh
    )
fi

if [[ "${INSECURE}" == "true" ]]; then
    INSTALL_ARGS+=(
        -insecure
    )
fi

"${INSTALL_PATH}" "${INSTALL_ARGS[@]}"

log "Criando serviço systemd..."

cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=Tactical RMM Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${INSTALL_PATH} -m svc
Restart=always
RestartSec=12
User=root
Group=root
WorkingDirectory=/usr/local/bin

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "${SERVICE_PATH}"

systemctl daemon-reload
systemctl enable tacticalagent.service

log "Iniciando agente..."

systemctl restart tacticalagent.service

sleep 2

if ! systemctl is-active --quiet tacticalagent.service; then
    echo
    echo "========================================"
    echo " ERRO: agente não iniciou"
    echo "========================================"
    echo
    systemctl status tacticalagent.service --no-pager || true
    echo
    journalctl -u tacticalagent.service -n 50 --no-pager || true
    exit 1
fi

echo
echo "========================================"
echo " Tactical RMM instalado com sucesso!"
echo "========================================"
echo
echo "Binário : ${INSTALL_PATH}"
echo "Serviço : tacticalagent.service"
echo "Status  : $(systemctl is-active tacticalagent.service)"
echo "Boot    : $(systemctl is-enabled tacticalagent.service)"
echo
echo "Verifique com:"
echo "  systemctl status tacticalagent"
echo
echo "Logs:"
echo "  journalctl -u tacticalagent -f"
echo
