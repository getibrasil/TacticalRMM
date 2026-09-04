#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_PATH="/usr/local/bin/rmmagent"
SERVICE_NAME="tacticalagent"
SERVICE_PATH="/etc/systemd/system/tacticalagent.service"
CONFIG_DIR="/etc/tacticalagent"
LOG_FILE="/var/log/tacticalagent.log"

PURGE="false"

usage() {
    cat <<EOF
Tactical RMM Linux Uninstaller

Uso:
  sudo ./uninstall.sh
  sudo ./uninstall.sh --purge

Sem --purge:
  Remove o serviço e o binário.
  Preserva configuração e logs.

Com --purge:
  Remove também:
    ${CONFIG_DIR}
    ${LOG_FILE}
EOF
}

[[ "${EUID}" -eq 0 ]] || {
    echo "[ERRO] Execute como root."
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge)
            PURGE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[ERRO] Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

echo "[+] Parando serviço..."

systemctl stop "${SERVICE_NAME}" 2>/dev/null || true

echo "[+] Desabilitando serviço..."

systemctl disable "${SERVICE_NAME}" 2>/dev/null || true

if [[ -f "${SERVICE_PATH}" ]]; then
    rm -f "${SERVICE_PATH}"
fi

systemctl daemon-reload

if [[ -f "${INSTALL_PATH}" ]]; then
    rm -f "${INSTALL_PATH}"
fi

if [[ "${PURGE}" == "true" ]]; then
    echo "[+] Removendo configuração..."
    rm -rf "${CONFIG_DIR}"

    echo "[+] Removendo log..."
    rm -f "${LOG_FILE}"
fi

echo
echo "========================================"
echo " Tactical RMM removido localmente."
echo "========================================"
echo
echo "ATENÇÃO:"
echo "A remoção local não remove automaticamente"
echo "o agente do dashboard do Tactical RMM."
echo

if [[ "${PURGE}" == "false" ]]; then
    echo "Configuração preservada em:"
    echo "  ${CONFIG_DIR}"
    echo
    echo "Para remover também:"
    echo "  sudo ./uninstall.sh --purge"
fi
