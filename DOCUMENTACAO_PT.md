# Documentação Completa - Samba 4 Manager

---

## 1. Introdução

Bem-vindo à documentação do **Samba 4 Manager**! Este conjunto de scripts foi desenvolvido por **Rafael Schuh** ([github.com/rafaelhschuh](https://github.com/rafaelhschuh)) para simplificar a instalação, configuração e gerenciamento de servidores Samba 4 em sistemas baseados no Debian (como o próprio Debian, Ubuntu, etc.).

O objetivo principal é oferecer uma interface de terminal amigável e intuitiva (usando o `dialog`) que guia você através das complexidades da configuração do Samba, seja para criar um Controlador de Domínio Active Directory (AD DC), um servidor de arquivos independente ou integrar um servidor a um domínio existente.

Os scripts são multilíngues, suportando **Português do Brasil** e **Inglês**, tornando-os acessíveis a um público mais amplo.

## 2. Instalação Automatizada (Recomendado)

A maneira mais fácil e rápida de instalar ou atualizar o Samba 4 Manager é usando o script de instalação automatizada diretamente do repositório GitHub. Este método garante que você tenha a versão mais recente e configura tudo automaticamente.

**O que o instalador faz?**

1.  **Verifica Dependências**: Garante que `wget` (ou `curl`) e `unzip` estejam instalados.
2.  **Baixa os Scripts**: Faz o download do pacote completo (`samba-scripts.zip`) do GitHub.
3.  **Instala os Scripts**: Cria um diretório oculto na sua pasta pessoal (`~/.samba-scripts`) e extrai todos os scripts lá.
4.  **Cria um Atalho (Lançador)**: Adiciona um comando `samba-script` ao diretório `/usr/local/bin`. Isso permite que você execute o gerenciador de qualquer lugar no terminal.
5.  **Define Permissões**: Garante que todos os scripts sejam executáveis.

**Como executar a instalação automatizada:**

Abra o terminal e execute **um** dos seguintes comandos como **usuário root** (usando `sudo`):

*   **Usando `wget`:**

    ```bash
    sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
    ```

*   **Usando `curl`:**

    ```bash
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
    ```

O script cuidará de todo o processo. Aguarde a mensagem de sucesso no final.

## 3. Utilização do Samba Manager

Após a instalação bem-sucedida, usar o Samba Manager é muito simples.

**Como iniciar:**

Abra o terminal e execute o comando:

```bash
sudo samba-script
```

**Passos Iniciais:**

1.  **Seleção de Idioma**: A primeira tela solicitará que você escolha o idioma desejado para a interface (Português do Brasil ou Inglês). Use as setas do teclado para selecionar e pressione `Enter`.
2.  **Tela de Boas-Vindas**: Uma breve mensagem de boas-vindas será exibida. Pressione `Enter` para continuar.
3.  **Menu Principal**: Você chegará ao menu principal, onde poderá escolher a ação desejada.

**Opções do Menu Principal:**

Use as setas para navegar e `Enter` para selecionar.

*   **`1. Instalar e Configurar Samba 4`**: Esta é a opção principal para configurar seu servidor Samba. Ao selecioná-la, você será guiado por várias etapas:
    *   **Atualização do Sistema**: Pergunta se você deseja atualizar os pacotes do seu Debian (`apt update && apt upgrade`).
    *   **Instalação de Dependências**: Instala automaticamente todos os pacotes necessários para o Samba e para os próprios scripts.
    *   **Instalação do Samba**: Instala os pacotes principais do Samba 4.
    *   **Configuração de Rede**: Solicita informações essenciais como o nome do servidor (hostname), o nome do domínio e o endereço IP estático.
    *   **Seleção do Tipo de Instalação**: Aqui você escolhe o papel do seu servidor Samba:
        *   **`Controlador de Domínio Active Directory`**: Configura o Samba para funcionar como um AD DC, similar a um servidor Windows Server. Isso inclui provisionamento do domínio, configuração de DNS interno, etc.
        *   **`Servidor de Arquivos Standalone`**: Configura o Samba como um servidor de arquivos simples, sem integração com um domínio AD. Cria compartilhamentos de exemplo (`publico` e `dados`).
        *   **`Membro de Domínio`**: Configura o servidor para ingressar em um domínio Active Directory existente (seja ele gerenciado por outro Samba ou por um Windows Server).
    *   **Configurações Específicas**: Dependendo do tipo de instalação escolhido, o script solicitará informações adicionais (como senha de administrador do domínio, IP do DC existente, etc.) e realizará as configurações necessárias (DNS, Kerberos, smb.conf, PAM, NSS, etc.).
    *   **Informações Finais**: Ao final, exibe um resumo das configurações aplicadas.

*   **`2. Adicionar Novo Funcionário`**: Este script auxiliar facilita a criação de usuários para acesso aos compartilhamentos Samba.
    *   Solicita o nome do grupo Samba (padrão: `sambausers`) que dará acesso aos compartilhamentos.
    *   Solicita o nome de usuário do novo funcionário.
    *   Cria o usuário no sistema **sem** criar uma pasta `/home` para ele (ideal para usuários que só acessarão compartilhamentos).
    *   Adiciona o usuário ao grupo Samba especificado.
    *   Define a senha do usuário no sistema Linux.
    *   Define a senha do usuário no banco de dados do Samba (`smbpasswd`).

*   **`3. Sobre`**: Mostra informações sobre o Samba 4 Manager, incluindo o autor e a data.

*   **`4. Sair`**: Fecha o Samba 4 Manager.

**Navegação na Interface:**

*   Use as **Setas (Cima/Baixo)** para navegar entre as opções nos menus.
*   Use as **Setas (Esquerda/Direita)** ou a tecla **Tab** para mover entre botões (como `<OK>`, `<Cancel>`, `<Yes>`, `<No>`).
*   Pressione **Enter** para confirmar uma seleção ou ativar um botão.
*   Pressione **Esc** geralmente cancela a ação atual ou volta ao menu anterior (em alguns casos, pode sair do script).

## 4. Requisitos do Sistema

Para usar o Samba 4 Manager, seu sistema precisa atender aos seguintes requisitos:

*   **Sistema Operacional**: Debian ou um derivado (como Ubuntu). Recomendado Debian 10 (Buster) ou superior.
*   **Privilégios**: Acesso root (necessário executar os scripts com `sudo`).
*   **Conexão com a Internet**: Essencial para baixar os pacotes durante a instalação e para usar o instalador automatizado.
*   **Endereço IP Estático**: Fortemente recomendado (e solicitado durante a configuração) para servidores, especialmente se for um Controlador de Domínio.

## 5. Autor

*   **Rafael Schuh** - [github.com/rafaelhschuh](https://github.com/rafaelhschuh)

*Abril 2025*

---

Esperamos que esta documentação ajude você a utilizar o Samba 4 Manager de forma eficaz. Para dúvidas, sugestões ou reporte de problemas, visite o [repositório no GitHub](https://github.com/rafaelhschuh/samba-4-scipts).
