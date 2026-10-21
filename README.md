# 🛡️ OpenCode + Herdr — Sandbox de Segurança Ofensiva (Docker)

[![Build](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml/badge.svg)](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Base](https://img.shields.io/badge/base-kali--rolling-363636)](https://www.kali.org/)

Ambiente **isolado em Docker** para rodar um agente de IA de segurança ofensiva
com um painel de gerenciamento de terminais:

| Componente | O que é |
|---|---|
| **Kali Linux rolling** | Base com o repositório Kali configurado — **sem** ferramentas pré-instaladas |
| **OpenCode** | Agente de IA que lê, escreve e executa comandos no seu projeto |
| **Herdr** | Painel TUI de *workspaces / tabs / panes* para orquestrar vários agentes |

O objetivo é dar ao agente um **laboratório descartável**: você aponta o
OpenCode para um alvo, ele ataca, e o estrago fica dentro do container.

**🇧🇷 Português (BR)** · **🇬🇧 [English](#english)**

---

## 📋 Sumário

- [Português (BR)](#português--br)
  - [Requisitos](#requisitos)
  - [Início rápido](#início-rápido)
  - [Uso](#uso)
  - [Atalhos do Herdr](#atalhos-do-herdr)
  - [Instalando ferramentas de pentest](#instalando-ferramentas-de-pentest)
  - [Volumes e persistência](#volumes-e-persistência)
  - [🔒 Segurança do sandbox](#-segurança-do-sandbox)
  - [Rede](#rede)
  - [Atualizando](#atualizando)
  - [Solução de problemas](#solução-de-problemas)
  - [Estrutura do projeto](#estrutura-do-projeto)
- [English](#english)
  - [Requirements](#requirements)
  - [Quick start](#quick-start)
  - [Usage](#usage)
  - [Herdr shortcuts](#herdr-shortcuts)
  - [Installing pentest tooling](#installing-pentest-tooling)
  - [Volumes and persistence](#volumes-and-persistence)
  - [🔒 Sandbox security](#-sandbox-security)
  - [Network](#network)
  - [Updating](#updating)
  - [Troubleshooting](#troubleshooting)
  - [Project layout](#project-layout)
- [Licença](#licença)

---

# Português (BR)

## Requisitos

- **Docker Engine** 24+ com o plugin **Docker Compose v2**
- 2 GB de RAM livres (4 GB+ para rodar o Herdr com vários agentes)
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
opencode   # abre o agente de IA em /workspace
herdr      # abre o painel de workspaces/panes
```

Sai com `Ctrl+D` (ou `exit`).

### Comandos mais usados

```bash
# Shell interativo
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

## Uso

### 1. Login do OpenCode

O OpenCode precisa de um provedor de modelo. Na primeira execução:

```bash
docker compose run --rm sandbox opencode auth login
```

Ou, dentro da TUI do OpenCode, use o comando `/connect`.
O token fica salvo em `/root/.local/share/opencode/auth.json`, num volume
nomeado — **sobrevive à recriação do container**.

### 2. Organizando o trabalho com o Herdr

O Herdr gerencia *workspaces* (projetos), *tabs* e *panes* (terminais).
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
| Nova tab | `Ctrl+B` `C` |
| Dividir pane à direita | `Ctrl+B` `V` |
| Dividir pane para baixo | `Ctrl+B` `-` |
| Focar pane ← ↑ ↓ → | `Ctrl+B` `H` / `K` / `J` / `L` |
| Trocar panes ← ↑ ↓ → | `Ctrl+B` `Shift+H` / `K` / `J` / `L` |
| Fechar pane | `Ctrl+B` `X` |
| Zoom no pane | `Ctrl+B` `Z` |
| Modo redimensionar | `Ctrl+B` `R` |
| Modo cópia | `Ctrl+B` `[` |
| Ir para a tab 1–9 | `Ctrl+B` `1`…`9` |
| Tab anterior / próxima | `Ctrl+B` `P` / `Ctrl+B` `N` |
| Renomear / fechar tab | `Ctrl+B` `Shift+T` / `Ctrl+B` `Shift+X` |
| Navegar entre workspaces | `Ctrl+B` `W` |
| Novo workspace | `Ctrl+B` `Shift+N` |
| Renomear / fechar workspace | `Ctrl+B` `Shift+W` / `Ctrl+B` `Shift+D` |
| Novo git worktree | `Ctrl+B` `Shift+G` |
| Ir para (agente/terminal) | `Ctrl+B` `G` |
| Mostrar/esconder a sidebar | `Ctrl+B` `B` |
| Configurações | `Ctrl+B` `S` |
| Recarregar config | `Ctrl+B` `Shift+R` |
| Ajuda (todas as teclas) | `Ctrl+B` `?` |
| Desconectar (servidor continua) | `Ctrl+B` `Q` |

> O mouse também funciona: clique em panes, tabs e agentes; arraste as bordas
> para redimensionar; botão direito abre o menu de contexto.
> O prefixo é `Ctrl+B`: pressione e solte, depois a tecla de ação.

### 4. Automação pela API do Herdr

O Herdr expõe uma API JSON pelo socket local:

```bash
# Listar agentes e estados
herdr agent list

# Esperar o agente ficar ocioso
herdr agent wait <alvo> --until idle --timeout 120000

# Mandar um prompt e esperar a resposta
herdr agent prompt <alvo> "enumere os endpoints" --wait
```

## Instalando ferramentas de pentest

A imagem é **intencionalmente mínima**: só o runtime do OpenCode e do Herdr.
Você instala as ferramentas que precisar.

> ⚠️ O filesystem do container é **somente-leitura**, então o `apt-get install`
> não funciona no sandbox padrão. Use um dos dois caminhos abaixo.

**1. No container, com escrita habilitada (efêmero — some ao recriar):**

```bash
# Crie o override uma única vez
cat > docker-compose.tools.yml <<'EOF'
services:
  sandbox:
    read_only: false
EOF

# Instale as ferramentas
docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox bash
# dentro do container:
apt-get update && apt-get install -y nmap sqlmap ffuf gobuster nikto
```

**2. De forma permanente (recomendado se você sempre usa as mesmas tools):**

Estenda a imagem num `Dockerfile.tools` no seu ambiente:

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

## Volumes e persistência

| Tipo | Host / Origem | No container | O que guarda |
|---|---|---|---|
| Bind mount | `.` (a pasta do projeto) | `/workspace` | O código em que o agente trabalha |
| Volume nomeado | `opencode-config` | `/root/.config/opencode` | Config do OpenCode |
| Volume nomeado | `opencode-data` | `/root/.local/share/opencode` | `auth.json`, banco, sessões, logs |
| Volume nomeado | `opencode-state` | `/root/.local/state/opencode` | Registro do serviço em background |
| Volume nomeado | `herdr-config` | `/root/.config/herdr` | `config.toml` do Herdr |
| Volume nomeado | `herdr-state` | `/root/.herdr` | Worktrees, sessão e estado do Herdr |

Os volumes nomeados são **preferidos a bind mounts do `~`** porque funcionam
igual em Linux, macOS e Windows, sem problemas de permissão de arquivo.

⚠️ O bind mount `.:/workspace` dá **acesso de escrita ao agente sobre a sua
pasta**. Use um diretório dedicado para os alvos, não a sua pasta pessoal.
Os arquivos criados ali dentro ficam com dono `root` (o container roda como
root) — se isso incomodar, use `sudo chown -R $(id -u) .` na pasta.

Recomeçar do zero (apaga login, sessões e config):

```bash
docker compose down -v
```

## 🔒 Segurança do sandbox

O container roda como **root** — é intencional: as ferramentas de pentest
precisam de privilégios (raw sockets, `tcpdump`, criação de interfaces).
A fronteira de isolamento é o **container**, e ela é reforçada aqui:

| Controle | Efeito |
|---|---|
| `no-new-privileges:true` | Nada dentro do container consegue escalar privilégio via binário setuid/setgid |
| `cap_drop: MKNOD, SETFCAP, AUDIT_WRITE, SYS_CHROOT, FSETID` | Remove capabilities do padrão do Docker que o sandbox não usa. Mantidas: `NET_RAW` (nmap -sS, tcpdump), `NET_BIND_SERVICE` (portas baixas), `CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETUID/SETGID`, `KILL` |
| `read_only: true` | O container não consegue alterar a própria imagem. Escrita só nos volumes e tmpfs |
| tmpfs `nosuid,nodev` | `/tmp`, `/run`, `/var/tmp` e `~/.cache` sem execução nem setuid |
| `pids_limit: 512` | Trava fork bombs |
| `mem_limit: 4g` / `cpus: 2.0` | Evita exaustão de recursos |
| `init: true` | PID 1 faz o reaping de processos (o Herdr abre vários subprocessos) |
| Perfil seccomp padrão do Docker | Bloqueia dezenas de syscalls considerados perigosos |
| Sem `privileged`, sem `network_mode: host` | Configuração padrão, sem brecha de escape |

### O que **não** fazer

- ❌ **Nunca** monte `/var/run/docker.sock` — equivale a dar root na sua máquina.
- ❌ Nunca use `--privileged` — derruba todas as proteções acima.
- ❌ Nunca monte `/`, `/etc` ou `/root` do host.
- ❌ Não rode alvo de terceiros sem autorização por escrito.

### Endurecimento extra (opcional)

O `docker compose run` não tem flag `--network`, então use um **override**:

```bash
# Trabalho totalmente offline, sem rede nenhuma
cat > docker-compose.offline.yml <<'EOF'
services:
  sandbox:
    network_mode: "none"
EOF

docker compose -f docker-compose.yml -f docker-compose.offline.yml run --rm sandbox
```

```bash
# Laboratório isolado: rede interna, sem rota para a internet
docker network create --internal pentest-lab

cat > docker-compose.lab.yml <<'EOF'
services:
  sandbox:
    networks:
      pentest-lab: {}
networks:
  pentest-lab:
    external: true
    name: pentest-lab
EOF

docker compose -f docker-compose.yml -f docker-compose.lab.yml run --rm sandbox
```

Para isolamento mais forte que containers (Kernel do Docker), use uma VM
dedicada, gVisor (`--runtime=runsc`) ou Firecracker. Num host compartilhado,
considere um runner descartável.

### ⚠️ Uso responsável

Este projeto é uma **ferramenta de duplo uso**, para pentest contratado, CTF,
laboratório e pesquisa de segurança.

- **Use apenas em sistemas com autorização explícita.** Testar sem autorização
  é ilegal na maior parte das jurisdições (no Brasil: Lei 12.737/2012 — a
  "Carne Digital"; nos EUA: CFAA e equivalentes).
- **O agente de IA executa comandos sozinho.** Revise as permissões concedidas
  ao OpenCode e mantenha o bind mount restrito a uma pasta de trabalho.
- **Não commite segredos.** O `.gitignore` exclui `.env`, chaves e `auth.json`,
  mas confira `git status` antes de `git push`.
- **Volumes nomeados guardam tokens** (`auth.json`). Trate-os como
  credenciais: `docker compose down -v` quando não precisar mais.

## Rede

O container usa a rede `bridge` padrão do Docker, com **saída para a internet**
(necessária para o login do OpenCode e para alcançar os alvos). Veja as opções
de isolamento acima.

## Atualizando

O filesystem do container é **somente-leitura**, então o upgrade acontece na
**hora do build**:

```bash
# Atualizar a imagem base (Kali) e reinstalar OpenCode/Herdr
docker compose build --no-cache --pull
docker compose up -d --force-recreate sandbox
```

Para **fixar** a versão do OpenCode (build reprodutível), crie um `.env`:

```bash
echo "OPENCODE_VERSION=1.2.3" > .env
docker compose build --no-cache
```

> ⚠️ `opencode upgrade` e `herdr update` **não funcionam** dentro de um
> container em execução: eles gravam em `/root/.opencode/bin` e
> `/usr/local/bin`, que fazem parte do rootfs somente-leitura. Para atualizar,
> reconstrua a imagem.

## Solução de problemas

<details>
<summary><b>Terminal pequeno ou quebrado (0x0) na TUI</b></summary>

Rode sempre com TTY: `docker compose run --rm` (o Compose já define `tty: true`).
Se o terminal ficar com tamanho 0, force:

```bash
docker compose run --rm sandbox bash -lc 'stty rows 50 cols 200; exec bash'
```
</details>

<details>
<summary><b>"Read-only file system" ao gravar em /root</b></summary>

Esperado: o rootfs do container é somente-leitura. Os caminhos graváveis são
os volumes nomeados e os tmpfs. Para gravar em outro lugar, monte um volume:
`-v meu_dir:/root/minha_pasta`.
</details>

<details>
<summary><b>"Read-only file system" ao rodar <code>apt-get install</code></b></summary>

Esperado: o rootfs do container é somente-leitura. Para instalar pacotes
dentro do container, use um override que desabilite o `read_only`:

```bash
cat > docker-compose.tools.yml <<'EOF'
services:
  sandbox:
    read_only: false
EOF

docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox bash
```

Ou instale as ferramentas na hora do build — veja
[Instalando ferramentas de pentest](#instalando-ferramentas-de-pentest).
</details>

<details>
<summary><b>O Herdr não detecta o estado do agente (fica "idle")</b></summary>

Alguns runtimes Linux restritos não expõem o *foreground process group*. Force
o modo alternativo:

```bash
docker compose run --rm -e HERDR_PROCESS_DETECTION=child-groups sandbox herdr
```

Diagnóstico: `herdr agent explain <alvo> --json`.
</details>

<details>
<summary><b>Erro de som / notificação</b></summary>

Containers não têm placa de som. Já definimos `HERDR_DISABLE_SOUND=1` e
`ui.sound.enabled = false`.
</details>

<details>
<summary><b>O OpenCode não conecta / serviço travado</b></summary>

```bash
opencode service status
opencode service restart
tail -f /root/.local/share/opencode/log/opencode.log
```
</details>

<details>
<summary><b>"permission denied" ao rodar tools do Kali</b></summary>

O container roda como `root` — se aparecer isso, o problema é o **bind mount**:
o container grava no host com o UID do root. Ajuste as permissões da pasta
hospedeira (`sudo chown -R $(id -u) .`).
</details>

<details>
<summary><b>"The OpenCode installer failed" ao rodar <code>opencode upgrade</code></b></summary>

Esperado: o rootfs é somente-leitura, então o instalador não consegue gravar em
`/root/.opencode/bin`. Atualize reconstruindo a imagem:

```bash
docker compose build --no-cache
```
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
├── Dockerfile                  # imagem: Kali + OpenCode + Herdr
├── docker-compose.yml          # serviço "sandbox", volumes e isolamento
├── .github/workflows/build.yml # CI: build + smoke test + segurança
├── .dockerignore               # contexto de build enxuto
├── .gitignore                  # segredos e artefatos
├── LICENSE                     # MIT
└── README.md
```

---

# English

## Requirements

- **Docker Engine** 24+ with the **Docker Compose v2** plugin
- 2 GB free RAM (4 GB+ to run Herdr with several agents)
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
# Interactive shell
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
The token is stored in `/root/.local/share/opencode/auth.json`, in a named
volume — **it survives container recreation**.

### 2. Driving the work with Herdr

Herdr manages *workspaces* (projects), *tabs* and *panes* (terminals).
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
| New tab | `Ctrl+B` `C` |
| Split pane right | `Ctrl+B` `V` |
| Split pane down | `Ctrl+B` `-` |
| Focus pane ← ↑ ↓ → | `Ctrl+B` `H` / `K` / `J` / `L` |
| Swap panes ← ↑ ↓ → | `Ctrl+B` `Shift+H` / `K` / `J` / `L` |
| Close pane | `Ctrl+B` `X` |
| Zoom pane | `Ctrl+B` `Z` |
| Resize mode | `Ctrl+B` `R` |
| Copy mode | `Ctrl+B` `[` |
| Jump to tab 1–9 | `Ctrl+B` `1`…`9` |
| Previous / next tab | `Ctrl+B` `P` / `Ctrl+B` `N` |
| Rename / close tab | `Ctrl+B` `Shift+T` / `Ctrl+B` `Shift+X` |
| Switch workspace | `Ctrl+B` `W` |
| New workspace | `Ctrl+B` `Shift+N` |
| Rename / close workspace | `Ctrl+B` `Shift+W` / `Ctrl+B` `Shift+D` |
| New git worktree | `Ctrl+B` `Shift+G` |
| Go to (agent/terminal) | `Ctrl+B` `G` |
| Toggle sidebar | `Ctrl+B` `B` |
| Settings | `Ctrl+B` `S` |
| Reload config | `Ctrl+B` `Shift+R` |
| Help (all bindings) | `Ctrl+B` `?` |
| Detach (server keeps running) | `Ctrl+B` `Q` |

> The mouse works too: click panes, tabs and agents, drag borders to resize,
> right-click for the context menu.
> The prefix is `Ctrl+B`: press and release, then the action key.

### 4. Scripting the agents

Herdr exposes a JSON API over a local socket:

```bash
# List agents and their states
herdr agent list

# Wait for an agent to go idle
herdr agent wait <target> --until idle --timeout 120000

# Send a prompt and wait for the answer
herdr agent prompt <target> "enumerate the endpoints" --wait
```

## Installing pentest tooling

The image is **intentionally minimal**: only the OpenCode + Herdr runtime.
You install the tools you need.

> ⚠️ The container filesystem is **read-only**, so `apt-get install` does not
> work in the default sandbox. Use one of the two paths below.

**1. Inside the container, with writes enabled (ephemeral — gone on recreate):**

```bash
# Create the override once
cat > docker-compose.tools.yml <<'EOF'
services:
  sandbox:
    read_only: false
EOF

# Install the tools
docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox bash
# inside the container:
apt-get update && apt-get install -y nmap sqlmap ffuf gobuster nikto
```

**2. Permanently (recommended if you always use the same tools):**

Extend the image with a `Dockerfile.tools` in your own environment:

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
same on Linux, macOS and Windows, with no file permission quirks.

⚠️ The `.:/workspace` bind mount gives the agent **write access to your
folder**. Use a dedicated directory for targets, not your personal one.
Files created there are owned by `root` (the container runs as root) — run
`sudo chown -R $(id -u) .` on the host folder if that bothers you.

Start completely fresh (drops login, sessions and config):

```bash
docker compose down -v
```

## 🔒 Sandbox security

The container runs as **root** — by design: pentest tooling needs privileges
(raw sockets, `tcpdump`, interface creation). The isolation boundary is the
**container**, and it is reinforced here:

| Control | Effect |
|---|---|
| `no-new-privileges:true` | Nothing inside the container can escalate privileges through a setuid/setgid binary |
| `cap_drop: MKNOD, SETFCAP, AUDIT_WRITE, SYS_CHROOT, FSETID` | Drops Docker-default capabilities the sandbox does not need. Kept: `NET_RAW` (nmap -sS, tcpdump), `NET_BIND_SERVICE` (low ports), `CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETUID/SETGID`, `KILL` |
| `read_only: true` | The container cannot modify its own image. Writes only to volumes and tmpfs |
| tmpfs `nosuid,nodev` | `/tmp`, `/run`, `/var/tmp` and `~/.cache` without exec or setuid |
| `pids_limit: 512` | Stops fork bombs |
| `mem_limit: 4g` / `cpus: 2.0` | Prevents resource exhaustion |
| `init: true` | PID 1 reaps processes (Herdr spawns many) |
| Docker's default seccomp profile | Blocks dozens of syscalls considered dangerous |
| No `privileged`, no `network_mode: host` | Defaults, with no escape hatch |

### What **not** to do

- ❌ **Never** bind-mount `/var/run/docker.sock` — that is root on your machine.
- ❌ Never use `--privileged` — it removes every protection above.
- ❌ Never mount the host's `/`, `/etc` or `/root`.
- ❌ Do not target third-party systems without written authorization.

### Extra hardening (optional)

`docker compose run` has no `--network` flag, so use an **override file**:

```bash
# Fully offline work, no network at all
cat > docker-compose.offline.yml <<'EOF'
services:
  sandbox:
    network_mode: "none"
EOF

docker compose -f docker-compose.yml -f docker-compose.offline.yml run --rm sandbox
```

```bash
# Isolated lab: internal network, no route to the internet
docker network create --internal pentest-lab

cat > docker-compose.lab.yml <<'EOF'
services:
  sandbox:
    networks:
      pentest-lab: {}
networks:
  pentest-lab:
    external: true
    name: pentest-lab
EOF

docker compose -f docker-compose.yml -f docker-compose.lab.yml run --rm sandbox
```

For isolation stronger than containers (the Docker kernel), use a dedicated VM,
gVisor (`--runtime=runsc`) or Firecracker. On a shared host, consider a
disposable runner.

### ⚠️ Responsible use

This project is a **dual-use tool**, for contract pentesting, CTFs, labs and
security research.

- **Only test systems you are explicitly authorized to test.** Unauthorized
  testing is illegal in most jurisdictions (in Brazil: Law 12.737/2012 — the
  "Carne Digital" law; in the US: the CFAA and its equivalents).
- **The AI agent executes commands on its own.** Review the permissions granted
  to OpenCode and keep the bind mount restricted to a working folder.
- **Do not commit secrets.** The `.gitignore` excludes `.env`, keys and
  `auth.json`, but check `git status` before `git push`.
- **Named volumes hold access tokens** (`auth.json`). Treat them as
  credentials: run `docker compose down -v` when you no longer need them.

## Network

The container uses Docker's default `bridge` network, with **internet egress**
(required for the OpenCode login and to reach the targets). See the isolation
options above.

## Updating

The container filesystem is **read-only**, so upgrades happen at **build time**:

```bash
# Update the base image (Kali) and reinstall OpenCode/Herdr
docker compose build --no-cache --pull
docker compose up -d --force-recreate sandbox
```

To **pin** the OpenCode version (reproducible builds), create a `.env` file:

```bash
echo "OPENCODE_VERSION=1.2.3" > .env
docker compose build --no-cache
```

> ⚠️ `opencode upgrade` and `herdr update` **do not work** inside a running
> container: they write to `/root/.opencode/bin` and `/usr/local/bin`, which
> belong to the read-only rootfs. Rebuild the image to update.

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
<summary><b>"Read-only file system" when writing to /root</b></summary>

Expected: the container rootfs is read-only. Writable paths are the named
volumes and the tmpfs mounts. To write elsewhere, mount a volume:
`-v my_dir:/root/my_folder`.
</details>

<details>
<summary><b>"Read-only file system" when running <code>apt-get install</code></b></summary>

Expected: the container rootfs is read-only. To install packages inside the
container, use an override that disables `read_only`:

```bash
cat > docker-compose.tools.yml <<'EOF'
services:
  sandbox:
    read_only: false
EOF

docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox bash
```

Or install the tools at build time — see
[Installing pentest tooling](#installing-pentest-tooling).
</details>

<details>
<summary><b>Herdr does not detect the agent state (stays "idle")</b></summary>

Some restricted Linux runtimes do not expose the terminal foreground process
group. Force the fallback mode:

```bash
docker compose run --rm -e HERDR_PROCESS_DETECTION=child-groups sandbox herdr
```

Diagnostics: `herdr agent explain <target> --json`.
</details>

<details>
<summary><b>Sound / notification errors</b></summary>

Containers have no sound card. `HERDR_DISABLE_SOUND=1` and
`ui.sound.enabled = false` are already set.
</details>

<details>
<summary><b>OpenCode will not connect / stuck service</b></summary>

```bash
opencode service status
opencode service restart
tail -f /root/.local/share/opencode/log/opencode.log
```
</details>

<details>
<summary><b>"permission denied" running Kali tools</b></summary>

The container runs as `root` — so this is usually the **bind mount**: the
container writes to the host as UID 0. Fix the host folder permissions
(`sudo chown -R $(id -u) .`).
</details>

<details>
<summary><b>"The OpenCode installer failed" when running <code>opencode upgrade</code></b></summary>

Expected: the rootfs is read-only, so the installer cannot write to
`/root/.opencode/bin`. Update by rebuilding the image:

```bash
docker compose build --no-cache
```
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
├── Dockerfile                  # image: Kali + OpenCode + Herdr
├── docker-compose.yml          # "sandbox" service, volumes and isolation
├── .github/workflows/build.yml # CI: build + smoke test + security checks
├── .dockerignore               # slim build context
├── .gitignore                  # secrets and artifacts
├── LICENSE                     # MIT
└── README.md
```

---

## Licença

[MIT](LICENSE) © 2026 orionhack99

Este projeto não é afiliado, endossado ou mantido pelo Kali Linux, pela
OpenCode (anomalyco) ou pela Herdr (herdrdev).
