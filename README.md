# :computer: Samba 4 Manager - Debian Scripts

[![Author](https://img.shields.io/badge/Author-Rafael%20Schuh-blue.svg)](https://github.com/rafaelhschuh)
[![GitHub stars](https://img.shields.io/github/stars/rafaelhschuh/samba-4-scipts.svg?style=social&label=Star&maxAge=2592000)](https://github.com/rafaelhschuh/samba-4-scipts/stargazers/)

---

## :book: Visão Geral

O **Samba 4 Manager** é uma coleção de scripts que oferece uma interface amigável no terminal, utilizando `dialog`, para facilitar a instalação, configuração e gerenciamento do Samba 4 em sistemas baseados no Debian.

Ideal para configurar:
- **Controlador de Domínio AD**
- **Servidor de Arquivos**
- **Membro de Domínio**

Suporte completo a múltiplos idiomas (Inglês e Português-BR) com instruções claras e passo a passo.

---

## :star2: Principais Recursos

- **Suporte Multilíngue**: Inglês e Português-BR.
- **Interface Intuitiva**: Menus interativos via `dialog`.
- **Instalações Versáteis**:
  - Controlador de Domínio AD
  - Servidor de Arquivos
  - Membro de Domínio
- **Gerenciamento de Dependências**: Instalação automática.
- **Gestão de Usuários**: Adição rápida de usuários.
- **Instalação Automatizada**: Um comando para tudo.

---

## :rocket: Instalação Rápida

Execute como root para instalar:

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
```

**Ou com curl:**

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
```

O instalador configurará tudo em `~/.samba-scripts` e criará o comando `samba-script` em `/usr/local/bin`.

---

## :keyboard: Como Usar

Após a instalação, execute:

```bash
sudo samba-script
```

Navegue pelas opções:
1. **Escolher idioma**
2. **Menu principal**:
   - Instalar e Configurar Samba 4
   - Adicionar Novo Funcionário
   - Sobre o Script
   - Sair

Siga as instruções na tela para concluir suas tarefas!

---

## :memo: Documentação

- [Documentação em Inglês](./DOCUMENTATION_EN.md)
- [Documentação em Português](./DOCUMENTACAO_PT.md)

---

## :gear: Requisitos

- Sistema Debian-based (Debian 10 Buster ou superior)
- Permissões de root (sudo)
- Conexão com a internet

---

## :bust_in_silhouette: Autor

**Rafael Schuh** - [github.com/rafaelhschuh](https://github.com/rafaelhschuh)

_Abril 2025_

---

:speech_balloon: Contribuições, sugestões e relatos de problemas são muito bem-vindos no [repositório GitHub](https://github.com/rafaelhschuh/samba-4-scipts)!


