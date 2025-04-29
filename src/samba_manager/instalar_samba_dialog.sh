#!/bin/bash

# Script de Instalação Completa do Samba 4 no Debian com Interface Dialog e Suporte a Idiomas
# Autor: Rafael Schuh (github.com/rafaelhschuh)
# Data: Abril 2025
# Descrição: Este script realiza a instalação e configuração completa do Samba 4 no Debian,
#            utilizando a interface dialog para interação com o usuário e suporte a PT-BR/EN-US.
#            Permite configurar como controlador de domínio Active Directory, servidor de arquivos,
#            ou membro de domínio.

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
OUTPUT="/tmp/samba_install_output.$$"

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

# Função para verificar se o script está sendo executado como root
verificar_root() {
    if [ "$(id -u)" != "0" ]; then
        erro "Este script deve ser executado como root. Use \'sudo $0\'\n\nThis script must be run as root. Use \'sudo $0\'"
    fi
}

# Função para verificar a versão do Debian
verificar_debian() {
    if [ ! -f /etc/debian_version ]; then
        erro "Este script foi projetado para ser executado no Debian. Sistema operacional não suportado.\n\nThis script is designed to run on Debian. Unsupported operating system."
    fi
    
    DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
    echo "[INFO] Versão do Debian detectada / Debian version detected: $DEBIAN_VERSION"
    
    if [ "$DEBIAN_VERSION" -lt 10 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_WARNING" --yesno "Este script foi testado no Debian 10 (Buster) ou superior. Versões mais antigas podem não funcionar corretamente. Deseja continuar?\n\nThis script was tested on Debian 10 (Buster) or later. Older versions may not work correctly. Do you want to continue?" 8 70
        if [ $? -ne 0 ]; then
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
            rm -f $OUTPUT
            exit 0
        fi
    fi
}

# Função para atualizar o sistema com dialog
atualizar_sistema() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_TITLE" --infobox "$INSTALL_UPDATING_REPOS" 5 50
    apt-get update > /dev/null 2>&1 || erro "Falha ao atualizar listas de pacotes / Failed to update package lists"
    
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_TITLE" --infobox "$INSTALL_UPDATING_PACKAGES" 5 70
    apt-get upgrade -y > /dev/null 2>&1 || erro "Falha ao atualizar pacotes / Failed to upgrade packages"
    echo "[INFO] Sistema atualizado com sucesso / System updated successfully"
}

# Função para instalar dependências básicas com dialog
instalar_dependencias() {
    DEPENDENCIAS=("dialog" "acl" "attr" "wget" "curl" "net-tools" "dnsutils" \
                  "python3-setproctitle" "python3-dnspython" "python3-markdown" \
                  "python3-crypto" "gdb" "pkg-config" "libjansson-dev")
    
    LOG_FILE="/tmp/dependency_install.log"
    rm -f $LOG_FILE
    touch $LOG_FILE
    
    # Verificar se o DEBIAN_FRONTEND está definido para noninteractive
    export DEBIAN_FRONTEND=noninteractive
    
    # Atualizar lista de pacotes primeiro
    apt-get update > /dev/null 2>&1
    
    ( 
      echo "$INSTALL_DEPENDENCIES_INFO"
      COUNT=0
      TOTAL=${#DEPENDENCIAS[@]}
      for dep in "${DEPENDENCIAS[@]}"; do
          PERCENT=$(( ($COUNT * 100) / $TOTAL ))
          echo $PERCENT
          echo "XXX"
          echo "Verificando/Instalando $dep... ($(($COUNT + 1))/$TOTAL)"
          echo "XXX"
          
          # Verificar se o pacote já está instalado
          if dpkg -l | grep -q "^ii  $dep "; then
              echo "INFO: $dep já está instalado, pulando." >> $LOG_FILE
          else
              # Instalar o pacote apenas se não estiver instalado
              apt-get install -y --no-install-recommends "$dep" >> $LOG_FILE 2>&1
              if [ $? -ne 0 ]; then
                  echo "ERRO: Falha ao instalar $dep. Verifique o log." >> $LOG_FILE
                  echo "ERROR: Failed to install $dep. Check log." >> $LOG_FILE
              fi
          fi
          COUNT=$(($COUNT + 1))
      done
      echo 100
      echo "XXX"
      echo "Verificação/Instalação de dependências concluída."
      echo "Dependency verification/installation complete."
      echo "XXX"
      sleep 1 # Pequena pausa para o usuário ver 100%
    ) | dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_DEPENDENCIES" --gauge "$INSTALL_DEPENDENCIES_INFO" 10 70 0

    # Verificar se houve erros reais no log (ignorando mensagens sobre pacotes já instalados)
    if grep -q "ERRO:" $LOG_FILE || grep -q "ERROR:" $LOG_FILE; then
        # Mostrar o log, mas continuar mesmo com erros
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_WARNING" --textbox $LOG_FILE 20 70
        aviso "Alguns pacotes podem não ter sido instalados corretamente. O script tentará continuar.\n\nSome packages may not have been installed correctly. The script will try to continue."
    else
        sucesso_msg "$INSTALL_DEPENDENCIES_SUCCESS"
    fi
    
    # Restaurar o DEBIAN_FRONTEND
    unset DEBIAN_FRONTEND
    
    # rm -f $LOG_FILE # Opcional: manter o log para depuração
    echo "[INFO] Dependências básicas verificadas/instaladas / Basic dependencies checked/installed."
}

# Função para instalar o Samba 4 como pacote com dialog
instalar_samba_pacote() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_SAMBA" --infobox "$INSTALL_SAMBA_INFO" 5 60
    
    # Definir DEBIAN_FRONTEND para noninteractive para evitar prompts
    export DEBIAN_FRONTEND=noninteractive
    
    # Instalar pacotes Samba com opção --no-install-recommends
    apt-get install -y --no-install-recommends samba samba-common samba-dsdb-modules samba-vfs-modules \
    winbind libpam-winbind libnss-winbind krb5-config krb5-user > /tmp/samba_install.log 2>&1
    
    # Verificar se houve erros na instalação
    if [ $? -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_WARNING" --textbox /tmp/samba_install.log 20 70
        aviso "Alguns componentes do Samba podem não ter sido instalados corretamente. O script tentará continuar.\n\nSome Samba components may not have been installed correctly. The script will try to continue."
    fi
    
    # Restaurar o DEBIAN_FRONTEND
    unset DEBIAN_FRONTEND
    
    # Parar e desabilitar serviços para evitar conflitos
    echo "[INFO] Parando e desabilitando serviços Samba padrão / Stopping and disabling default Samba services..."
    systemctl stop smbd nmbd winbind > /dev/null 2>&1
    systemctl disable smbd nmbd winbind > /dev/null 2>&1
    
    echo "[INFO] $INSTALL_SAMBA_SUCCESS"
}

# Função para configurar o NTP com dialog
configurar_ntp() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_NTP" --infobox "$INSTALL_NTP_INFO" 5 50
    apt-get install -y ntp > /dev/null 2>&1 || erro "Falha ao instalar NTP / Failed to install NTP"
    
    # Configurar NTP para sincronizar com servidores brasileiros (ou outros se preferir)
    cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

# Pool de servidores NTP (use pool.ntp.org para global)
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Configurações de acesso
restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
restrict source notrap nomodify noquery
EOF
    
    # Reiniciar serviço NTP
    systemctl restart ntp
    systemctl enable ntp
    
    # Verificar status do NTP (apenas log)
    echo "[INFO] Verificando status do NTP / Checking NTP status:"
    ntpq -p
    
    echo "[INFO] $INSTALL_NTP_SUCCESS"
}

# Função para configurar o hostname e hosts com dialog
configurar_hostname() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$NETWORK_CONFIG" --msgbox "$NETWORK_CONFIG_INFO" 6 60

    while true; do
        HOSTNAME=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$NETWORK_HOSTNAME" 8 40)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        [ -n "$HOSTNAME" ] && break
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$NETWORK_EMPTY_HOSTNAME" 5 40
    done

    while true; do
        DOMAIN=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$NETWORK_DOMAIN" 8 40)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        [ -n "$DOMAIN" ] && break
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$NETWORK_EMPTY_DOMAIN" 5 40
    done

    while true; do
        IP_ADDRESS=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$NETWORK_IP" 8 40)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        # Validação básica de IP (pode ser melhorada)
        if [[ "$IP_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$NETWORK_INVALID_IP" 5 40
    done

    # Configurar hostname
    hostnamectl set-hostname $HOSTNAME
    
    # Configurar /etc/hosts
    cat > /etc/hosts << EOF
127.0.0.1       localhost
$IP_ADDRESS     $HOSTNAME.$DOMAIN $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
    
    sucesso_msg "$NETWORK_SUCCESS"
    
    # Exportar variáveis para uso posterior
    export HOSTNAME
    export DOMAIN
    export IP_ADDRESS
}

# Função para configurar o DNS (para AD DC)
configurar_dns_ad() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$DNS_CONFIG_DC" --infobox "$DNS_CONFIG_DC_INFO" 5 60
    
    # Desativar o resolvconf se estiver instalado
    if dpkg -l | grep -q resolvconf; then
        echo "[INFO] Desativando resolvconf / Disabling resolvconf..."
        systemctl disable --now resolvconf.service > /dev/null 2>&1
    fi
    
    # Desativar o systemd-resolved se estiver em uso
    if systemctl is-active --quiet systemd-resolved; then
        echo "[INFO] Desativando systemd-resolved / Disabling systemd-resolved..."
        systemctl disable --now systemd-resolved.service > /dev/null 2>&1
        rm -f /etc/resolv.conf
    fi
    
    # Configurar resolv.conf para apontar para si mesmo
    chattr -i /etc/resolv.conf 2>/dev/null # Remover imutabilidade se existir
    cat > /etc/resolv.conf << EOF
domain $DOMAIN
search $DOMAIN
nameserver 127.0.0.1
EOF
    
    # Tornar o arquivo imutável para evitar alterações automáticas
    chattr +i /etc/resolv.conf
    
    echo "[INFO] $DNS_SUCCESS_DC"
}

# Função para configurar o DNS (para Membro de Domínio)
configurar_dns_member() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$DNS_CONFIG_MEMBER" --infobox "$DNS_CONFIG_MEMBER_INFO" 5 60

    while true; do
        DC_IP=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$DNS_DC_IP" 8 50)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        if [[ "$DC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$DNS_INVALID_DC_IP" 5 40
    done

    # Desativar o resolvconf se estiver instalado
    if dpkg -l | grep -q resolvconf; then
        echo "[INFO] Desativando resolvconf / Disabling resolvconf..."
        systemctl disable --now resolvconf.service > /dev/null 2>&1
    fi
    
    # Desativar o systemd-resolved se estiver em uso
    if systemctl is-active --quiet systemd-resolved; then
        echo "[INFO] Desativando systemd-resolved / Disabling systemd-resolved..."
        systemctl disable --now systemd-resolved.service > /dev/null 2>&1
        rm -f /etc/resolv.conf
    fi

    # Configurar resolv.conf para apontar para o DC
    chattr -i /etc/resolv.conf 2>/dev/null # Remover imutabilidade se existir
    cat > /etc/resolv.conf << EOF
domain $JOIN_DOMAIN
search $JOIN_DOMAIN
nameserver $DC_IP
EOF
    
    # Tornar o arquivo imutável para evitar alterações automáticas
    chattr +i /etc/resolv.conf
    
    echo "[INFO] $DNS_SUCCESS_MEMBER"
    export DC_IP
}


# Função para provisionar o domínio AD com dialog
provisionar_ad() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$AD_PROVISIONING" --infobox "$AD_PROVISIONING_INFO" 5 70
    
    # Parar serviços Samba se estiverem em execução
    systemctl stop smbd nmbd winbind > /dev/null 2>&1
    
    # Remover arquivos de configuração existentes
    rm -f /etc/samba/smb.conf
    
    # Solicitar senha do administrador
    while true; do
        ADMIN_PASS=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --passwordbox "$AD_ADMIN_PASS" 8 60)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        ADMIN_PASS_CONFIRM=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --passwordbox "$AD_ADMIN_PASS_CONFIRM" 8 60)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        
        if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$AD_PASS_MISMATCH" 5 50
        elif [ ${#ADMIN_PASS} -lt 8 ]; then
            dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$AD_PASS_TOO_SHORT" 5 60
        else
            break
        fi
    done
    
    # Converter domínio para maiúsculas para o realm
    REALM=$(echo $DOMAIN | tr '[:lower:]' '[:upper:]')
    
    # Extrair o nome NetBIOS do domínio (primeira parte do domínio)
    NETBIOS=$(echo $DOMAIN | cut -d. -f1 | tr '[:lower:]' '[:upper:]')
    
    # Provisionar o domínio
    PROVISION_MSG=$(printf "$AD_PROVISIONING_DOMAIN" "$DOMAIN" "$REALM" "$NETBIOS")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$AD_PROVISIONING" --infobox "$PROVISION_MSG" 8 70
    samba-tool domain provision --server-role=dc \
    --domain=$NETBIOS \
    --realm=$REALM \
    --adminpass="$ADMIN_PASS" \
    --dns-backend=SAMBA_INTERNAL \
    --use-rfc2307 > /tmp/samba_provision.log 2>&1 || erro "Falha ao provisionar o domínio. Verifique /tmp/samba_provision.log\n\nFailed to provision domain. Check /tmp/samba_provision.log"
    
    # Copiar arquivo de configuração Kerberos
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
    
    # Configurar serviço Samba AD DC
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$AD_SERVICE_CONFIG" --infobox "$AD_SERVICE_CONFIG_INFO" 5 60
    if [ -f /lib/systemd/system/samba-ad-dc.service ]; then
        systemctl unmask samba-ad-dc > /dev/null 2>&1
        systemctl enable samba-ad-dc > /dev/null 2>&1
        systemctl restart samba-ad-dc || erro "Falha ao iniciar o serviço samba-ad-dc / Failed to start samba-ad-dc service"
    else
        # Criar serviço manualmente se não existir (menos comum em Debian recente)
        cat > /etc/systemd/system/samba-ad-dc.service << EOF
[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/sbin/samba -D
PIDFile=/run/samba/samba.pid
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable samba-ad-dc > /dev/null 2>&1
        systemctl restart samba-ad-dc || erro "Falha ao iniciar o serviço samba-ad-dc / Failed to start samba-ad-dc service"
    fi
    
    # Criar zona reversa DNS
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$AD_DNS_REVERSE" --infobox "$AD_DNS_REVERSE_ZONE" 5 50
    IP_REVERSE=$(echo $IP_ADDRESS | awk -F. '{print $3"."$2"."$1}')
    samba-tool dns zonecreate $HOSTNAME.$DOMAIN $IP_REVERSE.in-addr.arpa -U Administrator%"$ADMIN_PASS" > /dev/null 2>&1 || aviso "Falha ao criar zona reversa DNS (pode ser criada manualmente depois)\n\nFailed to create reverse DNS zone (can be created manually later)"
    
    # Adicionar registro PTR
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$AD_DNS_REVERSE" --infobox "$AD_DNS_REVERSE_PTR" 5 50
    IP_LAST_OCTET=$(echo $IP_ADDRESS | awk -F. '{print $4}')
    samba-tool dns add $HOSTNAME.$DOMAIN $IP_REVERSE.in-addr.arpa $IP_LAST_OCTET PTR $HOSTNAME.$DOMAIN -U Administrator%"$ADMIN_PASS" > /dev/null 2>&1 || aviso "Falha ao adicionar registro PTR (pode ser adicionado manualmente depois)\n\nFailed to add PTR record (can be added manually later)"
    
    sucesso_msg "$AD_SUCCESS"
}

# Função para configurar o Samba como servidor de arquivos com dialog
configurar_servidor_arquivos() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$FILE_SERVER_CONFIG" --infobox "$FILE_SERVER_CONFIG_INFO" 5 70
    
    # Criar diretórios para compartilhamentos
    mkdir -p /srv/samba/publico
    mkdir -p /srv/samba/dados
    
    # Configurar permissões
    chmod 777 /srv/samba/publico
    chmod 770 /srv/samba/dados
    
    # Criar grupo para acesso aos dados
    if ! getent group sambausers > /dev/null; then
        groupadd -f sambausers || erro "Falha ao criar grupo sambausers / Failed to create group sambausers"
    fi
    chown root:sambausers /srv/samba/dados
    
    # Configurar smb.conf para servidor de arquivos
    cat > /etc/samba/smb.conf << EOF
[global]
   workgroup = WORKGROUP
   server string = Servidor de Arquivos Samba / Samba File Server
   netbios name = $HOSTNAME
   security = user
   map to guest = bad user
   dns proxy = no
   
   # Configurações de log / Log settings
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   
   # Configurações de segurança / Security settings
   server signing = auto
   client min protocol = SMB2
   server min protocol = SMB2
   
   # Configurações de desempenho / Performance settings
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   use sendfile = yes
   write cache size = 524288
   getwd cache = yes
   
   # Configurações de impressão (desabilitar se não usar) / Print settings (disable if not used)
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes
   
[homes]
   comment = Diretórios Home / Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S
   
[dados]
   comment = Compartilhamento de Dados / Data Share
   path = /srv/samba/dados
   browseable = yes
   read only = no
   guest ok = no
   valid users = @sambausers
   create mask = 0770
   directory mask = 0770
   force group = sambausers
   
[publico]
   comment = Área Pública / Public Area
   path = /srv/samba/publico
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
EOF
    
    # Reiniciar serviços Samba
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$FILE_SERVER_RESTART" --infobox "$FILE_SERVER_RESTART_INFO" 5 50
    systemctl restart smbd nmbd
    systemctl enable smbd nmbd
    
    # Adicionar usuário de exemplo
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --yesno "$FILE_SERVER_USER" 8 60
    if [ $? -eq 0 ]; then
        if ! id sambauser > /dev/null 2>&1; then
            useradd -m -s /bin/bash sambauser || aviso "Falha ao criar usuário sambauser no sistema / Failed to create sambauser system user"
        fi
        while true; do
            USER_PASS=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --passwordbox "$FILE_SERVER_USER_PASS" 8 40)
            [ $? -ne 0 ] && break # Cancelar criação de usuário exemplo
            USER_PASS_CONFIRM=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --passwordbox "$FILE_SERVER_USER_PASS_CONFIRM" 8 40)
            [ $? -ne 0 ] && break # Cancelar criação de usuário exemplo
            if [ "$USER_PASS" == "$USER_PASS_CONFIRM" ] && [ -n "$USER_PASS" ]; then
                echo -e "$USER_PASS\n$USER_PASS" | passwd sambauser > /dev/null 2>&1 || aviso "Falha ao definir senha do sistema para sambauser / Failed to set system password for sambauser"
                echo -e "$USER_PASS\n$USER_PASS" | smbpasswd -a sambauser > /dev/null 2>&1 || aviso "Falha ao definir senha do Samba para sambauser / Failed to set Samba password for sambauser"
                usermod -aG sambausers sambauser || aviso "Falha ao adicionar sambauser ao grupo sambausers / Failed to add sambauser to sambausers group"
                sucesso_msg "$FILE_SERVER_USER_SUCCESS"
                break
            else
                dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$ADD_USER_PASS_MISMATCH" 5 60
            fi
        done
    fi
    
    sucesso_msg "$FILE_SERVER_SUCCESS"
}

# Função para configurar o Samba como membro de domínio com dialog
configurar_membro_dominio() {
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_CONFIG" --msgbox "$MEMBER_CONFIG_INFO" 6 70

    while true; do
        JOIN_DOMAIN=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$MEMBER_DOMAIN" 8 50)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        [ -n "$JOIN_DOMAIN" ] && break
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$MEMBER_EMPTY_DOMAIN" 5 40
    done
    export JOIN_DOMAIN

    while true; do
        JOIN_WORKGROUP=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$MEMBER_WORKGROUP" 8 40)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        [ -n "$JOIN_WORKGROUP" ] && break
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$MEMBER_EMPTY_WORKGROUP" 5 40
    done
    export JOIN_WORKGROUP

    # Configurar DNS para apontar para o DC
    configurar_dns_member

    # Configurar smb.conf para membro de domínio
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_SMB_CONFIG" --infobox "$MEMBER_SMB_CONFIG_INFO" 5 50
    REALM_JOIN=$(echo $JOIN_DOMAIN | tr '[:lower:]' '[:upper:]')
    cat > /etc/samba/smb.conf << EOF
[global]
   workgroup = $JOIN_WORKGROUP
   server string = Servidor Membro Samba / Samba Member Server
   netbios name = $HOSTNAME
   security = ADS
   realm = $REALM_JOIN
   
   # Configurações de autenticação / Authentication settings
   kerberos method = secrets and keytab
   winbind use default domain = yes
   winbind offline logon = yes
   winbind enum users = yes
   winbind enum groups = yes
   
   # Configurações de mapeamento de ID / ID mapping settings
   idmap config * : backend = tdb
   idmap config * : range = 3000-7999
   idmap config $JOIN_WORKGROUP : backend = rid
   idmap config $JOIN_WORKGROUP : range = 10000-999999
   
   # Configurações de shell e home / Shell and home settings
   template shell = /bin/bash
   template homedir = /home/%U
   
   # Configurações de log / Log settings
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   
   # Configurações de segurança / Security settings
   server signing = auto
   client signing = auto
   client min protocol = SMB2
   server min protocol = SMB2
   
   # Configurações de desempenho / Performance settings
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   use sendfile = yes
   
   # Configurações de impressão (desabilitar se não usar) / Print settings (disable if not used)
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes
   
[homes]
   comment = Diretórios Home / Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S
   
# Exemplo de compartilhamento acessível por usuários do domínio
# Example share accessible by domain users
#[dados_dominio]
#   comment = Dados do Domínio / Domain Data
#   path = /srv/samba/dados_dominio
#   browseable = yes
#   read only = no
#   valid users = @"$JOIN_WORKGROUP\\Domain Users"
#   create mask = 0770
#   directory mask = 0770
EOF
    
    # Configurar Kerberos
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_KERBEROS" --infobox "$MEMBER_KERBEROS_INFO" 5 50
    cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $REALM_JOIN
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    $REALM_JOIN = {
        kdc = $DC_IP
        admin_server = $DC_IP
    }

[domain_realm]
    .$JOIN_DOMAIN = $REALM_JOIN
    $JOIN_DOMAIN = $REALM_JOIN
EOF
    
    # Reiniciar serviços
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$FILE_SERVER_RESTART" --infobox "Reiniciando smbd, nmbd, winbind... / Restarting smbd, nmbd, winbind..." 5 50
    systemctl restart smbd nmbd winbind
    systemctl enable smbd nmbd winbind
    
    # Solicitar credenciais para ingressar no domínio
    while true; do
        ADMIN_USER_PROMPT=$(printf "$MEMBER_ADMIN_USER" "$JOIN_DOMAIN")
        ADMIN_USER=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --inputbox "$ADMIN_USER_PROMPT" 8 60)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        ADMIN_PASS=$(dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --stdout --passwordbox "$MEMBER_ADMIN_PASS" 8 60)
        [ $? -ne 0 ] && erro "$MSG_CANCELED"
        [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ] && break
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MSG_ERROR" --msgbox "$MEMBER_EMPTY_CREDENTIALS" 5 50
    done
    
    # Ingressar no domínio
    JOIN_INFO_MSG=$(printf "$MEMBER_JOIN_INFO" "$JOIN_DOMAIN")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_JOIN" --infobox "$JOIN_INFO_MSG" 5 60
    echo "$ADMIN_PASS" | net ads join -U "$ADMIN_USER" -k no > /tmp/samba_join.log 2>&1
    # Alternativa sem -k no (pode pedir senha de novo):
    # net ads join -U "$ADMIN_USER%$ADMIN_PASS" > /tmp/samba_join.log 2>&1
    if [ $? -ne 0 ]; then
        erro "Falha ao ingressar no domínio. Verifique as credenciais, DNS, NTP e /tmp/samba_join.log\n\nFailed to join domain. Check credentials, DNS, NTP, and /tmp/samba_join.log"
    fi
    
    # Configurar NSS
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_NSS" --infobox "$MEMBER_NSS_INFO" 5 50
    if ! grep -q "winbind" /etc/nsswitch.conf; then
        sed -i 's/^passwd:.*/passwd:         files systemd winbind/g' /etc/nsswitch.conf
        sed -i 's/^group:.*/group:          files systemd winbind/g' /etc/nsswitch.conf
    fi
    
    # Configurar PAM (exemplo básico, pode precisar de ajustes)
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_PAM" --infobox "$MEMBER_PAM_INFO" 5 60
    pam-auth-update --enable winbind --force || aviso "Falha ao executar pam-auth-update. Verifique a configuração PAM manualmente.\n\nFailed to run pam-auth-update. Check PAM configuration manually."
    
    # Reiniciar serviços novamente
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$FILE_SERVER_RESTART" --infobox "Reiniciando smbd, nmbd, winbind novamente... / Restarting smbd, nmbd, winbind again..." 5 60
    systemctl restart smbd nmbd winbind
    
    # Testar a configuração
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$MEMBER_TEST" --infobox "$MEMBER_TEST_INFO" 5 50
    wbinfo -t > /tmp/wbinfo_t.log 2>&1
    if [ $? -ne 0 ]; then
        aviso "Teste de confiança (wbinfo -t) falhou. Verifique /tmp/wbinfo_t.log\n\nTrust test (wbinfo -t) failed. Check /tmp/wbinfo_t.log"
    else
        echo "[INFO] Teste de confiança (wbinfo -t) bem-sucedido / Trust test (wbinfo -t) successful."
    fi
    wbinfo -u > /tmp/wbinfo_u.log 2>&1
    if [ $? -ne 0 ]; then
        aviso "Falha ao listar usuários do domínio (wbinfo -u). Verifique /tmp/wbinfo_u.log\n\nFailed to list domain users (wbinfo -u). Check /tmp/wbinfo_u.log"
    else
        echo "[INFO] Listagem de usuários do domínio (wbinfo -u) bem-sucedida / Domain user listing (wbinfo -u) successful."
    fi
    
    sucesso_msg "$MEMBER_SUCCESS"
}

# Função para exibir informações finais com dialog
exibir_informacoes_finais() {
    FINAL_TEXT=$(printf "$FINAL_INFO_TEXT" "$HOSTNAME" "${DOMAIN:-N/A}" "$IP_ADDRESS")
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$FINAL_INFO" --msgbox "${FINAL_TEXT}" 15 70
}

# Função principal
main() {
    # Verificar se é root
    verificar_root
    
    # Verificar se é Debian
    verificar_debian
    
    # Atualizar sistema
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --yesno "$INSTALL_UPDATE_SYSTEM" 6 60
    if [ $? -eq 0 ]; then
        atualizar_sistema
    fi
    
    # Instalar dependências (incluindo dialog)
    instalar_dependencias
    
    # Instalar Samba
    instalar_samba_pacote
    
    # Configurar NTP
    configurar_ntp
    
    # Configurar hostname e hosts
    configurar_hostname
    
    # Menu de seleção do tipo de instalação
    dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --title "$INSTALL_TYPE" --menu "$INSTALL_TYPE_SELECT" 15 60 3 \
    1 "$INSTALL_TYPE_DC" \
    2 "$INSTALL_TYPE_FILE" \
    3 "$INSTALL_TYPE_MEMBER" 2> $OUTPUT
    
    exit_status=$?
    TIPO_INSTALACAO=$(cat $OUTPUT)
    rm -f $OUTPUT

    if [ $exit_status -ne 0 ]; then
        dialog --backtitle "Samba Manager - Rafael Schuh (github.com/rafaelhschuh)" --msgbox "$MSG_CANCELED" 5 40
        exit 0
    fi
    
    case $TIPO_INSTALACAO in
        1)
            # Configurar DNS para AD DC
            configurar_dns_ad
            # Provisionar AD
            provisionar_ad
            ;;
        2)
            # Configurar servidor de arquivos
            configurar_servidor_arquivos
            ;;
        3)
            # Configurar membro de domínio
            configurar_membro_dominio
            ;;
        *)
            erro "Opção inválida / Invalid option"
            ;;
    esac
    
    # Exibir informações finais
    exibir_informacoes_finais
}

# Executar função principal
main

# Limpar arquivo temporário na saída normal
rm -f $OUTPUT
exit 0

