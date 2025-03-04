#!/bin/bash

# Source the core functions
source "$HOME/.config/scripts/core_functions.sh"

# Optional colors for terminal output.
DARK_GREEN="\e[32;1m"
DARK_YELLOW="\e[33;1m"
DARK_RED="\e[31;1m"
DARK_CYAN="\e[36;1m"
RESET="\e[0m"

# ASCII Art and Visual Elements
BORDER="║"
HEADER_LINE="══════════════════════════════════════════════════"

# fzf configuration with safe color usage
FZF_OPTS="--height=100% --border=rounded --margin=2,4 --layout=reverse --ansi"

# Handle Ctrl+C to exit the script
trap "echo -e '\n${DARK_RED}Exiting... Goodbye!${RESET}'; exit 0" SIGINT

# Define help descriptions for menu options
HELP_UPDATE_SYSTEM="Update all system packages (pacman, AUR, and flatpak) to the latest versions. Ensures your system is secure and up-to-date with the latest features."
HELP_UPDATE_PACMAN="Update only official Arch Linux packages from repositories using pacman. Safe way to keep core system components current."
HELP_UPDATE_AUR="Update user packages from the Arch User Repository. Updates packages not found in official repositories."
HELP_UPDATE_FLATPAK="Update all installed flatpak applications. Flatpaks are containerized applications that can be installed alongside native packages."
HELP_MANAGE_PACMAN="Search for, install, or remove official Arch Linux packages using pacman."
HELP_MANAGE_AUR="Search for, install, or remove user packages from the Arch User Repository."
HELP_MANAGE_FLATPAK="Search for, install, or remove containerized applications using flatpak."
HELP_INSTALL_GENERIC="Install the latest standard Linux kernel and headers. Good for most users with recent hardware."
HELP_INSTALL_LTS="Install the long-term support Linux kernel. Provides stability for production systems with extended support timeline."
HELP_INSTALL_ZEN="Install the Zen kernel optimized for desktop usage. Better responsiveness and lower latency for interactive tasks."
HELP_UPDATE_KERNEL="Update your currently installed kernel to the latest version. Ensures security fixes and new hardware support."
HELP_BACKUP_REPOS="Create a backup of your current repository configuration. Useful before making system changes."
HELP_RESTORE_REPOS="Restore repository configuration from a previous backup. Helps recover from problematic changes."
HELP_UPDATE_MIRRORS="Refresh the list of package mirrors sorted by speed. Improves download speeds for package updates."
HELP_REMOVE_BACKUPS="Clean up old system backup files to free disk space. Removes outdated configuration backups."
HELP_SYSTEM_CLEANUP="Perform various cleaning tasks including package cache, orphans, and temporary files. Frees disk space."
HELP_RECENT_REMOVAL="Review and optionally remove recently installed packages. Helps revert recent changes."
HELP_SERVICE_MANAGER="Manage system services - start, stop, enable, or disable systemd services on your machine."
HELP_SYSTEM_HEALTH="View comprehensive system status including CPU, memory, disk, and service health at a glance."
HELP_PROCESS_MONITOR="Interactive view of running processes with resource usage. Find out what's consuming your system resources."
HELP_HARDWARE_INFO="Display detailed hardware information including CPU, disks, and memory specifications."
HELP_DISK_USAGE="View mounted filesystems with their total, used, and available space. Monitor disk space usage."
HELP_MEMORY_USAGE="Show current RAM and swap usage statistics. Check if your system needs more memory."
HELP_CPU_INFO="Display detailed processor information including model, cores, architecture and capabilities."
HELP_NETWORK_INFO="View network interfaces with their IP addresses and status. Check your network configuration."
HELP_EXIT="Exit this system management utility and return to the shell."

# fzf_menu: Displays a menu using fzf with dynamic help box
fzf_menu() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice
    local default_help="↑/↓: Navigate | ↵: Select | Esc: Back | Hold Ctrl+C: Exit"

    # Create a temporary file for the preview script
    local preview_script=$(mktemp)
    chmod +x "$preview_script"

    # Write the preview script that displays help for the selected option
    cat > "$preview_script" << 'EOF'
#!/bin/bash
option="$1"
display_name=$(echo "$option" | cut -d'|' -f1 | xargs)

echo -e "↑/↓: Navigate | ↵: Select | Esc: Back | Hold Ctrl+C: Exit | Made by Mandeep Singh\n"

if [[ -n "$display_name" ]]; then
    if [[ "$display_name" == "Back" ]]; then
        echo "Return to previous menu"
    else
        echo -e "\033[1mHelp:\033[0m"

        # Map display name to help variable
        case "$display_name" in
            "Update System")
                echo "$HELP_UPDATE_SYSTEM"
                ;;
            "Update Pacman")
                echo "$HELP_UPDATE_PACMAN"
                ;;
            "Update AUR")
                echo "$HELP_UPDATE_AUR"
                ;;
            "Update Flatpak")
                echo "$HELP_UPDATE_FLATPAK"
                ;;
            "Manage Pacman")
                echo "$HELP_MANAGE_PACMAN"
                ;;
            "Manage AUR")
                echo "$HELP_MANAGE_AUR"
                ;;
            "Manage Flatpak")
                echo "$HELP_MANAGE_FLATPAK"
                ;;
            "Install Generic Kernel")
                echo "$HELP_INSTALL_GENERIC"
                ;;
            "Install LTS Kernel")
                echo "$HELP_INSTALL_LTS"
                ;;
            "Install Zen Kernel")
                echo "$HELP_INSTALL_ZEN"
                ;;
            "Update Kernel")
                echo "$HELP_UPDATE_KERNEL"
                ;;
            "Backup Repos")
                echo "$HELP_BACKUP_REPOS"
                ;;
            "Restore Repos")
                echo "$HELP_RESTORE_REPOS"
                ;;
            "Update Mirrors")
                echo "$HELP_UPDATE_MIRRORS"
                ;;
            "Clean Backups")
                echo "$HELP_REMOVE_BACKUPS"
                ;;
            "System Cleanup")
                echo "$HELP_SYSTEM_CLEANUP"
                ;;
            "Recent Removals")
                echo "$HELP_RECENT_REMOVAL"
                ;;
            "Manage Services")
                echo "$HELP_SERVICE_MANAGER"
                ;;
            "System Health")
                echo "$HELP_SYSTEM_HEALTH"
                ;;
            "Process Monitor")
                echo "$HELP_PROCESS_MONITOR"
                ;;
            "Hardware Info")
                echo "$HELP_HARDWARE_INFO"
                ;;
            "Disk Usage")
                echo "$HELP_DISK_USAGE"
                ;;
            "Memory Usage")
                echo "$HELP_MEMORY_USAGE"
                ;;
            "CPU Info")
                echo "$HELP_CPU_INFO"
                ;;
            "Network Info")
                echo "$HELP_NETWORK_INFO"
                ;;
            "Exit")
                echo "$HELP_EXIT"
                ;;
            *)
                echo "No help available for this option."
                ;;
        esac
    fi
fi
EOF

    # Export all help variables
    export HELP_UPDATE_SYSTEM HELP_UPDATE_PACMAN HELP_UPDATE_AUR HELP_UPDATE_FLATPAK
    export HELP_MANAGE_PACMAN HELP_MANAGE_AUR HELP_MANAGE_FLATPAK
    export HELP_INSTALL_GENERIC HELP_INSTALL_LTS HELP_INSTALL_ZEN HELP_UPDATE_KERNEL
    export HELP_BACKUP_REPOS HELP_RESTORE_REPOS HELP_UPDATE_MIRRORS HELP_REMOVE_BACKUPS
    export HELP_SYSTEM_CLEANUP HELP_RECENT_REMOVAL HELP_SERVICE_MANAGER HELP_SYSTEM_HEALTH
    export HELP_PROCESS_MONITOR HELP_HARDWARE_INFO HELP_DISK_USAGE HELP_MEMORY_USAGE
    export HELP_CPU_INFO HELP_NETWORK_INFO HELP_EXIT

    # Execute fzf with the preview script
    choice=$(printf "%s\n" "${options[@]}" | fzf --prompt "$prompt > " \
        $FZF_OPTS \
        --preview="$preview_script {}" \
        --preview-window=down:30%:wrap)

    # Clean up the temporary file
    rm -f "$preview_script"

    [[ $? -eq 130 ]] && exit 0 # Exit if Ctrl+C is pressed inside fzf
    echo "$choice"
}

# Function to search and select a package using fzf
search_and_select_package() {
    local pkg_manager="$1"
    local search_cmd="$2"
    local install_cmd="$3"

    read -p "Enter package name to search: " pkg
    [[ -z "$pkg" ]] && return

    local results
    case "$pkg_manager" in
        "Pacman")
            results=$(pacman -Ss "$pkg" | awk '/^[a-zA-Z0-9\-\.]+/ {print $1}' | fzf --prompt="Select a package to install > " --header="$HEADER_LINE" --border --margin=2,4 --layout=reverse --ansi --multi --tiebreak=index --height=100%)
            ;;
        "AUR")
            results=$(yay -Ss "$pkg" | awk '/^[a-zA-Z0-9\-\.]+/ {print $1}' | fzf --prompt="Select a package to install > " --header="$HEADER_LINE" --border --margin=2,4 --layout=reverse --ansi --multi --tiebreak=index --height=100%)
            ;;
        "Flatpak")
            results=$(flatpak search "$pkg" | awk '/^[a-zA-Z0-9\-\.]+/ {print $1}' | fzf --prompt="Select a package to install > " --header="$HEADER_LINE" --border --margin=2,4 --layout=reverse --ansi --multi --tiebreak=index --height=100%)
            ;;
    esac

    if [[ -n "$results" ]]; then
        selected_pkg=$(echo "$results" | head -n 1)
        run_cmd "Install Package" "$install_cmd $selected_pkg"
    else
        echo "No packages found."
    fi
}

# Rest of the script remains the same...

while true; do
   choice=$(fzf_menu "Main Menu" \
    "Update System              | Updates       | update full" \
    "Update Pacman              | Updates       | update pacman" \
    "Update AUR                 | Updates       | update aur" \
    "Update Flatpak             | Updates       | update flatpak" \
    "Manage Pacman              | Packages      | manage pacman" \
    "Manage AUR                 | Packages      | manage aur" \
    "Manage Flatpak             | Packages      | manage flatpak" \
    "Install Generic Kernel     | Kernel        | install generic" \
    "Install LTS Kernel         | Kernel        | install lts" \
    "Install Zen Kernel         | Kernel        | install zen" \
    "Update Kernel              | Kernel        | update" \
    "Backup Repos               | Repo-Fetch    | backup repos" \
    "Restore Repos              | Repo-Fetch    | restore repos" \
    "Update Mirrors             | Repo-Fetch    | update mirrors" \
    "Clean Backups              | Repo-Fetch    | clean backups" \
    "System Cleanup             | Maintenance   | cleanup" \
    "Recent Removals            | Maintenance   | recent remove" \
    "Manage Services            | Services      | services" \
    "System Health              | Monitoring    | health" \
    "Process Monitor            | Monitoring    | processes" \
    "Hardware Info              | Monitoring    | hardware" \
    "Disk Usage                 | Monitoring    | disk" \
    "Memory Usage               | Monitoring    | memory" \
    "CPU Info                   | Monitoring    | cpu" \
    "Network Info               | Monitoring    | network" \
    "Exit                       | System        | exit quit" \
)

    display_name=$(echo "$choice" | cut -d'|' -f1 | xargs)
    case "$display_name" in
        "Update System")
            echo -e "${DARK_GREEN}Updating Pacman Packages...${RESET}"
            run_cmd "Update Official Packages" "sudo pacman -Syu --noconfirm"

            echo -e "${DARK_GREEN}Updating AUR Packages...${RESET}"
            run_cmd "Update AUR Packages" "yay -Syu --noconfirm"

            echo -e "${DARK_GREEN}Updating Flatpak Packages...${RESET}"
            run_cmd "Update Flatpak Packages" "flatpak update -y"
            ;;
        "Update Pacman")
            run_cmd "Update Official Packages" "sudo pacman -Syu --noconfirm"
            ;;
        "Update AUR")
            run_cmd "Update AUR Packages" "yay -Syu --noconfirm"
            ;;
        "Update Flatpak")
            run_cmd "Update Flatpak Packages" "flatpak update -y"
            ;;
        "Manage Pacman")
            while true; do
                pkg_choice=$(fzf_menu "Manage Pacman Packages" \
                    "Back                  | Return to Main Menu" \
                    "Search Packages       | Search for available packages" \
                    "Install Package       | Install a new package" \
                    "Remove Package        | Remove an installed package" \
                    "List Installed Packages| List all installed packages" \
                    "Package Info          | Display detailed package info")

                pkg_display_name=$(echo "$pkg_choice" | cut -d'|' -f1 | xargs)
                case "$pkg_display_name" in
                    "Back")
                        break
                        ;;
                    "Search Packages")
                        search_and_select_package "Pacman" "pacman -Ss" "sudo pacman -S --noconfirm"
                        ;;
                    "Install Package")
                        read -p "Enter package name to install: " pkg
                        [[ -z "$pkg" ]] && continue
                        run_cmd "Install Package" "sudo pacman -S --noconfirm $pkg"
                        ;;
                    "Remove Package")
                        selected=$(printf "Back\n%s" "$(pacman -Qqe)" | fzf_menu "Select a package to remove" "Back" $(pacman -Qqe))
                        [[ "$selected" == "Back" || -z "$selected" ]] && continue
                        run_cmd "Remove Package" "sudo pacman -Rns --noconfirm $selected"
                        ;;
                    "List Installed Packages")
                        list_cmd "Installed Packages" "pacman -Qqe"
                        ;;
                    "Package Info")
                        read -p "Enter package name: " pkg
                        [[ -z "$pkg" ]] && continue
                        list_cmd "Package Info" "pacman -Qi $pkg"
                        ;;
                esac
            done
            ;;
        "Manage AUR")
            while true; do
                aur_choice=$(fzf_menu "Manage AUR Packages" \
                    "Back                  | Return to Main Menu" \
                    "Search Packages       | Search for available packages" \
                    "Install Package       | Install a new package" \
                    "Remove Package        | Remove an installed package" \
                    "List Installed Packages| List all installed packages" \
                    "Package Info          | Display detailed package info")

                aur_display_name=$(echo "$aur_choice" | cut -d'|' -f1 | xargs)
                case "$aur_display_name" in
                    "Back")
                        break
                        ;;
                    "Search Packages")
                        search_and_select_package "AUR" "yay -Ss" "yay -S --noconfirm"
                        ;;
                    "Install Package")
                        read -p "Enter AUR package name to install: " pkg
                        [[ -z "$pkg" ]] && continue
                        run_cmd "Install AUR Package" "yay -S --noconfirm $pkg"
                        ;;
                    "Remove Package")
                        selected=$(printf "Back\n%s" "$(pacman -Qm | awk '{print $1}')" | fzf_menu "Select an AUR package to remove" "Back" $(pacman -Qm | awk '{print $1}'))
                        [[ "$selected" == "Back" || -z "$selected" ]] && continue
                        run_cmd "Remove AUR Package" "yay -Rns --noconfirm $selected"
                        ;;
                    "List Installed Packages")
                        list_cmd "Installed AUR Packages" "pacman -Qm"
                        ;;
                    "Package Info")
                        read -p "Enter AUR package name: " pkg
                        [[ -z "$pkg" ]] && continue
                        list_cmd "AUR Package Info" "pacman -Qi $pkg"
                        ;;
                esac
            done
            ;;
        "Manage Flatpak")
            while true; do
                flatpak_choice=$(fzf_menu "Manage Flatpak Packages" \
                    "Back                  | Return to Main Menu" \
                    "Search Packages       | Search for available packages" \
                    "Install Package       | Install a new package" \
                    "Remove Package        | Remove an installed package" \
                    "List Installed Packages| List all installed packages" \
                    "Package Info          | Display detailed package info")

                flatpak_display_name=$(echo "$flatpak_choice" | cut -d'|' -f1 | xargs)
                case "$flatpak_display_name" in
                    "Back")
                        break
                        ;;
                    "Search Packages")
                        search_and_select_package "Flatpak" "flatpak search" "flatpak install -y"
                        ;;
                    "Install Package")
                        read -p "Enter Flatpak package name to install: " pkg
                        [[ -z "$pkg" ]] && continue
                        run_cmd "Install Flatpak Package" "flatpak install -y $pkg"
                        ;;
                    "Remove Package")
                        selected=$(printf "Back\n%s" "$(flatpak list --app --columns=application)" | fzf_menu "Select a Flatpak package to remove" "Back" $(flatpak list --app --columns=application))
                        [[ "$selected" == "Back" || -z "$selected" ]] && continue
                        run_cmd "Remove Flatpak Package" "flatpak uninstall -y $selected"
                        ;;
                    "List Installed Packages")
                        list_cmd "Installed Flatpak Packages" "flatpak list"
                        ;;
                    "Package Info")
                        read -p "Enter Flatpak package name: " pkg
                        [[ -z "$pkg" ]] && continue
                        list_cmd "Flatpak Package Info" "flatpak info $pkg"
                        ;;
                esac
            done
            ;;
        "Install Generic Kernel")
            run_cmd "Install Generic Kernel" "sudo pacman -S --noconfirm linux linux-headers"
            ;;
        "Install LTS Kernel")
            run_cmd "Install LTS Kernel" "sudo pacman -S --noconfirm linux-lts linux-lts-headers"
            ;;
        "Install Zen Kernel")
            run_cmd "Install Zen Kernel" "sudo pacman -S --noconfirm linux-zen linux-zen-headers"
            ;;
        "Update Kernel")
            run_cmd "Update Kernel" "sudo pacman -Syu --noconfirm"
            ;;
        "Backup Repositories")
            backup_repos
            ;;
        "Restore Repositories")
            restore_repos
            ;;
        "Update Mirrors")
            update_mirrors
            ;;
        "Clean Backups")
            remove_backups
            ;;
        "System Cleanup")
            system_cleanup
            ;;
        "Recent Removals")
            recent_pkg_removal
            ;;
        "Manage Services")
            service_manager
            ;;
        "System Health")
            system_health
            ;;
        "Process Monitor")
            process_monitor
            ;;
        "Hardware Info")
            list_cmd "Hardware Info" "lscpu && lsblk && free -h"
            ;;
        "Disk Usage")
            list_cmd "Disk Usage" "df -h"
            ;;
        "Memory Usage")
            list_cmd "Memory Usage" "free -h"
            ;;
        "CPU Info")
            list_cmd "CPU Info" "lscpu"
            ;;
        "Network Info")
            list_cmd "Network Info" "ip a"
            ;;
        "Exit")
            echo -e "\n${DARK_CYAN}Exiting... Goodbye!${RESET}"
            exit 0
            ;;
    esac
done
