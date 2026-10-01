#!/usr/bin/env bash
# Починить_Citrix_Mac.command
# Двойной клик в macOS Finder запускает этот скрипт в окне Терминала.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$DIR/mac.sh" ]; then
    bash "$DIR/mac.sh"
else
    # Если запущен отдельно без mac.sh
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Maximka-L/citrix-vdi/main/mac.sh)"
fi

echo ""
echo "Нажмите Enter для закрытия этого окна..."
read -r
