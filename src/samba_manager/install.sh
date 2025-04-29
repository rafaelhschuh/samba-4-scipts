#!/bin/bash

# Script de instalação do Gerenciador Samba 4
# Autor: Rafael Schuh (github.com/rafaelhschuh)
# Data: Abril 2025
# Descrição: Script para instalar o Gerenciador Samba 4 no sistema

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
    echo "Este script deve ser executado como root. Use 'sudo $0'"
    exit 1
fi

# Diretório de instalação
INSTALL_DIR="/usr/local/samba-manager"

# Criar diretório de instalação
mkdir -p $INSTALL_DIR

# Copiar scripts para o diretório de instalação
cp -f "$(dirname "$0")/instalar_samba_dialog.sh" $INSTALL_DIR/
cp -f "$(dirname "$0")/adicionar_usuario_dialog.sh" $INSTALL_DIR/
cp -f "$(dirname "$0")/samba_manager.sh" $INSTALL_DIR/

# Tornar scripts executáveis
chmod +x $INSTALL_DIR/*.sh

# Criar link simbólico para o script principal
ln -sf $INSTALL_DIR/samba_manager.sh /usr/local/bin/samba-manager

echo "Gerenciador Samba 4 instalado com sucesso!"
echo "Execute 'samba-manager' para iniciar o programa."
