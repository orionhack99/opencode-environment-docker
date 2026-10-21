# 🛡️ OpenCode + Herdr — Sandbox de Segurança Ofensiva (Docker)

[![Build](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml/badge.svg)](https://github.com/orionhack99/opencode-environment-docker/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Base](https://img.shields.io/badge/base-kali--rolling-363636)](https://www.kali.org/)
[![Framework](https://img.shields.io/badge/opencode--pentester-blue)](https://github.com/humaidhahm/opencode-pentester)

Ambiente **isolado em Docker** para rodar um agente de IA de segurança ofensiva
com um painel de gerenciamento de terminais — com o framework
[opencode-pentester](https://github.com/humaidhahm/opencode-pentester) já
clonado dentro da imagem.

| Componente | O que é |
|---|---|
| **Kali Linux rolling** | Base com o repositório Kali configurado — **sem** ferramentas pré-instaladas |
| **OpenCode** | Agente de IA que lê, escreve e executa comandos no seu projeto |
| **Herdr** | Painel TUI de *workspaces / tabs / panes* para orquestrar vários agentes |
| **opencode-pentester** | Framework de pentest/auditoria (12 agentes, 69 categorias de ataque, 17 auditorias OWASP) clonado no build |
| **kaliuser** | Usuário **não-root** do container, com `sudo` sem senha para as tools de pentest |

O objetivo é dar ao agente um **laboratório descartável**: você aponta o
OpenCode para um alvo, ele ataca, e o estrago fica dentro do container.

**🇧🇷 Português (BR)** · **🇬🇧 [English](#english)** · [⬆ Sumário](#-sumário)

---

## 📋 Sumário

- [Português (BR)](#português-br)
  - [Requisitos](#requisitos)
  - [Início rápido](#início-rápido)
  - [O que já vem pronto na imagem](#o-que-já-vem-pronto-na-imagem)
  - [Uso](#uso)
  - [Atalhos do Herdr](#3-atalhos-do-herdr)
  - [Instalando ferramentas de pentest](#instalando-ferramentas-de-pentest)
  - [Volumes e persistência](#volumes-e-persistência)
  - [🔒 Segurança do sandbox](#-segurança-do-sandbox)
  - [Rede](#rede)
  - [Atualizando](#atualizando)
  - [CI/CD](#cicd)
  - [Solução de problemas](#solução-de-problemas)
  - [Estrutura do projeto](#estrutura-do-projeto)
- [English](#english)
  - [Requirements](#requirements)
  - [Quick start](#quick-start)
  - [What ships in the image](#what-ships-in-the-image)
  - [Usage](#usage)
  - [Herdr shortcuts](#3-herdr-shortcuts)
  - [Installing pentest tooling](#installing-pentest-tooling)
  - [Volumes and persistence](#volumes-and-persistence)
  - [🔒 Sandbox security](#-sandbox-security)
  - [Network](#network)
  - [Updating](#updating)
  - [CI/CD](#cicd-1)
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

O build faz três coisas: baixa o **Kali rolling**, instala o **OpenCode** e o
**Herdr** e clona o **opencode-pentester** em `/opt/opencode-pentester`.

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

## O que já vem pronto na imagem

| Caminho dentro do container | Conteúdo |
|---|---|
| `/workspace` | Diretório de trabalho do agente (recebe o bind mount do seu projeto) |
| `/opt/opencode-pentester` | Framework **clonado durante o build** (fora do bind mount, sempre disponível) |
| `/workspace/opencode-pentester` | Link simbólico para `/opt/opencode-pentester`, criado na subida do container |
| `/home/kaliuser/.opencode/bin/opencode` | Binário do OpenCode (no `PATH` da imagem) |
| `/home/kaliuser/.local/bin/herdr` | Binário do Herdr (no `PATH` da imagem) |
| `/home/kaliuser/.config/herdr/config.toml` | Config do Herdr — **você precisa criar** (veja abaixo) |
| `/home/kaliuser/.config/opencode/plugins/` | Plugin do Herdr — instalado com `herdr integration install opencode` |
| `/home/kaliuser/.local/share/opencode` | `auth.json`, banco, sessões e logs do OpenCode |

### Usuário `kaliuser` e `sudo`

O container **não roda como root**. A imagem cria o usuário `kaliuser`
(uid `1000`, home em `/home/kaliuser`) e o Compose não sobrescreve esse
usuário.

```bash
docker compose run --rm sandbox bash -lc '
  id -un                 # kaliuser
  id -u                  # 1000
  echo $HOME             # /home/kaliuser
  sudo -n true && echo "sudo sem senha: OK"
'
```

O `sudo` sem senha existe porque as ferramentas de pentest precisam de
privilégios (raw sockets, `tcpdump`, criação de interfaces). Na prática,
**o agente consegue virar root dentro do container** — a fronteira de
segurança é o container, não o usuário.

Consequência prática: os arquivos criados no bind mount belong ao uid `1000`
do container. Em Linux, esse é o uid da maioria dos usuários de desktop, então
costuma "dar certo"; em macOS/Windows (Docker Desktop) as permissões são
virtualizadas e não há problema. Se aparecer `permission denied`, ajuste no
host: `sudo chown -R $(id -u) .`.

### Onde fica o `opencode-pentester`

O framework é clonado **durante o build** em:

```
/opt/opencode-pentester
```

Ele fica **fora** de `/workspace` de propósito: o Compose monta a sua pasta do
host sobre `/workspace` (bind mount) e cobriria qualquer arquivo que estivesse
ali, deixando o framework invisível em tempo de execução — era exatamente o
que acontecia antes desta correção.

Na subida do container, o Compose cria um link simbólico dentro do workspace,
para o agente encontrar o framework onde trabalha:

```bash
docker compose run --rm sandbox bash -lc '
  ls -l /workspace/opencode-pentester   # -> /opt/opencode-pentester
  echo $OPENCODE_PENTESTER_DIR           # -> /opt/opencode-pentester
  ls /opt/opencode-pentester | head'
```

> O link é criado em modo *best effort*: se a pasta do host não for gravável
> pelo uid `1000` do container, o link é ignorado silenciosamente. Nesse
> caso, use sempre o caminho canônico `/opt/opencode-pentester` (ou a variável
> `$OPENCODE_PENTESTER_DIR`).

Se preferir ter o framework **dentro** da pasta do host (por exemplo para o
`git status` do projeto não mostrar um link estranho), copie a partir da
imagem:

```bash
# Copia o framework da imagem para a pasta do host
docker run --rm -v "$PWD:/out" --entrypoint bash opencode-sandbox:latest -lc \
  'cp -a /opt/opencode-pentester /out/'
```

### Config inicial do Herdr

A imagem atual **não** traz um `config.toml`. Sem ele, o Herdr mostra o
onboarding de primeiro uso — que não dá para responder dentro de um
container. Crie o arquivo uma vez:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/herdr
  cat > ~/.config/herdr/config.toml <<"EOF"
  onboarding = false

  [terminal]
  default_shell = "/bin/bash"

  [server]
  headless_cols = 120
  headless_rows = 40

  [ui.sound]
  enabled = false
  EOF'
```

> Alternativa: `herdr --default-config > ~/.config/herdr/config.toml` escreve a
> configuração completa padrão do Herdr.

Para a sidebar mostrar o estado do agente (`working`, `blocked`, `done`,
`idle`), instale a integração oficial:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/opencode
  herdr integration install opencode'
```

Isso grava `~/.config/opencode/plugins/herdr-agent-state.js`. Reinicie o
OpenCode depois de instalar.

## Uso

### 1. Login do OpenCode

O OpenCode precisa de um provedor de modelo. Na primeira execução:

```bash
docker compose run --rm sandbox opencode auth login
```

Ou, dentro da TUI do OpenCode, use o comando `/connect`.
O token fica salvo em `/home/kaliuser/.local/share/opencode/auth.json` — num
volume nomeado, **sobrevive à recriação do container**; sem volume (configuração
atual), ele é **perdido** a cada `docker compose run --rm`. Veja
[Volumes e persistência](#volumes-e-persistência).

### 2. Organizando o trabalho com o Herdr

O Herdr gerencia *workspaces* (projetos), *tabs* e *panes* (terminais).
Dentro de um pane você roda o OpenCode; o Herdr detecta o agente e mostra o
estado (`working`, `blocked`, `done`, `idle`) na barra lateral — desde que a
[integração](#config-inicial-do-herdr) esteja instalada.

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

### 5. Rodando uma auditoria com o `opencode-pentester`

Com o framework em `/opt/opencode-pentester` (também acessível como
`/workspace/opencode-pentester`, veja
[Onde fica o opencode-pentester](#onde-fica-o-opencode-pentester)):

```bash
# Instala as ~75 ferramentas de pentest e registra a skill no OpenCode
docker compose run --rm sandbox bash -lc '
  cd "$OPENCODE_PENTESTER_DIR" && sudo bash install.sh'

# Confere quais tools estão disponíveis
docker compose run --rm sandbox bash -lc '
  cd "$OPENCODE_PENTESTER_DIR" && bash db/doctor.sh'
```

Depois, dentro do container, é só chamar o agente:

```bash
# Pentest com autorização explícita
opencode run "Tenho autorização para testar https://alvo.com. Use opencode-pentester. Orçamento de tempo: 120 minutos."

# Auditoria defensiva do seu próprio código
cp "$OPENCODE_PENTESTER_DIR/AGENTS.md" /workspace/meu-projeto/AGENTS.md
opencode run "Execute a auditoria de segurança definida em AI-CHECKLIST.MD neste projeto"
```

> ⚠️ O `install.sh` baixa dezenas de ferramentas (nmap, sqlmap, nuclei,
> ffuf, metasploit, bloodhound...). Reserve tempo e disco, e use
> `bash install.sh --global-only` se quiser pular a instalação.
>
> ⚠️ As ferramentas instaladas e o banco de findings ficam na camada do
> container: um `docker compose run --rm` novo começa do zero. O código do
> framework, em si, continua lá — ele vem da imagem.

## Instalando ferramentas de pentest

A imagem é **intencionalmente mínima**: só o runtime do OpenCode e do Herdr.
O filesystem do container é **gravável**, então o `apt-get install` funciona
diretamente — com `sudo`, porque o usuário padrão é o `kaliuser`:

```bash
docker compose run --rm sandbox bash -lc '
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    nmap sqlmap ffuf gobuster nikto whatweb'
```

> ⚠️ As ferramentas instaladas nesse passo são **efêmeras**: somem quando o
> container é recriado (`docker compose run --rm`). Para torná-las
> permanentes, grave-as na imagem.

**Extendendo a imagem (permanente):**

```dockerfile
FROM opencode-sandbox:latest
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap sqlmap ffuf gobuster nikto whatweb \
    && rm -rf /var/lib/apt/lists/*
```

```bash
docker build -f Dockerfile.tools -t opencode-sandbox:tools .
```

E aponte o Compose para ela sem editar o `docker-compose.yml`, usando um
override:

```yaml
# docker-compose.tools.yml
services:
  sandbox:
    image: opencode-sandbox:tools
    build: null
```

```bash
docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox
```

> ⚠️ `kali-linux-meta` / `kali-tools-full` instalam **toda** a suíte do Kali
> (dezenas de GB). Prefira listas curtas e sob medida — ou use o
> `install.sh` do `opencode-pentester`, que faz a curadoria por você.

## Volumes e persistência

| Tipo | Host / Origem | No container | O que guarda |
|---|---|---|---|
| Bind mount | `.` (a pasta do projeto) | `/workspace` | O código em que o agente trabalha |
| Volume nomeado | `opencode-config` | `/home/kaliuser/.config/opencode` | Config do OpenCode |
| Volume nomeado | `opencode-data` | `/home/kaliuser/.local/share/opencode` | `auth.json`, banco, sessões, logs |
| Volume nomeado | `opencode-state` | `/home/kaliuser/.local/state/opencode` | Registro do serviço em background |
| Volume nomeado | `herdr-config` | `/home/kaliuser/.config/herdr` | `config.toml` do Herdr |
| Volume nomeado | `herdr-state` | `/home/kaliuser/.herdr` | Worktrees, sessão e estado do Herdr |

> ⚠️ **Estado atual:** as linhas de volumes nomeados estão **comentadas** no
> `docker-compose.yml` — e ainda apontam para `/root/...`, caminho da versão
> anterior, quando o container rodava como root. Na prática, hoje existe
> **apenas o bind mount `.:/workspace`** — config, login e sessões vivem na
> camada gravável do container e são perdidos a cada recriação. Os volumes
> declarados no fim do arquivo existem, mas não são montados em lugar nenhum.
>
> Se você descomentar as linhas do Compose, ajuste os caminhos para
> `/home/kaliuser/...` (é onde o usuário `kaliuser` realmente grava).

### Como persistir sem editar o Compose

Crie um override que monta os volumes nos caminhos do `kaliuser`:

```yaml
# docker-compose.persist.yml
services:
  sandbox:
    volumes:
      - opencode-config:/home/kaliuser/.config/opencode
      - opencode-data:/home/kaliuser/.local/share/opencode
      - opencode-state:/home/kaliuser/.local/state/opencode
      - herdr-config:/home/kaliuser/.config/herdr
      - herdr-state:/home/kaliuser/.herdr

volumes:
  opencode-config:
  opencode-data:
  opencode-state:
  herdr-config:
  herdr-state:
```

```bash
docker compose -f docker-compose.yml -f docker-compose.persist.yml run --rm sandbox
```

Volume nomeado em caminho que não existe na imagem é criado **com dono
`root`**. Corrija a permissão uma vez:

```bash
docker compose -f docker-compose.yml -f docker-compose.persist.yml run --rm sandbox bash -lc '
  sudo chown -R kaliuser:kaliuser \
    /home/kaliuser/.config/opencode \
    /home/kaliuser/.local/share/opencode \
    /home/kaliuser/.local/state/opencode \
    /home/kaliuser/.config/herdr \
    /home/kaliuser/.herdr'
```

Os volumes nomeados são **preferidos a bind mounts do `~`** porque funcionam
igual em Linux, macOS e Windows, sem problemas de permissão de arquivo.

⚠️ O bind mount `.:/workspace` dá **acesso de escrita ao agente sobre a sua
pasta**. Use um diretório dedicado para os alvos, não a sua pasta pessoal.

Recomeçar do zero (apaga containers e volumes):

```bash
docker compose down -v
```

## 🔒 Segurança do sandbox

O sandbox roda **dentro de uma VM**, então você já tem duas camadas: a VM
contém o host, e o container contém o workspace. O que a configuração atual
garante **dentro** do container:

| Controle | Efeito |
|---|---|
| Usuário padrão `kaliuser` | O agente não roda como root por padrão |
| `sudo` sem senha | Root sob demanda — as tools de pentest precisam (raw sockets, `tcpdump`). Anula o isolamento de *usuário*, não o de *container* |
| `init: true` | PID 1 faz o reaping de processos (o Herdr abre vários subprocessos) |
| Sem `privileged` | Sem escape de container |
| Sem `network_mode: host` | Rede `bridge` padrão |
| Sem `docker.sock` | O container não controla o host |
| Bind mount único (`.:/workspace`) | Escrita restrita ao workspace |
| Rootfs gravável | O container pode ser alterado em runtime (efêmero) |
| Limites de recursos | `pids_limit=4096`, `mem_limit=8g` e `cpus=4` — tetos (não reservas), ajustáveis por `SANDBOX_PIDS_LIMIT`, `SANDBOX_MEM_LIMIT` e `SANDBOX_CPUS` |

### O que **não** fazer

- ❌ **Nunca** monte `/var/run/docker.sock` — equivale a dar root na sua máquina.
- ❌ Nunca use `--privileged` — derruba todas as proteções acima.
- ❌ Nunca monte `/`, `/etc` ou `/root` do host.
- ❌ Não rode alvo de terceiros sem autorização por escrito.
- ❌ Não confie no usuário não-root como barreira: com `sudo` sem senha, o
  agente é root dentro do container.

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

Limites de recursos — já existem no Compose, mas podem ser ajustados sem
editar nada, por variável de ambiente:

```bash
# VM menor: aperta os tetos
SANDBOX_PIDS_LIMIT=1024 SANDBOX_MEM_LIMIT=4g SANDBOX_CPUS=2 \
  docker compose run --rm sandbox
```

Ou por override, se quiser valores diferentes dos três ao mesmo tempo:

```bash
cat > docker-compose.limits.yml <<'EOF'
services:
  sandbox:
    pids_limit: 512
    mem_limit: 4g
    cpus: 2.0
EOF

docker compose -f docker-compose.yml -f docker-compose.limits.yml run --rm sandbox
```

> Os valores padrão são **tetos**, não reservas: só mordem quando o sandbox
> sai do controle (fork bomb, tool de pentest comendo a VM). Por isso são
> generosos — `nuclei`, `ffuf`, `masscan` e `metasploit` abrem muitos
> processos e consome memória.

> ⚠️ **`no-new-privileges:true` é incompatível com o `sudo`**: o bit
> `no_new_privs` faz o kernel ignorar o bit setuid, e o `sudo` deixa de
> funcionar. Só use os dois se aceitar perder o `sudo`.
>
> ⚠️ `read_only: true` exige volumes para todos os caminhos graváveis
> (`/home/kaliuser/...`, `/tmp`, `/run`), senão o OpenCode e o Herdr não
> sobem.

Como o sandbox roda **dentro de uma VM**, a fronteira mais forte já existe:
o kernel da VM, e não o do host. Dentro dela, o container ainda usa o kernel
do Docker — se quiser uma camada extra, use gVisor (`--runtime=runsc`) ou
Firecracker. Num host compartilhado (sem VM), considere um runner descartável.

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
- **`auth.json` guarda tokens.** Hoje ele vive na camada do container e some
  com ele; se você montar volumes, trate-os como credenciais:
  `docker compose down -v` quando não precisar mais.
- **O `opencode-pentester` embutido tem termos próprios** (veja o
  [DISCLAIMER.md](https://github.com/humaidhahm/opencode-pentester/blob/main/DISCLAIMER.md)
  dele): ele recusa alvos fora de escopo, mas a responsabilidade final é sua.

## Rede

O container usa a rede `bridge` padrão do Docker, com **saída para a internet**
(necessária para o login do OpenCode e para alcançar os alvos). Veja as opções
de isolamento acima.

## Atualizando

O OpenCode e o Herdr são instalados no **build**, então a atualização
durável acontece reconstruindo a imagem:

```bash
# Atualizar a imagem base (Kali) e reinstalar OpenCode/Herdr
docker compose build --no-cache --pull
docker compose run --rm sandbox opencode --version
docker compose run --rm sandbox herdr --version
```

O `opencode-pentester` também é clonado no build — use `--no-cache` para
buscar a versão mais nova do repositório.

Dentro de um container em execução, `opencode upgrade` e `herdr update`
funcionam (o rootfs é gravável), mas a atualização é **perdida** quando o
container é recriado: reconstrua a imagem.

> ✅ O build arg `OPENCODE_VERSION` funciona: o `Dockerfile` declara
> `ARG OPENCODE_VERSION` e o instalador oficial aceita `--version`. Para fixar
> a versão do OpenCode:
>
> ```bash
> OPENCODE_VERSION=0.0.0-beta-17236 docker compose build
> ```
>
> Sem a variável, o build instala a `latest`. O Herdr **não** tem version
> pin no Dockerfile — só o OpenCode.

## CI/CD

O workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) roda em
todo push na `main` e em cada pull request:

| Etapa | O que valida |
|---|---|
| `docker compose config -q` | O Compose é sintaticamente válido |
| Postura de segurança (estática) | Nada de `privileged`, `docker.sock`, `network_mode: host` ou `pid/ipc: host` — e presença de `pids_limit`, `mem_limit` e `cpus` |
| Dockerfile (estático) | `SHELL` com `pipefail`, `ARG OPENCODE_VERSION` declarado e `tar` instalado |
| Build da imagem | A imagem compila do zero (Kali + OpenCode + Herdr + clone do framework) |
| Conteúdo da imagem | `USER` é `kaliuser`, `/workspace` pertence ao `kaliuser`, `tar`/`unzip` presentes e o `opencode-pentester` está clonado em `/opt/opencode-pentester` |
| Framework em runtime | O `opencode-pentester` existe em `/opt/opencode-pentester` **e** aparece linkado em `/workspace/opencode-pentester` (regressão do bug do bind mount) |
| Smoke test | Usuário padrão, `HOME`, `sudo` sem senha, binários no `PATH`, home gravável |
| Herdr headless | O servidor sobe e responde a `herdr status server` |
| Integração Herdr + OpenCode | `herdr integration install opencode` grava o plugin de estado do agente |

O CI **não** executa nenhum pentest nem toca em alvos externos — apenas
builda e faz smoke test do sandbox.

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
<summary><b>"opencode: command not found" ou "herdr: command not found"</b></summary>

O `PATH` da imagem já inclui `~/.opencode/bin` e `~/.local/bin`. Se o shell
não herdou o ambiente (por exemplo, um `sh` sem login), exporte manualmente:

```bash
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
```

E confira onde os binários realmente estão:

```bash
docker compose run --rm sandbox bash -lc 'ls -l ~/.opencode/bin ~/.local/bin'
```
</details>

<details>
<summary><b>O Herdr abre o onboarding e trava</b></summary>

Esperado: sem `config.toml`, o Herdr mostra o onboarding de primeiro uso, que
não dá para responder dentro de um container. Crie o arquivo com
`onboarding = false` — veja
[Config inicial do Herdr](#config-inicial-do-herdr).
</details>

<details>
<summary><b>A sidebar não mostra o estado do agente (fica "idle")</b></summary>

A integração oficial não vem na imagem. Instale dentro do container:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/opencode
  herdr integration install opencode'
```

Diagnóstico: `herdr agent explain <alvo> --json`.
</details>

<details>
<summary><b><code>/workspace/opencode-pentester</code> não existe (ou o link some)</b></summary>

O link simbólico é criado na subida do container e é *best effort*: se a pasta
do host não for gravável pelo uid `1000`, ele não é criado. Use o caminho
canônico, que vem da imagem e **nunca** é coberto pelo bind mount:

```bash
docker compose run --rm sandbox bash -lc '
  echo $OPENCODE_PENTESTER_DIR          # /opt/opencode-pentester
  ls "$OPENCODE_PENTESTER_DIR" | head'
```

Se preferir o framework dentro da pasta do host, copie a partir da imagem
(veja [Onde fica o opencode-pentester](#onde-fica-o-opencode-pentester)).
</details>

<details>
<summary><b>"permission denied" ao gravar no workspace</b></summary>

O container roda como `kaliuser` (uid `1000`). Os arquivos criados no host
ficam com esse uid. Ajuste as permissões da pasta hospedeira
(`sudo chown -R $(id -u) .`).
</details>

<details>
<summary><b>"permission denied" em volume nomeado recém-criado</b></summary>

Volume novo é criado com dono `root`. Corrija com `sudo chown -R
kaliuser:kaliuser /home/kaliuser/...` — veja
[Como persistir sem editar o Compose](#como-persistir-sem-editar-o-compose).
</details>

<details>
<summary><b>O build falha com "'tar' is required but not installed"</b></summary>

O instalador do OpenCode precisa de `tar`. A base Kali nem sempre o traz:

```bash
docker compose build --no-cache
```

Se o erro persistir, adicione `tar` (e `ca-certificates`) ao `apt-get install`
do Dockerfile.
</details>

<details>
<summary><b>O OpenCode não conecta / serviço travado</b></summary>

```bash
docker compose run --rm sandbox bash -lc '
  opencode service status
  opencode service restart
  tail -f ~/.local/share/opencode/log/opencode.log'
```
</details>

<details>
<summary><b>Erro de som / notificação</b></summary>

Containers não têm placa de som. O Compose já define `HERDR_DISABLE_SOUND=1`;
no `config.toml` do Herdr use `[ui.sound] enabled = false`.
</details>

<details>
<summary><b>Erro ao rodar <code>opencode upgrade</code> / <code>herdr update</code></b></summary>

Esperado: o rootfs é gravável, então o upgrade funciona — mas a mudança é
perdida quando o container é recriado. Reconstrua a imagem
(`docker compose build --no-cache`) para uma atualização durável.
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
├── Dockerfile                  # imagem: Kali + OpenCode + Herdr + kaliuser + opencode-pentester
├── docker-compose.yml          # serviço "sandbox", volumes e isolamento
├── .github/workflows/build.yml # CI: build + smoke test + verificação da postura de segurança
├── .dockerignore               # contexto de build enxuto
├── .gitignore                  # segredos e artefatos
├── LICENSE                     # MIT
└── README.md
```

E dentro do container:

```
/workspace
├── (bind mount) .              # o seu projeto
└── opencode-pentester -> /opt/opencode-pentester   # link criado na subida

/opt
└── opencode-pentester/         # framework clonado durante o build

/home/kaliuser
├── .opencode/bin/opencode      # binário do OpenCode
├── .local/bin/herdr            # binário do Herdr
├── .config/opencode/           # config do OpenCode + plugin do Herdr
├── .config/herdr/config.toml   # config do Herdr
├── .local/share/opencode/      # auth.json, banco, sessões e logs
└── .herdr/                     # worktrees, sessão e estado do Herdr
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

The build does three things: pulls **Kali rolling**, installs **OpenCode** and
**Herdr** and clones **opencode-pentester** into
`/opt/opencode-pentester`.

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

## What ships in the image

| Path inside the container | Contents |
|---|---|
| `/workspace` | Agent working directory (receives the bind mount of your project) |
| `/opt/opencode-pentester` | Framework **cloned at build time** (outside the bind mount, always available) |
| `/workspace/opencode-pentester` | Symlink to `/opt/opencode-pentester`, created when the container starts |
| `/home/kaliuser/.opencode/bin/opencode` | OpenCode binary (already on the image `PATH`) |
| `/home/kaliuser/.local/bin/herdr` | Herdr binary (already on the image `PATH`) |
| `/home/kaliuser/.config/herdr/config.toml` | Herdr config — **you have to create it** (see below) |
| `/home/kaliuser/.config/opencode/plugins/` | Herdr plugin — installed with `herdr integration install opencode` |
| `/home/kaliuser/.local/share/opencode` | `auth.json`, database, sessions and logs |

### The `kaliuser` user and `sudo`

The container **does not run as root**. The image creates the `kaliuser` user
(uid `1000`, home at `/home/kaliuser`) and Compose does not override it.

```bash
docker compose run --rm sandbox bash -lc '
  id -un                 # kaliuser
  id -u                  # 1000
  echo $HOME             # /home/kaliuser
  sudo -n true && echo "passwordless sudo: OK"
'
```

Passwordless `sudo` exists because pentest tooling needs privileges (raw
sockets, `tcpdump`, interface creation). In practice **the agent can become
root inside the container** — the security boundary is the container, not the
user.

Practical consequence: files created in the bind mount belong to uid `1000`
inside the container. On Linux that is the uid of most desktop users, so it
usually "just works"; on macOS/Windows (Docker Desktop) permissions are
virtualized and there is no issue. If you hit `permission denied`, fix it on
the host: `sudo chown -R $(id -u) .`.

### Where `opencode-pentester` lives

The framework is cloned **at build time** into:

```
/opt/opencode-pentester
```

It lives **outside** `/workspace` on purpose: Compose mounts your host folder
over `/workspace` (bind mount), which would cover anything sitting there and
leave the framework invisible at runtime — exactly what used to happen before
this fix.

When the container starts, Compose creates a symlink inside the workspace so
the agent finds the framework exactly where it works:

```bash
docker compose run --rm sandbox bash -lc '
  ls -l /workspace/opencode-pentester   # -> /opt/opencode-pentester
  echo $OPENCODE_PENTESTER_DIR           # -> /opt/opencode-pentester
  ls /opt/opencode-pentester | head'
```

> The symlink is created on a *best effort* basis: if the host folder is not
> writable by the container's uid `1000`, the link is silently skipped. In
> that case, always use the canonical path `/opt/opencode-pentester` (or the
> `$OPENCODE_PENTESTER_DIR` variable).

If you prefer the framework **inside** your host folder (so the project's
`git status` does not show a stray symlink), copy it from the image:

```bash
# Copy the framework from the image into the host folder
docker run --rm -v "$PWD:/out" --entrypoint bash opencode-sandbox:latest -lc \
  'cp -a /opt/opencode-pentester /out/'
```

### Initial Herdr config

The current image **does not** ship a `config.toml`. Without it, Herdr shows
the first-run onboarding — which cannot be answered inside a container. Create
the file once:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/herdr
  cat > ~/.config/herdr/config.toml <<"EOF"
  onboarding = false

  [terminal]
  default_shell = "/bin/bash"

  [server]
  headless_cols = 120
  headless_rows = 40

  [ui.sound]
  enabled = false
  EOF'
```

> Alternative: `herdr --default-config > ~/.config/herdr/config.toml` writes the
> full default Herdr configuration.

To make the sidebar show the agent state (`working`, `blocked`, `done`,
`idle`), install the official integration:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/opencode
  herdr integration install opencode'
```

That writes `~/.config/opencode/plugins/herdr-agent-state.js`. Restart
OpenCode afterwards.

## Usage

### 1. OpenCode login

OpenCode needs a model provider. On first run:

```bash
docker compose run --rm sandbox opencode auth login
```

Or, from inside the OpenCode TUI, use the `/connect` command.
The token is stored in `/home/kaliuser/.local/share/opencode/auth.json` — in a
named volume it **survives container recreation**; without a volume (the
current setup) it is **lost** on every `docker compose run --rm`. See
[Volumes and persistence](#volumes-and-persistence).

### 2. Driving the work with Herdr

Herdr manages *workspaces* (projects), *tabs* and *panes* (terminals).
Run OpenCode inside a pane; Herdr detects the agent and shows its state
(`working`, `blocked`, `done`, `idle`) in the sidebar — as long as the
[integration](#initial-herdr-config) is installed.

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

### 5. Running an audit with `opencode-pentester`

With the framework in `/opt/opencode-pentester` (also reachable as
`/workspace/opencode-pentester`, see
[Where opencode-pentester lives](#where-opencode-pentester-lives)):

```bash
# Installs the ~75 pentest tools and registers the skill in OpenCode
docker compose run --rm sandbox bash -lc '
  cd "$OPENCODE_PENTESTER_DIR" && sudo bash install.sh'

# Check which tools are available
docker compose run --rm sandbox bash -lc '
  cd "$OPENCODE_PENTESTER_DIR" && bash db/doctor.sh'
```

Then, inside the container, just call the agent:

```bash
# Pentest with explicit authorization
opencode run "I have authorization to test https://target.com. Use opencode-pentester. Time budget: 120 minutes."

# Defensive audit of your own code
cp "$OPENCODE_PENTESTER_DIR/AGENTS.md" /workspace/my-project/AGENTS.md
opencode run "Run the security audit defined in AI-CHECKLIST.MD against this project"
```

> ⚠️ `install.sh` downloads dozens of tools (nmap, sqlmap, nuclei, ffuf,
> metasploit, bloodhound...). Budget time and disk, or use
> `bash install.sh --global-only` to skip the installation.
>
> ⚠️ The installed tools and the findings database live in the container
> layer: a new `docker compose run --rm` starts from zero. The framework
> source itself stays there — it comes from the image.

## Installing pentest tooling

The image is **intentionally minimal**: only the OpenCode + Herdr runtime.
The container filesystem is **writable**, so `apt-get install` works directly —
with `sudo`, because the default user is `kaliuser`:

```bash
docker compose run --rm sandbox bash -lc '
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    nmap sqlmap ffuf gobuster nikto whatweb'
```

> ⚠️ Tools installed this way are **ephemeral**: they are gone when the
> container is recreated (`docker compose run --rm`). To make them permanent,
> bake them into the image.

**Extending the image (permanent):**

```dockerfile
FROM opencode-sandbox:latest
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap sqlmap ffuf gobuster nikto whatweb \
    && rm -rf /var/lib/apt/lists/*
```

```bash
docker build -f Dockerfile.tools -t opencode-sandbox:tools .
```

And point Compose at it without editing `docker-compose.yml`, using an
override:

```yaml
# docker-compose.tools.yml
services:
  sandbox:
    image: opencode-sandbox:tools
    build: null
```

```bash
docker compose -f docker-compose.yml -f docker-compose.tools.yml run --rm sandbox
```

> ⚠️ `kali-linux-meta` / `kali-tools-full` install the **entire** Kali suite
> (tens of GB). Prefer short, purpose-built lists — or use the
> `opencode-pentester` `install.sh`, which curates them for you.

## Volumes and persistence

| Type | Host / Source | In container | What it stores |
|---|---|---|---|
| Bind mount | `.` (the project folder) | `/workspace` | The code the agent works on |
| Named volume | `opencode-config` | `/home/kaliuser/.config/opencode` | OpenCode config |
| Named volume | `opencode-data` | `/home/kaliuser/.local/share/opencode` | `auth.json`, database, sessions, logs |
| Named volume | `opencode-state` | `/home/kaliuser/.local/state/opencode` | Background service registration |
| Named volume | `herdr-config` | `/home/kaliuser/.config/herdr` | Herdr `config.toml` |
| Named volume | `herdr-state` | `/home/kaliuser/.herdr` | Worktrees, session and Herdr state |

> ⚠️ **Current state:** the named-volume lines are **commented out** in
> `docker-compose.yml` — and they still point to `/root/...`, the path from the
> previous version, when the container ran as root. In practice there is
> **only the `.:/workspace` bind mount** today — config, login and sessions
> live in the container's writable layer and are lost on every recreation. The
> volumes declared at the bottom of the file exist, but are not mounted
> anywhere.
>
> If you uncomment those lines, fix the paths to `/home/kaliuser/...` (that is
> where the `kaliuser` user actually writes).

### How to persist without editing Compose

Create an override that mounts the volumes at the `kaliuser` paths:

```yaml
# docker-compose.persist.yml
services:
  sandbox:
    volumes:
      - opencode-config:/home/kaliuser/.config/opencode
      - opencode-data:/home/kaliuser/.local/share/opencode
      - opencode-state:/home/kaliuser/.local/state/opencode
      - herdr-config:/home/kaliuser/.config/herdr
      - herdr-state:/home/kaliuser/.herdr

volumes:
  opencode-config:
  opencode-data:
  opencode-state:
  herdr-config:
  herdr-state:
```

```bash
docker compose -f docker-compose.yml -f docker-compose.persist.yml run --rm sandbox
```

A named volume mounted on a path that does not exist in the image is created
**owned by `root`**. Fix the permission once:

```bash
docker compose -f docker-compose.yml -f docker-compose.persist.yml run --rm sandbox bash -lc '
  sudo chown -R kaliuser:kaliuser \
    /home/kaliuser/.config/opencode \
    /home/kaliuser/.local/share/opencode \
    /home/kaliuser/.local/state/opencode \
    /home/kaliuser/.config/herdr \
    /home/kaliuser/.herdr'
```

Named volumes are **preferred over bind-mounting `~`** because they behave the
same on Linux, macOS and Windows, with no file permission quirks.

⚠️ The `.:/workspace` bind mount gives the agent **write access to your
folder**. Use a dedicated directory for targets, not your personal one.

Start completely fresh (drops containers and volumes):

```bash
docker compose down -v
```

## 🔒 Sandbox security

The sandbox runs **inside a VM**, so you already have two layers: the VM
contains the host, and the container contains the workspace. What the current
configuration guarantees **inside** the container:

| Control | Effect |
|---|---|
| Default user `kaliuser` | The agent does not run as root by default |
| Passwordless `sudo` | Root on demand — pentest tooling needs it (raw sockets, `tcpdump`). It cancels *user* isolation, not *container* isolation |
| `init: true` | PID 1 reaps processes (Herdr spawns many) |
| No `privileged` | No container escape |
| No `network_mode: host` | Default `bridge` network |
| No `docker.sock` | The container cannot control the host |
| Single bind mount (`.:/workspace`) | Writes restricted to the workspace |
| Writable rootfs | The container can be modified at runtime (ephemeral) |
| Resource limits | `pids_limit=4096`, `mem_limit=8g` and `cpus=4` — caps (not reservations), tunable via `SANDBOX_PIDS_LIMIT`, `SANDBOX_MEM_LIMIT` and `SANDBOX_CPUS` |

### What **not** to do

- ❌ **Never** bind-mount `/var/run/docker.sock` — that is root on your machine.
- ❌ Never use `--privileged` — it removes every protection above.
- ❌ Never mount the host's `/`, `/etc` or `/root`.
- ❌ Do not target third-party systems without written authorization.
- ❌ Do not rely on the non-root user as a barrier: with passwordless `sudo`
  the agent is root inside the container.

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

Resource limits — they already exist in the Compose file, but you can tune them
without editing anything, through an environment variable:

```bash
# Smaller VM: tighten the caps
SANDBOX_PIDS_LIMIT=1024 SANDBOX_MEM_LIMIT=4g SANDBOX_CPUS=2 \
  docker compose run --rm sandbox
```

Or through an override, if you want to change all three at once:

```bash
cat > docker-compose.limits.yml <<'EOF'
services:
  sandbox:
    pids_limit: 512
    mem_limit: 4g
    cpus: 2.0
EOF

docker compose -f docker-compose.yml -f docker-compose.limits.yml run --rm sandbox
```

> The defaults are **caps**, not reservations: they only bite when the sandbox
> goes out of control (fork bomb, a pentest tool eating the VM). That is why
> they are generous — `nuclei`, `ffuf`, `masscan` and `metasploit` spawn many
> processes and consume memory.

> ⚠️ **`no-new-privileges:true` is incompatible with `sudo`**: the
> `no_new_privs` bit makes the kernel ignore the setuid bit, so `sudo` stops
> working. Only use both if you accept losing `sudo`.
>
> ⚠️ `read_only: true` requires volumes for every writable path
> (`/home/kaliuser/...`, `/tmp`, `/run`), otherwise OpenCode and Herdr cannot
> start.

Since the sandbox runs **inside a VM**, the strongest boundary already exists:
the VM's kernel, not the host's. Inside it, the container still shares the
Docker kernel — if you want one more layer, use gVisor (`--runtime=runsc`) or
Firecracker. On a shared host (no VM), consider a disposable runner.

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
- **`auth.json` holds access tokens.** Today it lives in the container layer
  and dies with it; if you mount volumes, treat them as credentials:
  run `docker compose down -v` when you no longer need them.
- **The bundled `opencode-pentester` has its own terms** (see its
  [DISCLAIMER.md](https://github.com/humaidhahm/opencode-pentester/blob/main/DISCLAIMER.md)):
  it refuses out-of-scope targets, but the final responsibility is yours.

## Network

The container uses Docker's default `bridge` network, with **internet egress**
(required for the OpenCode login and to reach the targets). See the isolation
options above.

## Updating

OpenCode and Herdr are installed **at build time**, so durable upgrades happen
by rebuilding the image:

```bash
# Update the base image (Kali) and reinstall OpenCode/Herdr
docker compose build --no-cache --pull
docker compose run --rm sandbox opencode --version
docker compose run --rm sandbox herdr --version
```

`opencode-pentester` is cloned at build time too — use `--no-cache` to pull
the newest revision of the repository.

Inside a running container, `opencode upgrade` and `herdr update` do work
(the rootfs is writable), but the upgrade is **lost** when the container is
recreated: rebuild the image.

> ✅ The `OPENCODE_VERSION` build arg works: the `Dockerfile` declares
> `ARG OPENCODE_VERSION` and the official installer accepts `--version`. To pin
> the OpenCode version:
>
> ```bash
> OPENCODE_VERSION=0.0.0-beta-17236 docker compose build
> ```
>
> Without the variable, the build installs `latest`. Herdr has **no** version
> pin in the Dockerfile — only OpenCode does.

## CI/CD

The [`.github/workflows/build.yml`](.github/workflows/build.yml) workflow runs
on every push to `main` and on every pull request:

| Step | What it validates |
|---|---|
| `docker compose config -q` | The Compose file is syntactically valid |
| Security posture (static) | No `privileged`, `docker.sock`, `network_mode: host` or `pid/ipc: host` — and that `pids_limit`, `mem_limit` and `cpus` are present |
| Dockerfile (static) | `SHELL` with `pipefail`, `ARG OPENCODE_VERSION` declared and `tar` installed |
| Image build | The image builds from scratch (Kali + OpenCode + Herdr + framework clone) |
| Image contents | `USER` is `kaliuser`, `/workspace` is owned by `kaliuser`, `tar`/`unzip` are present and `opencode-pentester` is cloned into `/opt/opencode-pentester` |
| Framework at runtime | `opencode-pentester` exists in `/opt/opencode-pentester` **and** shows up symlinked in `/workspace/opencode-pentester` (regression guard for the bind-mount bug) |
| Smoke test | Default user, `HOME`, passwordless `sudo`, binaries on `PATH`, writable home |
| Herdr headless | The server starts and answers `herdr status server` |
| Herdr + OpenCode integration | `herdr integration install opencode` writes the agent-state plugin |

The CI **does not** run any pentest and never touches external targets — it
only builds and smoke-tests the sandbox.

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
<summary><b>"opencode: command not found" or "herdr: command not found"</b></summary>

The image `PATH` already includes `~/.opencode/bin` and `~/.local/bin`. If the
shell did not inherit the environment (e.g. a non-login `sh`), export it
manually:

```bash
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
```

And check where the binaries actually landed:

```bash
docker compose run --rm sandbox bash -lc 'ls -l ~/.opencode/bin ~/.local/bin'
```
</details>

<details>
<summary><b>Herdr shows the onboarding and hangs</b></summary>

Expected: without a `config.toml`, Herdr shows the first-run onboarding, which
cannot be answered inside a container. Create the file with
`onboarding = false` — see [Initial Herdr config](#initial-herdr-config).
</details>

<details>
<summary><b>Herdr does not detect the agent state (stays "idle")</b></summary>

The official integration does not ship in the image. Install it inside the
container:

```bash
docker compose run --rm sandbox bash -lc '
  mkdir -p ~/.config/opencode
  herdr integration install opencode'
```

Diagnostics: `herdr agent explain <target> --json`.
</details>

<details>
<summary><b><code>/workspace/opencode-pentester</code> does not exist (or the link is missing)</b></summary>

The symlink is created when the container starts and is *best effort*: if the
host folder is not writable by uid `1000`, it is not created. Use the
canonical path, which comes from the image and is **never** covered by the
bind mount:

```bash
docker compose run --rm sandbox bash -lc '
  echo $OPENCODE_PENTESTER_DIR          # /opt/opencode-pentester
  ls "$OPENCODE_PENTESTER_DIR" | head'
```

If you rather have the framework inside your host folder, copy it from the
image (see [Where opencode-pentester lives](#where-opencode-pentester-lives)).
</details>

<details>
<summary><b>"permission denied" when writing to the workspace</b></summary>

The container runs as `kaliuser` (uid `1000`), so files created on the host
are owned by that uid. Fix the host folder permissions
(`sudo chown -R $(id -u) .`).
</details>

<details>
<summary><b>"permission denied" on a freshly created named volume</b></summary>

New volumes are created owned by `root`. Fix it with `sudo chown -R
kaliuser:kaliuser /home/kaliuser/...` — see
[How to persist without editing Compose](#how-to-persist-without-editing-compose).
</details>

<details>
<summary><b>Build fails with "'tar' is required but not installed"</b></summary>

The OpenCode installer needs `tar`, and the Kali base image does not always
ship it:

```bash
docker compose build --no-cache
```

If it still fails, add `tar` (and `ca-certificates`) to the `apt-get install`
line in the Dockerfile.
</details>

<details>
<summary><b>OpenCode will not connect / stuck service</b></summary>

```bash
docker compose run --rm sandbox bash -lc '
  opencode service status
  opencode service restart
  tail -f ~/.local/share/opencode/log/opencode.log'
```
</details>

<details>
<summary><b>Sound / notification errors</b></summary>

Containers have no sound card. Compose already sets `HERDR_DISABLE_SOUND=1`;
use `[ui.sound] enabled = false` in the Herdr `config.toml`.
</details>

<details>
<summary><b>Errors running <code>opencode upgrade</code> / <code>herdr update</code></b></summary>

Expected: the rootfs is writable, so the upgrade works — but the change is
lost when the container is recreated. Rebuild the image
(`docker compose build --no-cache`) for a durable update.
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
├── Dockerfile                  # image: Kali + OpenCode + Herdr + kaliuser + opencode-pentester
├── docker-compose.yml          # "sandbox" service, volumes and isolation
├── .github/workflows/build.yml # CI: build + smoke test + security posture checks
├── .dockerignore               # slim build context
├── .gitignore                  # secrets and artifacts
├── LICENSE                     # MIT
└── README.md
```

And inside the container:

```
/workspace
├── (bind mount) .              # your project
└── opencode-pentester -> /opt/opencode-pentester   # link created at startup

/opt
└── opencode-pentester/         # framework cloned at build time

/home/kaliuser
├── .opencode/bin/opencode      # OpenCode binary
├── .local/bin/herdr            # Herdr binary
├── .config/opencode/           # OpenCode config + Herdr plugin
├── .config/herdr/config.toml   # Herdr config
├── .local/share/opencode/      # auth.json, database, sessions and logs
└── .herdr/                     # worktrees, session and Herdr state
```

---

## Licença

[MIT](LICENSE) © 2026 orionhack99

Este projeto não é afiliado, endossado ou mantido pelo Kali Linux, pela
OpenCode (anomalyco) ou pela Herdr (herdrdev). O framework
[opencode-pentester](https://github.com/humaidhahm/opencode-pentester) é um
projeto de terceiro, sob licença MIT.
