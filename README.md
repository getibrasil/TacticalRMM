# Tactical RMM Linux Installer

Scripts para instalação, atualização e remoção do agente Linux do Tactical RMM.

O agente utilizado neste projeto é compilado a partir do código oficial do Tactical RMM:

https://github.com/amidaware/rmmagent

## Recursos

- Instalação automatizada do agente Linux
- Suporte a Linux amd64 e arm64
- Validação SHA256 antes da instalação
- Serviço systemd automático
- Inicialização automática no boot
- Atualização com rollback automático
- Desinstalação opcionalmente preservando configuração
- Token de autenticação informado manualmente
- Nenhum token armazenado no repositório

## Requisitos

- Linux amd64 ou arm64
- systemd
- curl
- sha256sum
- acesso à Internet para baixar a Release
- privilégios de root
- agente compatível com a versão publicada

## Instalação

Baixe uma Release e execute:

```bash
sudo ./install.sh \
  --api https://api.example.com \
  --client-id 3 \
  --site-id 3 \
  --agent-type server \
  --auth 'SEU_TOKEN'
