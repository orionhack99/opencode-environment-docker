# Usar a imagem oficial mais recente do Debian
FROM kalilinux/kali-rolling:latest

# Evitar travar a instalação esperando respostas no terminal
ENV DEBIAN_FRONTEND=noninteractive

# pipefail: o build QUEBRA se um `curl | sh` falhar no meio do download.
# Sem isso, um download truncado produz uma imagem sem o binário e sem erro.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Instalar dependências básicas essenciais para os scripts rodarem
# tar   -> o instalador do OpenCode extrai .tgz e aborta se o tar faltar
# unzip -> várias tools de pentest distribuem-se em .zip
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    ca-certificates \
    procps \
    tmux \
    tar \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Criar o usuário comum
RUN useradd -m -s /bin/bash kaliuser

# PERMISSÃO DE ROOT (SUDO): Permite ao kaliuser rodar comandos como root sem pedir senha
RUN echo "kaliuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/kaliuser \
    && chmod 0440 /etc/sudoers.d/kaliuser

# Configurar o diretório de trabalho padrão com permissões corretas
WORKDIR /workspace
RUN chown kaliuser:kaliuser /workspace

# Alternar para o usuário comum para manter o ambiente isolado por padrão
USER kaliuser
ENV HOME=/home/kaliuser


# Versão fixa do OpenCode (vazio = "latest"). Fixe para builds reprodutíveis.
# O Compose passa este build arg; sem o ARG declarado o Docker avisa que o
# argumento não foi usado e a versão fixada é ignorada.
ARG OPENCODE_VERSION=""

# Instalar o Herdr usando o script oficial indicado
RUN curl -fsSL --retry 3 --connect-timeout 10 https://herdr.dev/install.sh | sh

# Instalar o OpenCode usando o script oficial indicado
RUN if [ -n "${OPENCODE_VERSION}" ]; then \
        curl -fsSL --retry 3 --connect-timeout 10 https://opencode.ai/v2/install | bash -s -- --version "${OPENCODE_VERSION}"; \
    else \
        curl -fsSL --retry 3 --connect-timeout 10 https://opencode.ai/v2/install | bash; \
    fi

# CLONAR O REPOSITÓRIO AUTOMATICAMENTE (Nova Funcionalidade)
# IMPORTANTE: o clone fica em /opt/opencode-pentester e NÃO em /workspace.
# O Compose monta a pasta do host por cima de /workspace (bind mount) e
# cobriria o clone, deixando o framework invisível em tempo de execução.
# O clone roda como root (não depende do sudo) e a posse volta ao kaliuser
# para o agente poder gravar findings, DB e outputs.
USER root
RUN git clone https://github.com/humaidhahm/opencode-pentester.git /opt/opencode-pentester \
    && chown -R kaliuser:kaliuser /opt/opencode-pentester
USER kaliuser

# Caminho canônico do framework dentro do container
ENV OPENCODE_PENTESTER_DIR=/opt/opencode-pentester

# 7. EXPORTAR O PATH: Corrigido apontando apenas para as pastas do kaliuser
ENV PATH="${HOME}/.local/bin:${HOME}/.opencode/bin:${PATH}"

# 8. Correção do Erro: Grava no .bashrc do KALIUSER (e não do root)
RUN echo 'export PATH="${HOME}/.local/bin:${HOME}/.opencode/bin:$PATH"' >> ${HOME}/.bashrc





# Iniciar com um terminal interativo
CMD ["/bin/bash"]
