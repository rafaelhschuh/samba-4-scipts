# Complete Documentation - Samba 4 Manager

---

## 1. Introduction

Welcome to the **Samba 4 Manager** documentation! This set of scripts was developed by **Rafael Schuh** ([github.com/rafaelhschuh](https://github.com/rafaelhschuh)) to simplify the installation, configuration, and management of Samba 4 servers on Debian-based systems (such as Debian itself, Ubuntu, etc.).

The main goal is to offer a friendly and intuitive terminal interface (using `dialog`) that guides you through the complexities of Samba configuration, whether you need to create an Active Directory Domain Controller (AD DC), a standalone file server, or integrate a server into an existing domain.

The scripts are multilingual, supporting **Brazilian Portuguese** and **English**, making them accessible to a wider audience.

## 2. Automated Installation (Recommended)

The easiest and fastest way to install or update the Samba 4 Manager is by using the automated installation script directly from the GitHub repository. This method ensures you have the latest version and sets everything up automatically.

**What does the installer do?**

1.  **Checks Dependencies**: Ensures that `wget` (or `curl`) and `unzip` are installed.
2.  **Downloads Scripts**: Downloads the complete package (`samba-scripts.zip`) from GitHub.
3.  **Installs Scripts**: Creates a hidden directory in your home folder (`~/.samba-scripts`) and extracts all scripts there.
4.  **Creates a Launcher**: Adds a `samba-script` command to the `/usr/local/bin` directory. This allows you to run the manager from anywhere in the terminal.
5.  **Sets Permissions**: Ensures all scripts are executable.

**How to run the automated installation:**

Open your terminal and run **one** of the following commands as the **root user** (using `sudo`):

*   **Using `wget`:**

    ```bash
    sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
    ```

*   **Using `curl`:**

    ```bash
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rafaelhschuh/samba-4-scipts/main/install.sh)"
    ```

The script will handle the entire process. Wait for the success message at the end.

## 3. Using the Samba Manager

After a successful installation, using the Samba Manager is very straightforward.

**How to start:**

Open your terminal and run the command:

```bash
sudo samba-script
```

**Initial Steps:**

1.  **Language Selection**: The first screen will prompt you to choose the desired interface language (Brazilian Portuguese or English). Use the arrow keys to select and press `Enter`.
2.  **Welcome Screen**: A brief welcome message will be displayed. Press `Enter` to continue.
3.  **Main Menu**: You will arrive at the main menu, where you can choose the desired action.

**Main Menu Options:**

Use the arrow keys to navigate and `Enter` to select.

*   **`1. Install and Configure Samba 4`**: This is the main option for setting up your Samba server. Upon selecting it, you will be guided through several steps:
    *   **System Update**: Asks if you want to update your Debian system packages (`apt update && apt upgrade`).
    *   **Dependency Installation**: Automatically installs all necessary packages for Samba and the scripts themselves.
    *   **Samba Installation**: Installs the core Samba 4 packages.
    *   **Network Configuration**: Prompts for essential information like the server name (hostname), domain name, and static IP address.
    *   **Installation Type Selection**: Here you choose the role of your Samba server:
        *   **`Active Directory Domain Controller`**: Configures Samba to function as an AD DC, similar to a Windows Server. This includes domain provisioning, internal DNS configuration, etc.
        *   **`Standalone File Server`**: Configures Samba as a simple file server, without integration into an AD domain. Creates example shares (`publico` and `dados`).
        *   **`Domain Member`**: Configures the server to join an existing Active Directory domain (whether managed by another Samba server or a Windows Server).
    *   **Specific Configurations**: Depending on the chosen installation type, the script will ask for additional information (like domain administrator password, existing DC IP address, etc.) and perform the necessary configurations (DNS, Kerberos, smb.conf, PAM, NSS, etc.).
    *   **Final Information**: At the end, displays a summary of the applied configurations.

*   **`2. Add New Employee`**: This helper script facilitates the creation of users for accessing Samba shares.
    *   Prompts for the Samba group name (default: `sambausers`) that will grant access to shares.
    *   Prompts for the new employee's username.
    *   Creates the user on the system **without** creating a `/home` directory for them (ideal for users who will only access shares).
    *   Adds the user to the specified Samba group.
    *   Sets the user's password on the Linux system.
    *   Sets the user's password in the Samba database (`smbpasswd`).

*   **`3. About`**: Shows information about the Samba 4 Manager, including the author and date.

*   **`4. Exit`**: Closes the Samba 4 Manager.

**Interface Navigation:**

*   Use the **Arrow Keys (Up/Down)** to navigate between options in menus.
*   Use the **Arrow Keys (Left/Right)** or the **Tab** key to move between buttons (like `<OK>`, `<Cancel>`, `<Yes>`, `<No>`).
*   Press **Enter** to confirm a selection or activate a button.
*   Press **Esc** usually cancels the current action or goes back to the previous menu (in some cases, it might exit the script).

## 4. System Requirements

To use the Samba 4 Manager, your system needs to meet the following requirements:

*   **Operating System**: Debian or a derivative (like Ubuntu). Debian 10 (Buster) or later is recommended.
*   **Privileges**: Root access (scripts need to be run with `sudo`).
*   **Internet Connection**: Essential for downloading packages during installation and for using the automated installer.
*   **Static IP Address**: Strongly recommended (and requested during configuration) for servers, especially if it will be a Domain Controller.

## 5. Author

*   **Rafael Schuh** - [github.com/rafaelhschuh](https://github.com/rafaelhschuh)

*April 2025*

---

We hope this documentation helps you use the Samba 4 Manager effectively. For questions, suggestions, or issue reporting, please visit the [GitHub repository](https://github.com/rafaelhschuh/samba-4-scipts).
