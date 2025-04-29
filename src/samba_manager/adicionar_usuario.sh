#!/bin/bash

# Script para adicionar novos funcionários ao servidor Samba
# Autor: Manus
# Data: Abril 2025
# Descrição: Este script adiciona um novo usuário ao sistema e ao Samba,
#            sem criar diretório home, e o adiciona ao grupo que tem acesso
#            às pastas do servidor Samba.

# Cores para melhor visualização
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[0;33m'
AZUL='\033[0;34m'
NC='\033[0m' # Sem cor

# Função para exibir mensagens de log
log() {
    echo -e "${AZUL}[INFO]${NC} $1"
}

# Função para exibir mensagens de sucesso
sucesso() {
    echo -e "${VERDE}[SUCESSO]${NC} $1"
}

# Função para exibir mensagens de erro
erro() {
    echo -e "${VERMELHO}[ERRO]${NC} $1"
    exit 1
}

# Função para exibir mensagens de aviso
aviso() {
    echo -e "${AMARELO}[AVISO]${NC} $1"
}

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
    erro "Este script deve ser executado como root. Use 'sudo $0'"
fi

# Nome do grupo que tem acesso às pastas do Samba
# Este valor pode ser alterado conforme a configuração do seu servidor
SAMBA_GROUP="sambausers"

# Verificar se o grupo existe
if ! getent group "$SAMBA_GROUP" > /dev/null; then
    log "O grupo $SAMBA_GROUP não existe. Criando grupo..."
    groupadd "$SAMBA_GROUP" || erro "Falha ao criar o grupo $SAMBA_GROUP"
    sucesso "Grupo $SAMBA_GROUP criado com sucesso"
fi

# Solicitar nome de usuário
read -p "Digite o nome de usuário para o novo funcionário: " USERNAME

# Verificar se o usuário já existe
if id "$USERNAME" &>/dev/null; then
    aviso "O usuário $USERNAME já existe no sistema"
    read -p "Deseja continuar e apenas adicionar ao grupo Samba? (s/n): " CONTINUE
    if [[ "$CONTINUE" != "s" && "$CONTINUE" != "S" ]]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
else
    # Criar o usuário sem diretório home
    log "Criando usuário $USERNAME sem diretório home..."
    useradd -M -s /bin/false "$USERNAME" || erro "Falha ao criar o usuário $USERNAME"
    sucesso "Usuário $USERNAME criado com sucesso"
fi

# Adicionar usuário ao grupo Samba
log "Adicionando usuário $USERNAME ao grupo $SAMBA_GROUP..."
usermod -aG "$SAMBA_GROUP" "$USERNAME" || erro "Falha ao adicionar usuário ao grupo $SAMBA_GROUP"
sucesso "Usuário $USERNAME adicionado ao grupo $SAMBA_GROUP com sucesso"

# Definir senha para o usuário no sistema
log "Definindo senha para o usuário $USERNAME no sistema..."
echo "Por favor, defina a senha para o usuário $USERNAME no sistema:"
passwd "$USERNAME" || erro "Falha ao definir senha para o usuário $USERNAME no sistema"

# Verificar se o Samba está instalado
if ! command -v smbpasswd &> /dev/null; then
    aviso "O comando smbpasswd não foi encontrado. O Samba pode não estar instalado."
    read -p "Deseja continuar mesmo assim? (s/n): " CONTINUE
    if [[ "$CONTINUE" != "s" && "$CONTINUE" != "S" ]]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
else
    # Definir senha para o usuário no Samba
    log "Definindo senha para o usuário $USERNAME no Samba..."
    echo "Por favor, defina a senha para o usuário $USERNAME no Samba (pode ser a mesma do sistema):"
    smbpasswd -a "$USERNAME" || erro "Falha ao definir senha para o usuário $USERNAME no Samba"
    sucesso "Senha definida com sucesso para o usuário $USERNAME no Samba"
fi

# Exibir informações do usuário
log "Informações do usuário $USERNAME:"
id "$USERNAME"

sucesso "Usuário $USERNAME configurado com sucesso!"
log "O usuário agora tem acesso às pastas do servidor Samba configuradas para o grupo $SAMBA_GROUP"
