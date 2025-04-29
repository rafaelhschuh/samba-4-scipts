#!/bin/bash

# Script Instalador/Atualizador para o Samba Manager
# Autor: Rafael Schuh (github.com/rafaelhschuh)
# Data: Abril 2025
# Descrição: Este script baixa o pacote samba-scripts.zip,
#            extrai para ~/.samba-scripts e cria um lançador
#            em /usr/local/bin/samba-script.

# --- Configuração --- #
DOWNLOAD_URL="https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/refs/heads/main/samba_manager.zip"
# Diretório de instalação (oculto na home do usuário)
INSTALL_DIR="$HOME/.samba-scripts"
# Nome do arquivo zip
ZIP_FILE="samba-scripts.zip"
# Nome do script lançador
LAUNCHER_NAME="samba-script"
# Caminho completo do lançador
LAUNCHER_PATH="/usr/local/bin/$LAUNCHER_NAME"
# --- Fim da Configuração --- #

# Cores para mensagens
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem Cor

# Função para exibir mensagens de erro e sair
erro() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

# Função para exibir mensagens de aviso
aviso() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

# Função para exibir mensagens de sucesso
sucesso() {
    echo -e "${GREEN}[SUCESSO] $1${NC}"
}

# Função para exibir mensagens de informação
info() {
    echo -e "[INFO] $1"
}

# Verificar se o script está sendo executado como root
if [ "$(id -u)" != "0" ]; then
    erro "Este script precisa ser executado como root para instalar o lançador em $LAUNCHER_PATH. Use 'sudo $0'"
fi

# Verificar dependências (wget/curl e unzip)
info "Verificando dependências..."
if command -v wget > /dev/null; then
    DOWNLOAD_CMD="wget -q -O"
elif command -v curl > /dev/null; then
    DOWNLOAD_CMD="curl -s -L -o"
else
    info "'wget' ou 'curl' não encontrado. Tentando instalar 'wget'..."
    apt-get update > /dev/null 2>&1 && apt-get install -y wget > /dev/null 2>&1 || erro "Falha ao instalar 'wget'. Instale 'wget' ou 'curl' manualmente."
    DOWNLOAD_CMD="wget -q -O"
fi

if ! command -v unzip > /dev/null; then
    info "'unzip' não encontrado. Tentando instalar 'unzip'..."
    apt-get update > /dev/null 2>&1 && apt-get install -y unzip > /dev/null 2>&1 || erro "Falha ao instalar 'unzip'. Instale 'unzip' manualmente."
fi
sucesso "Dependências verificadas."

# Criar diretório de instalação se não existir
info "Criando diretório de instalação em $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR" || erro "Falha ao criar o diretório $INSTALL_DIR"

# Baixar o arquivo zip
info "Baixando $ZIP_FILE de $DOWNLOAD_URL..."
$DOWNLOAD_CMD "$INSTALL_DIR/$ZIP_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    erro "Falha ao baixar o arquivo de $DOWNLOAD_URL. Verifique o URL e sua conexão."
fi
sucesso "Download concluído."

# Extrair o arquivo zip
info "Extraindo $ZIP_FILE para $INSTALL_DIR..."
# -o: sobrescrever arquivos existentes sem perguntar
unzip -o "$INSTALL_DIR/$ZIP_FILE" -d "$INSTALL_DIR/" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    erro "Falha ao extrair o arquivo $INSTALL_DIR/$ZIP_FILE."
fi

# Verificar se o script principal existe após extração (ajuste o caminho se necessário)
MAIN_SCRIPT_PATH="$INSTALL_DIR/samba_scripts/samba_manager.sh"
if [ ! -f "$MAIN_SCRIPT_PATH" ]; then
    # Tentar encontrar em um subdiretório comum se a estrutura do zip variar
    if [ -d "$INSTALL_DIR/samba_manager_scripts" ] && [ -f "$INSTALL_DIR/samba_manager_scripts/samba_manager.sh" ]; then
        MAIN_SCRIPT_PATH="$INSTALL_DIR/samba_manager_scripts/samba_manager.sh"
    elif [ -d "$INSTALL_DIR/samba_manager_multilingual" ] && [ -f "$INSTALL_DIR/samba_manager_multilingual/samba_scripts/samba_manager.sh" ]; then
         MAIN_SCRIPT_PATH="$INSTALL_DIR/samba_manager_multilingual/samba_scripts/samba_manager.sh"
    elif [ -d "$INSTALL_DIR/samba_manager_fix_deps" ] && [ -f "$INSTALL_DIR/samba_manager_fix_deps/samba_scripts/samba_manager.sh" ]; then
         MAIN_SCRIPT_PATH="$INSTALL_DIR/samba_manager_fix_deps/samba_scripts/samba_manager.sh"
    else
       aviso "Não foi possível encontrar o script principal 'samba_manager.sh' dentro do diretório esperado após a extração. O lançador pode não funcionar."
       # Definir um caminho padrão mesmo assim, pode ser ajustado manualmente
       MAIN_SCRIPT_PATH="$INSTALL_DIR/samba_scripts/samba_manager.sh"
    fi
fi

info "Script principal encontrado em: $MAIN_SCRIPT_PATH"

# Tornar scripts baixados executáveis
info "Tornando scripts em $INSTALL_DIR executáveis..."
find "$INSTALL_DIR" -name '*.sh' -exec chmod +x {} \;

# Criar o script lançador em /usr/local/bin
info "Criando lançador em $LAUNCHER_PATH..."
cat > "$LAUNCHER_PATH" << EOF
#!/bin/bash
# Lançador para o Samba Manager
# Gerado por install_samba_manager.sh
# Autor: Rafael Schuh (github.com/rafaelhschuh)

# Executa o script principal com sudo
sudo "$MAIN_SCRIPT_PATH" "\$@"
EOF

# Dar permissão de execução ao lançador
chmod +x "$LAUNCHER_PATH" || erro "Falha ao definir permissões de execução para $LAUNCHER_PATH"

# Limpar o arquivo zip baixado (opcional)
info "Limpando arquivo zip baixado..."
rm -f "$INSTALL_DIR/$ZIP_FILE"

sucesso "Instalação/Atualização do Samba Manager concluída!"
info "Execute o gerenciador com o comando: sudo $LAUNCHER_NAME"

exit 0
