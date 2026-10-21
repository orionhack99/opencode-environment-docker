# 🛡️ OpenCode + Herdr — Sandbox de Segurança Ofensiva (Docker)

[![Build](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml/badge.svg)](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Base](https://img.shields.io/badge/base-kali--rolling-363636)](https://www.kali.org/)
[![OpenCode](https://img.shields.io/badge/OpenCode-v2-111111)](https://opencode.ai)
[![Herdr](https://img.shields.io/badge/Herdr-stable-111111)](https://herdr.dev)

Ambiente **isolado em Docker** que combina:

| Componente | O que é |
|---|---|
| **Kali Linux rolling** | Base com o repositório Kali configurado — **sem** ferramentas pré-instaladas (você instala o que precisa) |
| **OpenCode** | Agente de IA que lê, escreve e executa comandos no seu projeto |
| **Herdr** | Painel TUI de *workspaces / tabs / panes* que gerencia vários agentes em paralelo |

O objetivo é dar ao agente de IA um **laboratório descartável**: você aponta o
OpenCode para um alvo, ele ataca, e o estrago fica dentro do container.

**🇧🇷 Português (BR)** · **🇬🇧 [English](#english)**

---

## 📋 Sumário

- [Português (BR)](#português--br)
  - [Requisitos](#requisitos)
  - [Início rápido](#início-rápido)
  - [Como usar](#como-usar)
  - [Atalhos do Herdr](#atalhos-do-herdr)
  - [O que já vem na imagem](#o-que-já-vem-na-imagem)
  - [Volumes e persistência](#volumes-e-persistência)
  - [Rede e isolamento](#rede-e-isolamento)
  - [⚠️ Segurança e uso responsável](#️-segurança-e-uso-responsável)
  - [Atualizando](#atualizando)
  - [Personalizando](#personalizando)
  - [Solução de problemas](#solução-de-problemas)
  - [Estrutura do projeto](#estrutura-do-projeto)
- [English](#english)
  - [Requirements](#requirements)
  - [Quick start](#quick-start)
  - [Usage](#usage)
  - [Herdr shortcuts](#herdr-shortcuts)
  - [What ships in the image](#what-ships-in-the-image)
  - [Volumes and persistence](#volumes-and-persistence)
  - [Network and isolation](#network-and-isolation)
  - [⚠️ Security and responsible use](#️-security-and-responsible-use)
  - [Updating](#updating)
  - [Customizing](#customizing)
  - [Troubleshooting](#troubleshooting)
  - [Project layout](#project-layout)
- [Licença](#licença)

---

# Português (BR)

## Requisitos

- **Docker Engine** 24+ com o plugin **Docker Compose v2**
- 2 GB de RAM livres (recomendado 4 GB+ para rodar o Herdr com vários agentes)
- Uma pasta de trabalho para o projeto alvo

```bash
docker --version
docker compose version
```

## Início rápido

```bash
git clone https://github.com/orionhack99/opencode-environment-docker.git
cd opencode-environment-docker

# 1. Constrói a imagem (primeira vez leva alguns minutos)
docker compose build

# 2. Abre um shell interativo dentro do sandbox
docker compose run --rm sandbox
```

Dentro do container:

```bash
opencode   # abre o agente de IA no /workspace
herdr      # abre o painel de workspaces/panes
```

Atalho para sair do container: `Ctrl+D` (ou `exit`).

### Comandos mais usados

```bash
# Shell interativo (equivalente a `docker compose run --rm sandbox`)
docker compose run --rm sandbox

# Já abrir o OpenCode
docker compose run --rm sandbox opencode

# Já abrir o Herdr
docker compose run --rm sandbox herdr

# Mandar um prompt sem TUI (automatização / scripts)
docker compose run --rm sandbox opencode run "Explique a estrutura deste repositório"

# Container em background
docker compose up -d sandbox
docker compose logs -f sandbox

# Parar e apagar container + volumes (começa do zero)
docker compose down -v
```

## Como usar

### 1. Login do OpenCode

O OpenCode precisa de um provedor de modelo. Na primeira execução:

```bash
docker compose run --rm sandbox opencode auth login
```

Ou, dentro da TUI do OpenCode, use o comando `/connect`.
Depois disso, `opencode` abre o agente normalmente.

O token fica salvo em `/root/.local/share/opencode/auth.json`, que está num volume
nomeado — **sobrevive à recriação do container**.

### 2. Organizando o trabalho com o Herdr

O Herdr é um gerenciador de *workspaces* (projetos), *tabs* e *panes* (terminais).
Dentro de um pane você roda o OpenCode; o Herdr detecta o agente e mostra o
estado (`working`, `blocked`, `done`, `idle`) na barra lateral.

```bash
docker compose run --rm sandbox herdr
```

Cenário típico:

1. `herdr` → abre o painel
2. `Ctrl+B`, depois `Shift+N` → cria um workspace novo para o alvo
3. Dentro do pane, `opencode` → o agente aparece na sidebar
4. `Ctrl+B`, `V` → divide o pane para paralelizar outro agente
5. `Ctrl+B`, `Q` → desliga o cliente; **o servidor e os agentes continuam rodando**
6. `herdr` de novo → reconecta na mesma sessão

### 3. Atalhos do Herdr

Prefixo padrão: `Ctrl+B` (pressione e solte, depois a tecla de ação).

| Ação | Tecla |
|---|---|
| Dividir pane à direita | `Ctrl+B` `V` |
| Dividir pane para baixo | `Ctrl+B` `-` |
| Nova tab | `Ctrl+B` `C` |
| Tab anterior / próxima | `Ctrl+B` `P` / `Ctrl+B` `N` |
| Navegar entre workspaces | `Ctrl+B` `W` |
| Novo workspace | `Ctrl+B` `Shift+N` |
| Novo git worktree | `Ctrl+B` `Shift+G` |
| Focar pane ← ↑ ↓ → | `Ctrl+B` `H` / `K` / `J` / `L` |
| Modo cópia | `Ctrl+B` `[` |
| Configurações | `Ctrl+B` `S` |
| Recarregar config | `Ctrl+B` `Shift+R` |
| Ajuda (todas as teclas) | `Ctrl+B` `?` |
| Desconectar (servidor continua) | `Ctrl+B` `Q` |

> O mouse também funciona: clique em panes, tabs e agentes; arraste as bordas para
> redimensionar; botão direito abre o menu de contexto.

### 4. Orquestrando os agentes por script

O Herdr expõe uma API JSON pelo socket local — útil para automação:

```bash
# Listar agentes e estados
herdr agent list

# Esperar o agente ficar ocioso
herdr agent wait <alvo> --until idle --timeout 120000

# Mandar um prompt e esperar a resposta
herdr agent prompt <alvo> "enumere os endpoints" --wait
```

## O que já vem na imagem

A imagem é **intencionalmente mínima**. Ela traz apenas o runtime para o
OpenCode e o Herdr rodarem — **nenhuma ferramenta de pentest vem pré-instalada**.
Isso mantém a imagem pequena, o build rápido e você no controle do que entra
no sandbox.

**Já instalado:**

- **Kali Linux rolling** como base (com o repositório `kali-rolling` configurado,
  pronto para `apt install`)
- **OpenCode v2** — via instalador oficial
- **Herdr stable** — via instalador oficial (com verificação de SHA-256)
- **Integração Herdr ↔ OpenCode** — habilita o relatório de estado do agente e a
  restauração da sessão depois de reiniciar o servidor do Herdr
- Utilitários básicos: `git`, `curl`, `tmux`, `sudo`, `procps`

### Instalando ferramentas de pentest

**1. Dentro do container (efêmero — some quando o container é recriado):**

```bash
docker compose run --rm sandbox bash
# dentro do container:
apt-get update && apt-get install -y nmap sqlmap ffuf gobuster nikto
```

**2. De forma permanente (recomendado se você usa sempre as mesmas tools):**

Crie um `Dockerfile.tools` no seu ambiente e estenda a imagem:

```dockerfile
FROM opencode-sandbox:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap sqlmap ffuf gobuster nikto whatweb \
    && rm -rf /var/lib/apt/lists/*
```

```bash
docker build -f Dockerfile.tools -t opencode-sandbox:tools .
```

E aponte o Compose para ela (no `docker-compose.yml`):

```yaml
    image: opencode-sandbox:tools
```

> ⚠️ `kali-linux-meta` / `kali-tools-full` instalam **toda** a suíte do Kali
> (dezenas de GB). Prefira listas curtas e sob medida.

Verifique o que está instalado:

```bash
docker compose run --rm sandbox bash -lc 'opencode --version; herdr --version; ls /usr/bin | wc -l'
```

## Volumes e persistência

| Tipo | Host / Origem | No container | O que guarda |
|---|---|---|---|
| Bind mount | `.` (a pasta do projeto) | `/workspace` | O código em que o agente trabalha |
| Volume nomeado | `opencode-config` | `/root/.config/opencode` | Config do OpenCode |
| Volume nomeado | `opencode-data` | `/root/.local/share/opencode` | `auth.json`, banco, sessões, logs |
| Volume nomeado | `opencode-state` | `/root/.local/state/opencode` | Registro do serviço em background |
| Volume nomeado | `herdr-config` | `/root/.config/herdr` | `config.toml` do Herdr |
| Volume nomeado | `herdr-state` | `/root/.herdr` | Worktrees, sessão e estado do Herdr |

Os volumes nomeados são **preferidos a bind mounts do `~`** porque funcionam igual
em Linux, macOS e Windows, sem problemas de permissão de arquivo.

⚠️ O bind mount `.:/workspace` dá **acesso de escrita ao agente sobre o seu
repositório**. Use uma pasta dedicada para os alvos, não a sua pasta pessoal.

Recomeçar do zero (apaga login, sessões e config):

```bash
docker compose down -v
```

## Rede e isolamento

O container usa a rede `bridge` padrão do Docker, com **saída para a internet**
(necessária para o login do OpenCode e para alcançar os alvos).

Para trabalhar **offline** (análise de código, revisão de payloads, treino):

```bash
docker compose run --rm sandbox --network none
```

Para um laboratório isolado, crie uma rede dedicada:

```bash
docker network create --internal pentest-lab
docker compose run --rm sandbox --network pentest-lab
```

Uma rede `--internal` não tem rota para a internet — ideal para alvos internos
e para simular redes segmentadas.

> **Nunca** monte `/var/run/docker.sock` neste container. Isso equivale a dar
> root na sua máquina.

## ⚠️ Segurança e uso responsável

Este projeto é uma **ferramenta de duplo uso**. Ele existe para testes legítimos:
pentest contratado, CTF, laboratório, pesquisa de segurança.

- **Use apenas em sistemas que você tem autorização explícita para testar.**
  Testar sem autorização é ilegal na maior parte das jurisdições (no Brasil:
  Lei 12.737/2012 — "Carne Digital"; nos EUA: CFAA e equivalentes).
- **O container roda como `root` dentro do seu Docker.** Isso é intencional
  (ferramentas de pentest precisam de privilégios), mas o container **não é uma
  fronteira de segurança** contra o kernel, o runtime do Docker ou o daemon
  exposto. Não o use para executar código que você não auditou.
- **O agente de IA executa comandos automaticamente.** Revise as permissões
  concedidas ao OpenCode (config do provedor) e mantenha o bind mount restrito
  a uma pasta de trabalho.
- **Não commite segredos.** O `.gitignore` já exclui `.env`, chaves e
  `auth.json`, mas confira `git status` antes de `git push`.
- **Volumes nomeados guardam tokens de acesso** (`auth.json`). Trate-os como
  credenciais: `docker compose down -v` quando não precisar mais.

## Atualizando

```bash
# Atualizar a imagem base (Kali) e reinstalar o OpenCode/Herdr do zero
docker compose build --no-cache --pull
docker compose up -d --force-recreate sandbox

# Atualizar o Herdr dentro do container (canal stable por padrão)
docker compose run --rm sandbox herdr update
docker compose run --rm sandbox herdr channel show

# Atualizar o OpenCode dentro do container
docker compose run --rm sandbox opencode upgrade
```

Para **fixar** a versão do OpenCode (build reprodutível), crie um `.env`:

```bash
echo "OPENCODE_VERSION=1.2.3" > .env
docker compose build --no-cache
```

## Personalizando

- **Ambiente**: edite o bloco `environment:` do `docker-compose.yml`.
  Ex.: `HERDR_LOG=herdr=debug`, `OPENCODE_LOG_LEVEL=DEBUG`.
- **Config do Herdr**: `docker compose run --rm sandbox` e edite
  `/root/.config/herdr/config.toml` (há ~200 opções em
  `herdr --default-config`). Depois: `herdr server reload-config`.
- **Config do OpenCode**: `~/.config/opencode/opencode.json` dentro do container.
- **Imagem**: edite o `Dockerfile` e rode `docker compose build`.

## Solução de problemas

<details>
<summary><b>Terminal pequeno ou quebrado (0x0) na TUI</b></summary>

Rode sempre com TTY: `docker compose run --rm` (o Compose já define `tty: true`).
Se o terminal ficar com tamanho 0, force o tamanho:

```bash
docker compose run --rm sandbox bash -lc 'stty rows 50 cols 200; exec bash'
```
</details>

<details>
<summary><b>O Herdr não detecta o estado do agente (fica "idle")</b></summary>

Alguns runtimes Linux restritos não expõem o *foreground process group*, e a
detecção nativa falha. Force o modo alternativo:

```bash
docker compose run --rm sandbox -e HERDR_PROCESS_DETECTION=child-groups herdr
```

Diagnóstico: `herdr agent explain <alvo> --verbose`.
</details>

<details>
<summary><b>Erro de som / notificação</b></summary>

Containeres não têm placa de som. Já definimos `HERDR_DISABLE_SOUND=1` e
`ui.sound.enabled = false`. Se persistir, veja
[troubleshooting do Herdr](https://herdr.dev/docs/troubleshooting/).
</details>

<details>
<summary><b>O OpenCode não conecta / serviço travado</b></summary>

```bash
opencode service status
opencode service restart
tail -f ~/.local/share/opencode/log/opencode.log
```
</details>

<details>
<summary><b>"permission denied" ao rodar tools do Kali</b></summary>

O container roda como `root` — se aparecer isso, o problema é o **bind mount**:
o container grava no host com o UID do root. Ajuste as permissões da pasta
hospedeira ou rode com `user: "${UID}:${GID}"` no Compose.
</details>

<details>
<summary><b>Quero recomeçar com tudo limpo</b></summary>

```bash
docker compose down -v --remove-orphans
docker compose build --no-cache
```
</details>

## Estrutura do projeto

```
.
├── Dockerfile                 # imagem: Kali + OpenCode + Herdr
├── docker-compose.yml         # serviço "sandbox" e volumes nomeados
├── docker/
│   └── entrypoint.sh          # banner + exec do comando
├── .github/workflows/build.yml# CI: build da imagem + smoke test
├── .dockerignore              # contexto de build enxuto
├── .gitignore                 # segredos e artefatos
├── LICENSE                    # MIT
└── README.md
```

---

# English

## Requirements

- **Docker Engine** 24+ with the **Docker Compose v2** plugin
- 2 GB free RAM (4 GB+ recommended to run Herdr with several agents)
- A working directory for the target project

```bash
docker --version
docker compose version
```

## Quick start

```bash
git clone https://github.com/orionhack99/opencode-environment-docker.git
cd opencode-environment-docker

# 1. Build the image (first run takes a few minutes)
docker compose build

# 2. Open an interactive shell inside the sandbox
docker compose run --rm sandbox
```

Inside the container:

```bash
opencode   # start the AI agent in /workspace
herdr      # open the workspace/pane dashboard
```

Exit with `Ctrl+D` (or `exit`).

### Common commands

```bash
# Interactive shell (same as `docker compose run --rm sandbox`)
docker compose run --rm sandbox

# Jump straight into OpenCode
docker compose run --rm sandbox opencode

# Jump straight into Herdr
docker compose run --rm sandbox herdr

# Headless prompt (automation / scripts)
docker compose run --rm sandbox opencode run "Explain the structure of this repository"

# Background container
docker compose up -d sandbox
docker compose logs -f sandbox

# Stop and remove container + volumes (start from scratch)
docker compose down -v
```

## Usage

### 1. OpenCode login

OpenCode needs a model provider. On first run:

```bash
docker compose run --rm sandbox opencode auth login
```

Or, from inside the OpenCode TUI, use the `/connect` command.
After that, `opencode` starts the agent normally.

The token is stored in `/root/.local/share/opencode/auth.json`, which lives in a
named volume — **it survives container recreation**.

### 2. Driving the work with Herdr

Herdr is a dashboard for *workspaces* (projects), *tabs* and *panes* (terminals).
Run OpenCode inside a pane; Herdr detects the agent and shows its state
(`working`, `blocked`, `done`, `idle`) in the sidebar.

```bash
docker compose run --rm sandbox herdr
```

Typical flow:

1. `herdr` → open the dashboard
2. `Ctrl+B`, then `Shift+N` → new workspace for the target
3. Inside the pane, run `opencode` → the agent shows up in the sidebar
4. `Ctrl+B`, `V` → split the pane to run another agent in parallel
5. `Ctrl+B`, `Q` → detach the client; **the server and agents keep running**
6. Run `herdr` again → reattach to the same session

### 3. Herdr shortcuts

Default prefix: `Ctrl+B` (press and release, then the action key).

| Action | Keys |
|---|---|
| Split pane right | `Ctrl+B` `V` |
| Split pane down | `Ctrl+B` `-` |
| New tab | `Ctrl+B` `C` |
| Previous / next tab | `Ctrl+B` `P` / `Ctrl+B` `N` |
| Switch workspace | `Ctrl+B` `W` |
| New workspace | `Ctrl+B` `Shift+N` |
| New git worktree | `Ctrl+B` `Shift+G` |
| Focus pane ← ↑ ↓ → | `Ctrl+B` `H` / `K` / `J` / `L` |
| Copy mode | `Ctrl+B` `[` |
| Settings | `Ctrl+B` `S` |
| Reload config | `Ctrl+B` `Shift+R` |
| Help (all bindings) | `Ctrl+B` `?` |
| Detach (server keeps running) | `Ctrl+B` `Q` |

> The mouse works too: click panes, tabs and agents, drag borders to resize,
> right-click for the context menu.

### 4. Scripting the agents

Herdr exposes a JSON API over a local socket — handy for automation:

```bash
# List agents and their states
herdr agent list

# Wait for an agent to go idle
herdr agent wait <target> --until idle --timeout 120000

# Send a prompt and wait for the answer
herdr agent prompt <target> "enumerate the endpoints" --wait
```

## What ships in the image

The image is **intentionally minimal**. It ships only the runtime needed for
OpenCode and Herdr — **no pentest tooling is pre-installed**. That keeps the
image small, the build fast, and you in control of what enters the sandbox.

**Already installed:**

- **Kali Linux rolling** as the base (with the `kali-rolling` repository
  configured and ready for `apt install`)
- **OpenCode v2** — via the official installer
- **Herdr stable** — via the official installer (SHA-256 verified)
- **Herdr ↔ OpenCode integration** — enables agent state reporting and session
  restore after a Herdr server restart
- Basic utilities: `git`, `curl`, `tmux`, `sudo`, `procps`

### Installing pentest tooling

**1. Inside the container (ephemeral — gone when the container is recreated):**

```bash
docker compose run --rm sandbox bash
# inside the container:
apt-get update && apt-get install -y nmap sqlmap ffuf gobuster nikto
```

**2. Permanently (recommended if you always use the same tools):**

Create a `Dockerfile.tools` in your own environment and extend the image:

```dockerfile
FROM opencode-sandbox:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap sqlmap ffuf gobuster nikto whatweb \
    && rm -rf /var/lib/apt/lists/*
```

```bash
docker build -f Dockerfile.tools -t opencode-sandbox:tools .
```

And point the Compose file at it (in `docker-compose.yml`):

```yaml
    image: opencode-sandbox:tools
```

> ⚠️ `kali-linux-meta` / `kali-tools-full` install the **entire** Kali suite
> (tens of GB). Prefer short, purpose-built lists.

Check what is installed:

```bash
docker compose run --rm sandbox bash -lc 'opencode --version; herdr --version; ls /usr/bin | wc -l'
```

## Volumes and persistence

| Type | Host / Source | In container | What it stores |
|---|---|---|---|
| Bind mount | `.` (the project folder) | `/workspace` | The code the agent works on |
| Named volume | `opencode-config` | `/root/.config/opencode` | OpenCode config |
| Named volume | `opencode-data` | `/root/.local/share/opencode` | `auth.json`, database, sessions, logs |
| Named volume | `opencode-state` | `/root/.local/state/opencode` | Background service registration |
| Named volume | `herdr-config` | `/root/.config/herdr` | Herdr `config.toml` |
| Named volume | `herdr-state` | `/root/.herdr` | Worktrees, session and Herdr state |

Named volumes are **preferred over bind-mounting `~`** because they behave the
same on Linux, macOS and Windows, with no odd file permissions.

⚠️ The `.:/workspace` bind mount gives the agent **write access to your
repository**. Use a dedicated folder for targets, not your personal one.

Start completely fresh (drops login, sessions and config):

```bash
docker compose down -v
```

## Network and isolation

The container uses Docker's default `bridge` network, with **internet egress**
(required for the OpenCode login and to reach the targets).

To work **offline** (code review, payload analysis, training):

```bash
docker compose run --rm sandbox --network none
```

For an isolated lab, create a dedicated network:

```bash
docker network create --internal pentest-lab
docker compose run --rm sandbox --network pentest-lab
```

An `--internal` network has no route to the internet — ideal for internal
targets and to simulate segmented networks.

> **Never** bind-mount `/var/run/docker.sock` into this container. That is
> equivalent to giving root on your machine.

## ⚠️ Security and responsible use

This project is a **dual-use tool**. It exists for legitimate work: contract
pentesting, CTFs, labs, security research.

- **Only test systems you are explicitly authorized to test.** Unauthorized
  testing is illegal in most jurisdictions (in Brazil: Law 12.737/2012 — the
  "Carne Digital" law; in the US: the CFAA and its equivalents).
- **The container runs as `root` inside your Docker.** This is intentional
  (pentest tooling needs privileges), but the container is **not a security
  boundary** against the kernel, the Docker runtime, or an exposed daemon. Do
  not use it to run code you have not audited.
- **The AI agent executes commands on its own.** Review the permissions granted
  to OpenCode (provider config) and keep the bind mount restricted to a working
  folder.
- **Do not commit secrets.** The `.gitignore` already excludes `.env`, keys and
  `auth.json`, but check `git status` before `git push`.
- **Named volumes hold access tokens** (`auth.json`). Treat them as
  credentials: run `docker compose down -v` when you no longer need them.

## Updating

```bash
# Update the base image (Kali) and the bundled tooling
docker compose build --no-cache --pull
docker compose up -d --force-recreate sandbox

# Update Herdr inside the container (stable channel by default)
docker compose run --rm sandbox herdr update
docker compose run --rm sandbox herdr channel show

# Update OpenCode inside the container
docker compose run --rm sandbox opencode upgrade
```

To **pin** the OpenCode version (reproducible builds), create a `.env` file:

```bash
echo "OPENCODE_VERSION=1.2.3" > .env
docker compose build --no-cache
```

## Customizing

- **Environment**: edit the `environment:` block in `docker-compose.yml`, e.g.
  `HERDR_LOG=herdr=debug`, `OPENCODE_LOG_LEVEL=DEBUG`.
- **Herdr config**: run `docker compose run --rm sandbox` and edit
  `/root/.config/herdr/config.toml` (~200 options; see `herdr --default-config`).
  Then run `herdr server reload-config`.
- **OpenCode config**: `~/.config/opencode/opencode.json` inside the container.
- **Image**: edit the `Dockerfile` and run `docker compose build`.

## Troubleshooting

<details>
<summary><b>Broken or tiny terminal (0x0) in the TUI</b></summary>

Always run with a TTY: `docker compose run --rm` (Compose already sets
`tty: true`). If the size is 0, force it:

```bash
docker compose run --rm sandbox bash -lc 'stty rows 50 cols 200; exec bash'
```
</details>

<details>
<summary><b>Herdr does not detect the agent state (stays "idle")</b></summary>

Some restricted Linux runtimes do not expose the terminal foreground process
group and native detection fails. Force the fallback mode:

```bash
docker compose run --rm sandbox -e HERDR_PROCESS_DETECTION=child-groups herdr
```

Diagnostics: `herdr agent explain <target> --verbose`.
</details>

<details>
<summary><b>Sound / notification errors</b></summary>

Containers have no sound card. `HERDR_DISABLE_SOUND=1` and
`ui.sound.enabled = false` are already set. If it persists, see the
[Herdr troubleshooting guide](https://herdr.dev/docs/troubleshooting/).
</details>

<details>
<summary><b>OpenCode will not connect / stuck service</b></summary>

```bash
opencode service status
opencode service restart
tail -f ~/.local/share/opencode/log/opencode.log
```
</details>

<details>
<summary><b>"permission denied" running Kali tools</b></summary>

The container runs as `root` — so this is usually the **bind mount**: the
container writes to the host as UID 0. Fix the host folder permissions, or run
with `user: "${UID}:${GID}"` in the Compose file.
</details>

<details>
<summary><b>Start completely clean</b></summary>

```bash
docker compose down -v --remove-orphans
docker compose build --no-cache
```
</details>

## Project layout

```
.
├── Dockerfile                 # image: Kali + OpenCode + Herdr
├── docker-compose.yml         # "sandbox" service and named volumes
├── docker/
│   └── entrypoint.sh          # banner + exec of the command
├── .github/workflows/build.yml# CI: image build + smoke test
├── .dockerignore              # slim build context
├── .gitignore                 # secrets and artifacts
├── LICENSE                    # MIT
└── README.md
```

---

## Licença

[MIT](LICENSE) © 2026 orionhack99

Este projeto não é afiliado, endossado ou mantido pelo Kali Linux, pela
OpenCode (anomalyco) ou pela Herdr (herdrdev).
