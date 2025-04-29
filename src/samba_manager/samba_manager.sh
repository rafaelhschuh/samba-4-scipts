#!/bin/bash

# Script principal para gerenciamento do Samba com suporte a múltiplos idiomas
# Autor: Rafael Schuh (github.com/rafaelhschuh)
# Data: Abril 2025
# Descrição: Interface principal para gerenciar o servidor Samba com suporte a PT-BR e EN-US

# Diretório dos scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOCALE_DIR="$SCRIPT_DIR/locale"

# Arquivo temporário para capturar saída do dialog
OUTPUT="/tmp/samba_manager_output.$$"

# Função para limpar e sair
limpar_e_sair() {
    rm -f $OUTPUT
    clear
    exit 0
}

# Verificar se dialog está instalado, se não, instalar
if ! command -v dialog &> /dev/null; then
    echo "Instalando dialog... / Installing dialog..."
    apt-get update > /dev/null 2>&1 && apt-get install -y dialog > /dev/null 2>&1
    if ! command -v dialog &> /dev/null; then
        echo "Falha ao instalar 'dialog'. Por favor, instale manualmente e execute o script novamente."
        echo "Failed to install 'dialog'. Please install it manually and run the script again."
        exit 1
    fi
fi

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
    dialog --title "Erro / Error" --msgbox "Este script deve ser executado como root. Use 'sudo $0'\n\nThis script must be run as root. Use 'sudo $0'" 8 60
    limpar_e_sair
fi

# Função para selecionar o idioma
selecionar_idioma() {
    # Exibir informações de autoria na tela de seleção de idioma
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" \
           --title "Samba Manager - Seleção de Idioma / Language Selection" \
           --menu "Selecione o idioma / Select language:" 12 60 2 \
           "pt_BR" "Português (Brasil)" \
           "en_US" "English (US)" 2> $OUTPUT
    
    exit_status=$?
    LANGUAGE=$(cat $OUTPUT)
    rm -f $OUTPUT
    
    if [ $exit_status -ne 0 ]; then
        limpar_e_sair
    fi
    
    # Carregar arquivo de idioma selecionado
    if [ -f "$LOCALE_DIR/${LANGUAGE}.sh" ]; then
        source "$LOCALE_DIR/${LANGUAGE}.sh"
    else
        dialog --title "Error / Erro" --msgbox "Language file not found / Arquivo de idioma não encontrado: $LANGUAGE" 6 60
        limpar_e_sair
    fi
}

# Função para exibir o menu principal
menu_principal() {
    while true; do
        dialog --clear --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" \
               --title "$MENU_TITLE" \
               --menu "$MENU_CHOOSE" 15 60 4 \
               1 "$MENU_INSTALL" \
               2 "$MENU_ADD_USER" \
               3 "$MSG_ABOUT" \
               4 "$MSG_EXIT" 2> $OUTPUT
        
        exit_status=$?
        choice=$(cat $OUTPUT)
        rm -f $OUTPUT
        
        if [ $exit_status -ne 0 ]; then
            limpar_e_sair
        fi
        
        case $choice in
            1)
                # Executar script de instalação com o idioma selecionado
                LANGUAGE=$LANGUAGE $SCRIPT_DIR/instalar_samba_dialog.sh
                ;;
            2)
                # Executar script de adição de usuário com o idioma selecionado
                LANGUAGE=$LANGUAGE $SCRIPT_DIR/adicionar_usuario_dialog.sh
                ;;
            3)
                # Exibir informações sobre o script
                dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" \
                       --title "$MSG_ABOUT" \
                       --msgbox "$ABOUT_TEXT" 12 60
                ;;
            4)
                # Sair do script
                limpar_e_sair
                ;;
        esac
    done
}

# Selecionar idioma
selecionar_idioma

# Exibir tela de boas-vindas com informações de autoria
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" \
       --title "$MSG_WELCOME" \
       --msgbox "$MSG_WELCOME_DESC\n\n$MSG_CONTINUE" 12 60

# Iniciar o menu principal
menu_principal

# Limpar e sair (caso o menu principal retorne)
limpar_e_sair
