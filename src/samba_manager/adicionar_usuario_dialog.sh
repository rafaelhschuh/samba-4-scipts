#!/bin/bash

# Script para adicionar novos funcionários ao servidor Samba com Interface Dialog e Suporte a Idiomas
# Autor: Rafael Schuh (github.com/rafaelhschuh)
# Data: Abril 2025
# Descrição: Este script adiciona um novo usuário ao sistema e ao Samba,
#            sem criar diretório home, e o adiciona ao grupo que tem acesso
#            às pastas do servidor Samba. Suporta PT-BR/EN-US.

# Diretório dos scripts e locale
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOCALE_DIR="$SCRIPT_DIR/locale"

# Carregar idioma (passado como variável de ambiente ou padrão para en_US)
LANGUAGE=${LANGUAGE:-en_US}
if [ -f "$LOCALE_DIR/${LANGUAGE}.sh" ]; then
    source "$LOCALE_DIR/${LANGUAGE}.sh"
else
    # Fallback para inglês se o arquivo de idioma não for encontrado
    echo "Warning: Language file $LOCALE_DIR/${LANGUAGE}.sh not found. Falling back to English."
    source "$LOCALE_DIR/en_US.sh"
fi

# Arquivo temporário para capturar saída do dialog
OUTPUT="/tmp/samba_adduser_output.$$"

# Função para exibir mensagens de erro e sair
erro() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$1" 8 50
    rm -f $OUTPUT
    exit 1
}

# Função para exibir mensagens de aviso
aviso() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_WARNING" --msgbox "$1" 8 50
}

# Função para exibir mensagens de sucesso
sucesso_msg() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_SUCCESS" --msgbox "$1" 8 50
}

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
    erro "Este script deve ser executado como root. Use \'sudo $0\'\n\nThis script must be run as root. Use \'sudo $0\'"
fi

# Verificar se dialog está instalado (já deve estar pelo script principal, mas por segurança)
if ! command -v dialog &> /dev/null; then
    echo "Comando \'dialog\' não encontrado. Instale-o manualmente.\n\nCommand \'dialog\' not found. Please install it manually."
    exit 1
fi

# Exibir tela de boas-vindas
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_TITLE" --msgbox "$ADD_USER_DESC" 8 70

# Solicitar nome do grupo Samba
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_GROUP" --inputbox "$ADD_USER_GROUP_PROMPT" 8 60 "sambausers" 2> $OUTPUT
exit_status=$?
SAMBA_GROUP=$(cat $OUTPUT)
rm -f $OUTPUT

if [ $exit_status -ne 0 ]; then
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
    exit 0
fi

# Usar sambausers como padrão se nenhum grupo for especificado
if [ -z "$SAMBA_GROUP" ]; then
    SAMBA_GROUP="sambausers"
fi

# Verificar se o grupo existe
if ! getent group "$SAMBA_GROUP" > /dev/null; then
    GROUP_CREATE_PROMPT=$(printf "$ADD_USER_GROUP_CREATE" "$SAMBA_GROUP")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_GROUP_NOT_FOUND" --yesno "$GROUP_CREATE_PROMPT" 6 60
    if [ $? -eq 0 ]; then
        groupadd "$SAMBA_GROUP" || erro "Falha ao criar o grupo $SAMBA_GROUP / Failed to create group $SAMBA_GROUP"
        GROUP_SUCCESS_MSG=$(printf "$ADD_USER_GROUP_SUCCESS" "$SAMBA_GROUP")
        sucesso_msg "$GROUP_SUCCESS_MSG"
    else
        GROUP_REQUIRED_MSG=$(printf "$ADD_USER_GROUP_REQUIRED" "$SAMBA_GROUP")
        erro "$GROUP_REQUIRED_MSG"
    fi
fi

# Solicitar nome de usuário
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_NAME" --inputbox "$ADD_USER_NAME_PROMPT" 8 50 2> $OUTPUT
exit_status=$?
USERNAME=$(cat $OUTPUT)
rm -f $OUTPUT

if [ $exit_status -ne 0 ]; then
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
    exit 0
fi

if [ -z "$USERNAME" ]; then
    erro "$ADD_USER_EMPTY_NAME"
fi

# Verificar se o usuário já existe
if id "$USERNAME" &>/dev/null; then
    USER_EXISTS_PROMPT=$(printf "$ADD_USER_EXISTS_PROMPT" "$USERNAME")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_EXISTS" --yesno "$USER_EXISTS_PROMPT" 8 60
    if [ $? -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
        exit 0
    fi
else
    # Criar o usuário sem diretório home
    USER_CREATING_INFO=$(printf "$ADD_USER_CREATING_INFO" "$USERNAME")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_CREATING" --infobox "$USER_CREATING_INFO" 5 50
    useradd -M -s /bin/false "$USERNAME" || erro "Falha ao criar o usuário $USERNAME / Failed to create user $USERNAME"
    USER_SUCCESS_MSG=$(printf "$ADD_USER_SUCCESS" "$USERNAME")
    sucesso_msg "$USER_SUCCESS_MSG"
fi

# Adicionar usuário ao grupo Samba
ADDING_GROUP_INFO=$(printf "$ADD_USER_ADDING_GROUP_INFO" "$USERNAME" "$SAMBA_GROUP")
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_ADDING_GROUP" --infobox "$ADDING_GROUP_INFO" 5 60
usermod -aG "$SAMBA_GROUP" "$USERNAME" || erro "Falha ao adicionar usuário ao grupo $SAMBA_GROUP / Failed to add user to group $SAMBA_GROUP"
ADDING_GROUP_SUCCESS_MSG=$(printf "$ADD_USER_ADDING_GROUP_SUCCESS" "$USERNAME" "$SAMBA_GROUP")
sucesso_msg "$ADDING_GROUP_SUCCESS_MSG"

# Definir senha para o usuário no sistema
SYS_PASS_INFO=$(printf "$ADD_USER_SYS_PASS_INFO" "$USERNAME")
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SYS_PASS" --msgbox "$SYS_PASS_INFO" 6 60

while true; do
    SYS_PASS_PROMPT=$(printf "$ADD_USER_SYS_PASS_PROMPT" "$USERNAME")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SYS_PASS" --passwordbox "$SYS_PASS_PROMPT" 8 60 2> $OUTPUT
    exit_status=$?
    PASS1=$(cat $OUTPUT)
    rm -f $OUTPUT
    
    if [ $exit_status -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
        exit 0
    fi
    
    SYS_PASS_CONFIRM=$(printf "$ADD_USER_SYS_PASS_CONFIRM" "$USERNAME")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SYS_PASS" --passwordbox "$SYS_PASS_CONFIRM" 8 60 2> $OUTPUT
    exit_status=$?
    PASS2=$(cat $OUTPUT)
    rm -f $OUTPUT
    
    if [ $exit_status -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
        exit 0
    fi
    
    if [ "$PASS1" == "$PASS2" ] && [ -n "$PASS1" ]; then
        break
    else
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$ADD_USER_PASS_MISMATCH" 5 60
    fi
done

# Definir senha do sistema
echo -e "$PASS1\n$PASS1" | passwd "$USERNAME" > /dev/null 2>&1 || erro "Falha ao definir senha para o usuário $USERNAME no sistema / Failed to set system password for user $USERNAME"
SYS_PASS_SUCCESS_MSG=$(printf "$ADD_USER_SYS_PASS_SUCCESS" "$USERNAME")
sucesso_msg "$SYS_PASS_SUCCESS_MSG"

# Verificar se o Samba está instalado
if ! command -v smbpasswd &> /dev/null; then
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SAMBA_NOT_FOUND" --yesno "$ADD_USER_SAMBA_NOT_FOUND_PROMPT" 8 60
    if [ $? -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
        exit 0
    fi
else
    # Definir senha para o usuário no Samba
    SAMBA_PASS_INFO=$(printf "$ADD_USER_SAMBA_PASS_INFO" "$USERNAME")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SAMBA_PASS" --msgbox "$SAMBA_PASS_INFO" 6 70
    
    while true; do
        SAMBA_PASS_PROMPT=$(printf "$ADD_USER_SAMBA_PASS_PROMPT" "$USERNAME")
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SAMBA_PASS" --passwordbox "$SAMBA_PASS_PROMPT" 8 60 2> $OUTPUT
        exit_status=$?
        SAMBA_PASS1=$(cat $OUTPUT)
        rm -f $OUTPUT
        
        if [ $exit_status -ne 0 ]; then
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
            exit 0
        fi
        
        SAMBA_PASS_CONFIRM=$(printf "$ADD_USER_SAMBA_PASS_CONFIRM" "$USERNAME")
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_SAMBA_PASS" --passwordbox "$SAMBA_PASS_CONFIRM" 8 60 2> $OUTPUT
        exit_status=$?
        SAMBA_PASS2=$(cat $OUTPUT)
        rm -f $OUTPUT
        
        if [ $exit_status -ne 0 ]; then
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
            exit 0
        fi
        
        if [ "$SAMBA_PASS1" == "$SAMBA_PASS2" ] && [ -n "$SAMBA_PASS1" ]; then
            break
        else
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$ADD_USER_PASS_MISMATCH" 5 60
        fi
    done
    
    # Definir senha do Samba
    echo -e "$SAMBA_PASS1\n$SAMBA_PASS1" | smbpasswd -a "$USERNAME" > /dev/null 2>&1 || erro "Falha ao definir senha para o usuário $USERNAME no Samba / Failed to set Samba password for user $USERNAME"
    SAMBA_PASS_SUCCESS_MSG=$(printf "$ADD_USER_SAMBA_PASS_SUCCESS" "$USERNAME")
    sucesso_msg "$SAMBA_PASS_SUCCESS_MSG"
fi

# Exibir informações do usuário
USER_INFO_RAW=$(id "$USERNAME" 2>&1)
USER_INFO_SUCCESS_MSG=$(printf "$ADD_USER_INFO_SUCCESS" "$USERNAME" "$SAMBA_GROUP" "$USER_INFO_RAW")
dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$ADD_USER_INFO" --msgbox "$USER_INFO_SUCCESS_MSG" 15 70

# Limpar arquivo temporário na saída normal
rm -f $OUTPUT
exit 0
