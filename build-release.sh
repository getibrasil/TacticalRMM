#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${1:-}"

if [[ -z "${VERSION}" ]]; then
    echo "Uso:"
    echo "  ./build-release.sh v2.11.0"
    exit 1
fi

if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[ERRO] Versão deve estar no formato vX.Y.Z"
    exit 1
fi

SOURCE_REPO="https://github.com/amidaware/rmmagent.git"
SOURCE_COMMIT="d81c5f94dec700d257b14518a1514866ef7f5cbf"

WORK_DIR="$(mktemp -d)"
DIST_DIR="$(pwd)/dist/${VERSION}"

cleanup() {
    rm -rf "${WORK_DIR}"
}

trap cleanup EXIT

command -v git >/dev/null 2>&1 || {
    echo "[ERRO] git não instalado."
    exit 1
}

command -v go >/dev/null 2>&1 || {
    echo "[ERRO] Go não instalado."
    exit 1
}

echo "========================================"
echo " Tactical RMM - Build Release"
echo "========================================"
echo
echo "[+] Versão: ${VERSION}"
echo "[+] Repositório: ${SOURCE_REPO}"
echo "[+] Commit: ${SOURCE_COMMIT}"
echo

echo "[+] Clonando fonte oficial..."
git clone "${SOURCE_REPO}" "${WORK_DIR}/rmmagent"

cd "${WORK_DIR}/rmmagent"

echo "[+] Checkout do commit fixo..."
git checkout "${SOURCE_COMMIT}"

echo
echo "[+] Commit utilizado:"
git rev-parse HEAD

echo
echo "[+] Verificando versão do código..."
grep -RniE 'Version.*2\.11|2\.11\.0' --include='*.go' . | head -20 || true

mkdir -p "${DIST_DIR}"

echo
echo "[+] Compilando Linux amd64..."
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" \
    -o "${DIST_DIR}/rmmagent-linux-amd64" \
    .

echo "[+] amd64 concluído."

echo
echo "[+] Compilando Linux arm64..."
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 \
    go build -ldflags="-s -w" \
    -o "${DIST_DIR}/rmmagent-linux-arm64" \
    .

echo "[+] arm64 concluído."

cd "${DIST_DIR}"

chmod 0755 \
    rmmagent-linux-amd64 \
    rmmagent-linux-arm64

echo
echo "[+] Gerando SHA256SUMS..."
sha256sum \
    rmmagent-linux-amd64 \
    rmmagent-linux-arm64 \
    > SHA256SUMS

echo
echo "========================================"
echo " Release preparada"
echo "========================================"
echo
echo "Diretório:"
echo "  ${DIST_DIR}"
echo
echo "Arquivos:"
ls -lh

echo
echo "SHA256:"
cat SHA256SUMS

echo
echo "[+] Verificando versão amd64..."
./rmmagent-linux-amd64 -version || true

echo
echo "[+] Verificando formato dos binários..."
file \
    rmmagent-linux-amd64 \
    rmmagent-linux-arm64

echo
echo "========================================"
echo " BUILD CONCLUÍDO"
echo "========================================"
