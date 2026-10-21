#!/usr/bin/env bash
# Entrypoint do container. Apenas exibe um banner e repassa o comando ao shell.
set -euo pipefail

if [[ "${HERDR_BANNER:-1}" == "1" && -t 1 ]]; then
  cat <<'BANNER'

  ┌───────────────────────────────────────────────────────────────┐
  │  OpenCode + Herdr — sandbox de segurança ofensiva (Kali)     │
  ├───────────────────────────────────────────────────────────────┤
  │  opencode ................ abre o agente de IA no terminal    │
  │  herdr ................... abre o painel de workspaces/panes  │
  │  nmap, sqlmap, ffuf ...... ferramentas do Kali               │
  │  herdr server stop ....... encerra a sessão e os agentes      │
  └───────────────────────────────────────────────────────────────┘

BANNER
fi

exec "$@"
