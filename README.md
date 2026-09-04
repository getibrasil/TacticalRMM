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

    chmod +x install.sh

    sudo ./install.sh \
      --api https://api.example.com \
      --client-id 3 \
      --site-id 3 \
      --agent-type server \
      --auth 'SEU_TOKEN'

### Parâmetros obrigatórios

- --api — URL da API do Tactical RMM
- --client-id — ID do cliente
- --site-id — ID do site
- --auth — token de autenticação do instalador

### Parâmetros opcionais

- --agent-type — server ou workstation
- --description — descrição do agente
- --version — versão da Release
- --repo — repositório GitHub utilizado
- --no-mesh — não instalar Mesh
- --insecure — modo insecure para testes

Exemplo:

    sudo ./install.sh \
      --api https://api.example.com \
      --client-id 3 \
      --site-id 3 \
      --agent-type server \
      --description "Servidor Linux" \
      --auth 'SEU_TOKEN'

## Token de autenticação

O token de autenticação é informado manualmente durante a instalação.

Nenhum token de autenticação é armazenado neste repositório.

Nunca publique:

- tokens
- senhas
- chaves privadas
- credenciais
- arquivos de configuração contendo segredos

Exemplo:

    --auth 'SEU_TOKEN'

## Verificação SHA256

Antes de instalar o binário, o install.sh baixa o arquivo SHA256SUMS da mesma Release e compara o SHA256 esperado com o arquivo baixado.

Se a validação falhar, a instalação é interrompida.

Isso reduz o risco de instalar um binário diferente daquele publicado na Release.

## Releases

As Releases deste projeto utilizam binários compilados a partir de uma versão específica do código-fonte oficial do Tactical RMM Agent.

Cada Release deve identificar:

- versão do Tactical RMM Agent
- repositório de origem
- commit exato utilizado
- arquitetura do binário
- SHA256 dos arquivos distribuídos

Exemplo:

    Tactical RMM Agent: 2.11.0
    Source repository: https://github.com/amidaware/rmmagent
    Source commit: d81c5f94dec700d257b14518a1514866ef7f5cbf

## Build

O script build-release.sh permite compilar os binários Linux a partir do código-fonte oficial.

Exemplo:

    ./build-release.sh v2.11.0

O processo:

1. clona o repositório oficial;
2. seleciona um commit específico;
3. compila para Linux amd64;
4. compila para Linux arm64;
5. gera os hashes SHA256;
6. verifica os binários produzidos.

Estrutura esperada:

    dist/
    └── v2.11.0/
        ├── rmmagent-linux-amd64
        ├── rmmagent-linux-arm64
        └── SHA256SUMS

Os artefatos locais de build não são versionados no Git.

## Atualização

O update.sh permite atualizar o agente instalado.

A atualização preserva a configuração existente e realiza rollback caso a atualização falhe.

Exemplo:

    sudo ./update.sh

Consulte:

    ./update.sh --help

para as opções disponíveis.

## Desinstalação

O uninstall.sh remove o agente e o serviço systemd.

Por padrão, os arquivos de configuração podem ser preservados.

Para remover também os arquivos locais de configuração e logs:

    sudo ./uninstall.sh --purge

Consulte:

    ./uninstall.sh --help

para as opções disponíveis.

## Serviço systemd

O agente Linux é executado através do serviço:

    tacticalagent.service

Verificar o status:

    systemctl status tacticalagent

Iniciar:

    systemctl start tacticalagent

Parar:

    systemctl stop tacticalagent

Reiniciar:

    systemctl restart tacticalagent

Verificar inicialização automática:

    systemctl is-enabled tacticalagent

Ver logs:

    journalctl -u tacticalagent -f

## Arquivos utilizados

Binário:

    /usr/local/bin/rmmagent

Serviço:

    /etc/systemd/system/tacticalagent.service

Configuração do agente:

    /etc/tacticalagent/

Os arquivos de configuração e credenciais locais não fazem parte deste repositório.

## Segurança

Este projeto deve ser utilizado somente em sistemas para os quais exista autorização administrativa.

O Tactical RMM Agent possui recursos de gerenciamento remoto de sistemas. Portanto, sua utilização deve estar limitada a ambientes próprios ou devidamente autorizados.

Recomendações:

- utilize HTTPS na comunicação com a API;
- não compartilhe tokens de instalação;
- não publique credenciais;
- mantenha o servidor Tactical RMM atualizado;
- mantenha os agentes atualizados;
- valide os hashes das Releases;
- utilize VPN quando apropriado;
- restrinja o acesso administrativo;
- monitore regularmente os agentes registrados.

## Tactical RMM Agent

O Tactical RMM Agent é software de terceiros desenvolvido pela AmidaWare Inc.

Copyright © 2022 AmidaWare Inc.

O Tactical RMM Agent é licenciado sob a:

Tactical RMM License Version 1.0

A Tactical RMM License não é uma licença de software open source.

A utilização do Tactical RMM Agent está sujeita aos termos e restrições da licença oficial.

A licença oficial está disponível em:

https://license.tacticalrmm.com/

## Código-fonte oficial

O código-fonte oficial do Tactical RMM Agent está disponível em:

https://github.com/amidaware/rmmagent

Documentação oficial:

https://docs.tacticalrmm.com/

Licença oficial:

https://license.tacticalrmm.com/

## Proveniência

Os binários distribuídos pelas Releases deste projeto são compilados a partir do código-fonte oficial do Tactical RMM Agent.

Cada Release identifica a versão e o commit exato utilizados na compilação.

Exemplo:

    Version: 2.11.0
    Source repository: https://github.com/amidaware/rmmagent
    Source commit: d81c5f94dec700d257b14518a1514866ef7f5cbf
    Architecture: linux/amd64

Os arquivos SHA256SUMS fornecidos nas Releases permitem verificar a integridade dos binários distribuídos.

## Projeto independente

Este é um projeto independente e não oficial.

Este repositório não é:

- mantido pela AmidaWare Inc.;
- patrocinado pela AmidaWare Inc.;
- afiliado à AmidaWare Inc.;
- endossado pela AmidaWare Inc.

O nome Tactical RMM e suas marcas relacionadas pertencem à AmidaWare Inc.

Este projeto não pretende representar-se como uma distribuição oficial do Tactical RMM.

## Licença e software de terceiros

Este repositório contém scripts e ferramentas desenvolvidos pelo autor para instalação, atualização, remoção e compilação do Tactical RMM Agent em sistemas Linux.

O Tactical RMM Agent é software de terceiros.

Os direitos sobre o Tactical RMM Agent permanecem sujeitos à Tactical RMM License Version 1.0.

A licença oficial deve ser consultada antes de qualquer redistribuição, modificação ou utilização do Tactical RMM Agent em novos cenários.

O texto da licença oficial está disponível em:

https://license.tacticalrmm.com/

Informações adicionais sobre software de terceiros estão disponíveis em:

THIRD-PARTY-NOTICES.md

## Licenciamento deste projeto

Os scripts e ferramentas desenvolvidos especificamente para este repositório são independentes do código de terceiros utilizado para compilar o Tactical RMM Agent.

Nenhuma parte deste README concede direitos adicionais sobre o Tactical RMM Agent.

O código de terceiros permanece sujeito à sua respectiva licença.

## Aviso

Este projeto é fornecido sem garantia de funcionamento em todos os ambientes, distribuições Linux ou versões do Tactical RMM.

Recomenda-se testar novas versões em ambiente controlado antes de utilizá-las em produção.

---

## Autor

Projeto independente de automação e administração de sistemas Linux.

GitHub:

https://github.com/getibrasil/TacticalRMM
