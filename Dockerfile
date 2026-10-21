# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Imagem base: Kali Linux rolling
#
# Esta imagem base é enxuta e NÃO traz ferramentas de pentest pré-instaladas.
# O objetivo aqui é apenas o runtime do OpenCode + Herdr sobre um sistema
# com o repositório Kali configurado, para você instalar o que precisar.
# ---------------------------------------------------------------------------
FROM kalilinux/kali-rolling:latest

# Versão fixa do OpenCode (vazio = "latest"). Fixe para builds reprodutíveis.
ARG OPENCODE_VERSION=""

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    # Diretório de instalação do Herdr (o instalador oficial respeita esta variável)
    HERDR_INSTALL_DIR=/usr/local/bin

# pipefail faz o build quebrar se um `curl | sh` falhar no meio do download.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------------
# Dependências básicas
#
# A imagem do Kali já é enxuta: NÃO traz ferramentas de pentest prontas.
# Aqui entram apenas o runtime mínimo para o OpenCode e o Herdr funcionarem.
# Para instalar ferramentas (nmap, sqlmap, ...), veja o README.
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        procps \
        sudo \
        tmux \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Herdr — instalador oficial (valida SHA-256 do binário antes de instalar)
# https://herdr.dev/docs/install/
# ---------------------------------------------------------------------------
RUN curl -fsSL --retry 3 --connect-timeout 10 https://herdr.dev/install.sh | sh \
    && herdr --version

# ---------------------------------------------------------------------------
# OpenCode — instalador oficial
# https://opencode.ai/v2/docs
# ---------------------------------------------------------------------------
RUN if [ -n "${OPENCODE_VERSION}" ]; then \
        curl -fsSL --retry 3 --connect-timeout 10 https://opencode.ai/v2/install | bash -s -- --version "${OPENCODE_VERSION}"; \
    else \
        curl -fsSL --retry 3 --connect-timeout 10 https://opencode.ai/v2/install | bash; \
    fi \
    && ln -sf /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && opencode --version

# ---------------------------------------------------------------------------
# PATH para shells de login e não-login
# ---------------------------------------------------------------------------
ENV PATH="/root/.opencode/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN printf '%s\n' \
        'export PATH="/root/.opencode/bin:$PATH"' \
        'export PATH="$HERDR_INSTALL_DIR:$PATH"' \
        > /etc/profile.d/opencode-herdr.sh \
    && chmod 0644 /etc/profile.d/opencode-herdr.sh

# ---------------------------------------------------------------------------
# Configuração do Herdr com defaults sensatos dentro de container
# ---------------------------------------------------------------------------
RUN mkdir -p /root/.config/herdr && cat > /root/.config/herdr/config.toml <<'EOF'
# Pular o onboarding interativo de primeiro uso (não há como responder dentro
# de um container não-interativo).
onboarding = false

[terminal]
default_shell = "/bin/bash"

[server]
# Tamanho virtual usado quando nenhum cliente está conectado.
headless_cols = 120
headless_rows = 40

[ui.sound]
# Container não tem placa de som; evita warnings e delays.
enabled = false

[ui.toast]
# Toast é in-app e funciona, mas o delivery externo não faz sentido no container.
delivery = "herdr"
EOF

# ---------------------------------------------------------------------------
# Integração oficial Herdr <-> OpenCode (estado do agente + restauração de sessão)
# https://herdr.dev/docs/integrations/
# ---------------------------------------------------------------------------
RUN herdr integration install opencode || echo "AVISO: integração do opencode não instalada"

# ---------------------------------------------------------------------------
# Workspace
# ---------------------------------------------------------------------------
WORKDIR /workspace

COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

# Sinais: o herdr abre subprocessos; `init: true` no compose já cuida do reaping,
# mas o exec no entrypoint garante que o processo principal receba o SIGTERM.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
