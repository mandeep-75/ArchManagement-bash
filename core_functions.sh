#!/bin/bash

# Core Functions

# check_deps: Check for required tools and install missing ones.
check_deps() {
    local missing=()
    for dep in hwinfo reflector fzf; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${DARK_YELLOW}Installing missing dependencies: ${missing[*]}...${RESET}"
        sudo pacman -S --noconfirm "${missing[@]}" || exit 1
    fi
}

# backup_repos: Backup repository configuration files.
backup_repos() {
    local backup_dir="$HOME/repo_backup"
    mkdir -p "$backup_dir"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    sudo cp /etc/pacman.conf "$backup_dir/pacman.conf.backup-$timestamp"
    sudo cp /etc/pacman.d/mirrorlist "$backup_dir/mirrorlist.backup-$timestamp"
    echo -e "\n${DARK_GREEN}Repositories backed up with timestamp $timestamp to $backup_dir.${RESET}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# restore_repos: Restore repository configuration files from backup.
restore_repos() {
    local backup_dir="$HOME/repo_backup"
    if [ ! -d "$backup_dir" ]; then
        echo -e "\n${DARK_YELLOW}Backup directory not found.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    local backups
    backups=$(find "$backup_dir" -maxdepth 1 -type f -name "pacman.conf.backup-*" | sort)
    if [ -z "$backups" ]; then
        echo -e "\n${DARK_YELLOW}No backup files found in $backup_dir.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    local selected
    selected=$(printf "%s\n" $backups | fzf --prompt "Select pacman.conf backup to restore > " --height=80% --border --layout=reverse --margin=2,4)
    if [ -z "$selected" ]; then
        echo -e "\n${DARK_YELLOW}No backup selected.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    local timestamp
    timestamp=$(echo "$selected" | sed 's/.*pacman.conf.backup-//')
    local mirror_backup="$backup_dir/mirrorlist.backup-$timestamp"
    if [ ! -f "$mirror_backup" ]; then
        echo -e "\n${DARK_YELLOW}Corresponding mirrorlist backup not found for timestamp $timestamp.${RESET}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    sudo cp "$selected" /etc/pacman.conf
    sudo cp "$mirror_backup" /etc/pacman.d/mirrorlist
    echo -e "\n${DARK_GREEN}Repositories restored from backup with timestamp $timestamp.${RESET}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# update_mirrors: Update the mirrorlist using rate-mirrors.
update_mirrors() {
    echo -e "\n${DARK_GREEN}Updating mirrorlist using rate-mirrors with verbose logging...${RESET}"
    RUST_LOG=trace rate-mirrors --protocol https arch | sudo tee /etc/pacman.d/mirrorlist
    echo -e "\n${DARK_GREEN}Mirrorlist updated successfully.${RESET}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# remove_backups: Remove all backup files.
remove_backups() {
    local backup_dir="$HOME/repo_backup"
    if [ -d "$backup_dir" ]; then
        rm -rf "$backup_dir"
        echo -e "\n${DARK_GREEN}All backup files removed from $backup_dir.${RESET}"
    else
        echo -e "\n${DARK_YELLOW}No backup directory found.${RESET}"
    fi
    read -n 1 -s -r -p "Press any key to continue..."
}

# system_cleanup: Clean up the system by removing orphaned packages and caches.
system_cleanup() {
    if orphans=$(pacman -Qdtq); then
        if [[ -n "$orphans" ]]; then
            echo -e "\n${DARK_YELLOW}Orphaned packages:${RESET}\n$orphans"
            run_cmd "Remove Orphans" "sudo pacman -Rns --noconfirm $orphans"
        else
            echo -e "\n${DARK_GREEN}No orphaned packages found.${RESET}"
            read -n 1 -s -r -p "Press any key to continue..."
        fi
    fi
    run_cmd "Clean Pacman Cache" "sudo pacman -Scc --noconfirm"
    command -v yay &>/dev/null && run_cmd "Clean yay Cache" "yay -Scc --noconfirm"
    command -v flatpak &>/dev/null && run_cmd "Clean Flatpak" "flatpak uninstall --unused -y"
    run_cmd "Clean Journal" "sudo journalctl --vacuum-time=7d"
}

# parse_exclusion_input: Parses an exclusion string (supports numbers and ranges).
parse_exclusion_input() {
    local input="$1"
    local -a indices=()
    input=$(echo "$input" | tr ',' ' ')
    for token in $input; do
        if [[ "$token" =~ ^([0-9]+)[[:space:]]*to[[:space:]]*([0-9]+)$ ]]; then
            start=${BASH_REMATCH[1]}
            end=${BASH_REMATCH[2]}
            if (( start > end )); then
                tmp=$start; start=$end; end=$tmp
            fi
            for ((i=start; i<=end; i++)); do
                indices+=($((i-1)))
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            indices+=($((token-1)))
        fi
    done
    declare -A seen
    local -a uniq=()
    for i in "${indices[@]}"; do
        if [[ -z "${seen[$i]}" ]]; then
            uniq+=("$i")
            seen[$i]=1
        fi
    done
    echo "${uniq[@]}"
}

# search_package: Search for a package and display info.
search_package() {
    read -p "Enter package name to search: " pkg
    [[ -z "$pkg" ]] && return
    local result
    result=$( (echo "Back"; pacman -Ss "$pkg") | fzf --prompt "Search Results > " --height=80% --border --layout=reverse --margin=2,4 )
    if [[ "$result" == "Back" || -z "$result" ]]; then
        return
    else
        local pkgname
        pkgname=$(echo "$result" | cut -d'/' -f2 | awk '{print $1}')
        list_cmd "Package Info" "pacman -Qi $pkgname"
    fi
}

# run_cmd: Executes a command with an optional confirmation prompt.
# It pauses only on error.
run_cmd() {
    local confirm_flag=1
    if [[ "$1" == "--no-confirm" ]]; then
        confirm_flag=0
        shift
    fi

    local title="$1"
    shift
    local cmd="$*"

    if [[ $confirm_flag -eq 1 ]]; then
        local confirm
        confirm=$(fzf_menu "Execute $title?" "Yes" "No")
        if [[ "$confirm" != "Yes" ]]; then
            echo -e "\n${DARK_YELLOW}$title skipped.${RESET}"
            return
        fi
    fi

    clear
    echo -e "\n${DARK_CYAN}=== $title ===${RESET}"
    echo -e "${DARK_GREEN}Command:${RESET} $cmd"
    echo -e "${DARK_GREEN}-------------------------${RESET}"
    eval "$cmd"
    status=$?
    if [ $status -ne 0 ]; then
         echo -e "\n${DARK_RED}Command failed with exit code $status.${RESET}"
         read -n 1 -s -r -p "Press any key to continue..."
    fi
}

# list_cmd: Runs a command that lists output and always waits for a key press.
list_cmd() {
    local title="$1"
    shift
    local cmd="$*"
    clear
    echo -e "\n${DARK_CYAN}=== $title ===${RESET}"
    echo -e "${DARK_GREEN}Command:${RESET} $cmd"
    echo -e "${DARK_GREEN}-------------------------${RESET}"
    eval "$cmd"
    echo -e "\n${DARK_CYAN}=== End of $title ===${RESET}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# repo_manager: Manage repositories.
repo_manager() {
    while true; do
        choice=$(fzf_menu "Repository Manager" \
            "Backup Repositories" "Restore Repositories" "Update Mirrorlist" "Remove Backup Files" "Back")
        case "$choice" in
            "Backup Repositories") backup_repos ;;
            "Restore Repositories") restore_repos ;;
            "Update Mirrorlist") update_mirrors ;;
            "Remove Backup Files") remove_backups ;;
            "Back") break ;;
        esac
    done
}

# update_manager: Manage system updates.
update_manager() {
    while true; do
        choice=$(fzf_menu "Update Manager" \
            "Update System" "Update Pacman Packages" "Update AUR Packages" "Update Flatpak Packages" "Back")
        case "$choice" in
            "Update System")
                run_cmd "Update System" "sudo pacman -Syu --noconfirm"
                ;;
            "Update Pacman Packages")
                run_cmd "Update Official Packages" "sudo pacman -Syu --noconfirm"
                ;;
            "Update AUR Packages")
                run_cmd "Update AUR Packages" "yay -Syu --noconfirm"
                ;;
            "Update Flatpak Packages")
                run_cmd "Update Flatpak Packages" "flatpak update -y"
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# kernel_manager: Manage kernel options.
kernel_manager() {
    while true; do
        choice=$(fzf_menu "Kernel Options" \
            "Install Generic" "Install LTS" "Install Zen" "Update Kernel" "Back")
        case "$choice" in
            "Install Generic")
                run_cmd "Install Generic Kernel" "sudo pacman -S --noconfirm linux linux-headers"
                ;;
            "Install LTS")
                run_cmd "Install LTS Kernel" "sudo pacman -S --noconfirm linux-lts linux-lts-headers"
                ;;
            "Install Zen")
                run_cmd "Install Zen Kernel" "sudo pacman -S --noconfirm linux-zen linux-zen-headers"
                ;;
            "Update Kernel")
                local kernels
                kernels=$(pacman -Qq | grep -E '^linux(-lts|-zen)?$')
                if [[ -n "$kernels" ]]; then
                    run_cmd "Update Kernel" "sudo pacman -S --noconfirm $kernels"
                else
                    echo -e "\n${DARK_GREEN}No kernel packages found.${RESET}"
                    read -n 1 -s -r -p "Press any key to continue..."
                fi
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# pacman_manager: Manage Pacman packages.
pacman_manager() {
    while true; do
        choice=$(fzf_menu "Pacman Manager" \
            "Install Package" "Remove Package" "Search Package" "Query Package Info" "List Installed Packages" "Back")
        case "$choice" in
            "Install Package")
                read -p "Enter package name to install: " pkg
                [[ -z "$pkg" ]] && continue
                run_cmd "Install Package" "sudo pacman -S --noconfirm $pkg"
                ;;
            "Remove Package")
                while true; do
                    selected=$(printf "Back\n%s" "$(pacman -Qqe)" | fzf --prompt "Select a package to remove > " --height=80% --border --layout=reverse --margin=2,4)
                    [[ -z "$selected" ]] && break
                    if [[ "$selected" == "Back" ]]; then break; fi
                    action=$(fzf_menu "Action for $selected" "Remove" "Reinstall" "Back")
                    case "$action" in
                        "Remove")
                            run_cmd --no-confirm "Remove Package" "sudo pacman -Rns --noconfirm $selected"
                            break
                            ;;
                        "Reinstall")
                            run_cmd --no-confirm "Reinstall Package" "sudo pacman -S --noconfirm $selected"
                            break
                            ;;
                        "Back")
                            continue
                            ;;
                    esac
                done
                ;;
            "Search Package")
                search_package
                ;;
            "Query Package Info")
                read -p "Enter package name: " pkg
                [[ -z "$pkg" ]] && continue
                list_cmd "Package Info" "pacman -Qi $pkg"
                ;;
            "List Installed Packages")
                list_cmd "Installed Packages" "pacman -Qqe"
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# aur_manager: Manage AUR packages.
aur_manager() {
    while true; do
        choice=$(fzf_menu "AUR Manager" \
            "Install AUR Package" "Remove AUR Package" "Search AUR Package" "List Installed AUR Packages" "Back")
        case "$choice" in
            "Install AUR Package")
                read -p "Enter AUR package name to install: " pkg
                [[ -z "$pkg" ]] && continue
                run_cmd "Install AUR Package" "yay -S --noconfirm $pkg"
                ;;
            "Remove AUR Package")
                while true; do
                    selected=$(printf "Back\n%s" "$(pacman -Qm | awk '{print $1}')" | fzf --prompt "Select an AUR package to remove > " --height=80% --border --layout=reverse --margin=2,4)
                    [[ -z "$selected" ]] && break
                    if [[ "$selected" == "Back" ]]; then break; fi
                    action=$(fzf_menu "Action for $selected" "Remove" "Reinstall" "Back")
                    case "$action" in
                        "Remove")
                            run_cmd --no-confirm "Remove AUR Package" "yay -Rns --noconfirm $selected"
                            break
                            ;;
                        "Reinstall")
                            run_cmd --no-confirm "Reinstall AUR Package" "yay -S --noconfirm $selected"
                            break
                            ;;
                        "Back")
                            continue
                            ;;
                    esac
                done
                ;;
            "Search AUR Package")
                read -p "Enter AUR package name to search: " pkg
                [[ -z "$pkg" ]] && return
                local result
                result=$( (echo "Back"; yay -Ss "$pkg") | fzf --prompt "Search Results > " --height=80% --border --layout=reverse --margin=2,4 )
                if [[ "$result" == "Back" || -z "$result" ]]; then
                    return
                else
                    local pkgname
                    pkgname=$(echo "$result" | cut -d'/' -f2 | awk '{print $1}')
                    list_cmd "AUR Package Info" "yay -Qi $pkgname"
                fi
                ;;
            "List Installed AUR Packages")
                list_cmd "Installed AUR Packages" "pacman -Qm"
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# flatpak_manager: Manage Flatpak packages.
flatpak_manager() {
    while true; do
        choice=$(fzf_menu "Flatpak Manager" \
            "Install Flatpak Package" "Remove Flatpak Package" "Search Flatpak Package" "List Installed Flatpak Packages" "Back")
        case "$choice" in
            "Install Flatpak Package")
                read -p "Enter Flatpak package name to install: " pkg
                [[ -z "$pkg" ]] && continue
                run_cmd "Install Flatpak Package" "sudo flatpak install -y $pkg"
                ;;
            "Remove Flatpak Package")
                while true; do
                    selected=$(printf "Back\n%s" "$(flatpak list --app --columns=application)" | fzf --prompt "Select a Flatpak package to remove > " --height=80% --border --layout=reverse --margin=2,4)
                    [[ -z "$selected" ]] && break
                    if [[ "$selected" == "Back" ]]; then break; fi
                    action=$(fzf_menu "Action for $selected" "Remove" "Reinstall" "Back")
                    case "$action" in
                        "Remove")
                            run_cmd --no-confirm "Remove Flatpak Package" "sudo flatpak uninstall -y $selected"
                            break
                            ;;
                        "Reinstall")
                            run_cmd --no-confirm "Reinstall Flatpak Package" "sudo flatpak install -y $selected"
                            break
                            ;;
                        "Back")
                            continue
                            ;;
                    esac
                done
                ;;
            "Search Flatpak Package")
                read -p "Enter Flatpak package name to search: " pkg
                [[ -z "$pkg" ]] && return
                local result
                result=$( (echo "Back"; flatpak search "$pkg") | fzf --prompt "Search Results > " --height=80% --border --layout=reverse --margin=2,4 )
                if [[ "$result" == "Back" || -z "$result" ]]; then
                    return
                else
                    local pkgname
                    pkgname=$(echo "$result" | awk '{print $1}')
                    list_cmd "Flatpak Package Info" "flatpak info $pkgname"
                fi
                ;;
            "List Installed Flatpak Packages")
                list_cmd "Installed Flatpak Packages" "flatpak list"
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# service_manager: Manage system services.
service_manager() {
    while true; do
        services=($(systemctl list-unit-files --type=service --state=enabled,disabled | awk '/\.service/ {print $1}'))
        if [[ ${#services[@]} -eq 0 ]]; then
            echo -e "\n${DARK_YELLOW}No services found.${RESET}"
            read -n 1 -s -r -p "Press any key to continue..."
            break
        fi
        selected=$(printf "Back\n%s" "$(printf "%s\n" "${services[@]}")" | fzf --prompt "Select a service > " --height=40% --border --layout=reverse --margin=2,4)
        if [[ "$selected" == "Back" || -z "$selected" ]]; then
            break
        fi
        action=$(fzf_menu "Service Action for $selected" "Start" "Stop" "Enable" "Disable" "Back")
        if [[ "$action" == "Back" || -z "$action" ]]; then
            continue
        fi
        run_cmd --no-confirm "${action} Service" "sudo systemctl $action ${selected%.service}"
    done
}

# system_info: Display system information.
system_info() {
    while true; do
        choice=$(fzf_menu "System Information" \
            "Hardware Info" "Disk Usage" "Memory Usage" "CPU Info" "Network Info" "Back")
        case "$choice" in
            "Hardware Info")
                clear
                echo -e "${DARK_CYAN}--- Hardware Information ---${RESET}"
                command -v hwinfo &>/dev/null && hwinfo --short || echo "hwinfo not available."
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "Disk Usage")
                clear
                echo -e "${DARK_CYAN}--- Disk Usage ---${RESET}"
                df -h /
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "Memory Usage")
                clear
                echo -e "${DARK_CYAN}--- Memory Usage ---${RESET}"
                free -h
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "CPU Info")
                clear
                echo -e "${DARK_CYAN}--- CPU Information ---${RESET}"
                lscpu
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "Network Info")
                clear
                echo -e "${DARK_CYAN}--- Network Information ---${RESET}"
                ip a
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            "Back")
                break
                ;;
        esac
    done
}

# system_health: Display system health overview.
system_health() {
    clear
    echo -e "\n${DARK_CYAN}=== System Health Overview ===${RESET}"
    echo -e "${DARK_GREEN}Uptime:${RESET}"
    uptime
    echo -e "\n${DARK_GREEN}Disk Usage:${RESET}"
    df -h
    echo -e "\n${DARK_GREEN}Memory Usage:${RESET}"
    free -h
    if command -v sensors &>/dev/null; then
        echo -e "\n${DARK_GREEN}Temperature Sensors:${RESET}"
        sensors
    else
        echo -e "\n${DARK_YELLOW}Temperature sensors not installed.${RESET}"
    fi
    read -n 1 -s -r -p "Press any key to continue..."
}

# process_monitor: Display top CPU and memory-consuming processes.
process_monitor() {
    clear
    echo -e "\n${DARK_CYAN}=== Top 10 CPU-consuming Processes ===${RESET}"
    ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head -n 11 | column -t
    echo -e "\n${DARK_CYAN}=== Top 10 Memory-consuming Processes ===${RESET}"
    ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head -n 11 | column -t
    read -n 1 -s -r -p "Press any key to continue..."
}

# system_monitor: Monitor system health and processes.
system_monitor() {
    while true; do
        choice=$(fzf_menu "System Monitor" "System Health" "Process Monitor" "Back")
        case "$choice" in
            "System Health") system_health ;;
            "Process Monitor") process_monitor ;;
            "Back") break ;;
        esac
    done
}

# recent_pkg_removal: Remove packages installed within a specified time range.
recent_pkg_removal() {
    while true; do
        choice=$(fzf_menu "Select Time Range for Recent Package Removal" \
            "Last 30 Minutes" "Last 1 Hour" "Last 2 Hours" "Last 3 Hours" "Last 5 Hours" "Last 10 Hours" "Last 12 Hours" "Last 1 Day" "Last 2 Days" "Last 5 Days" "Return")
        if [[ "$choice" == "Return" || -z "$choice" ]]; then
            break
        fi

        case "$choice" in
            "Last 30 Minutes") delta=1800 ;;
            "Last 1 Hour") delta=3600 ;;
            "Last 2 Hours") delta=7200 ;;
            "Last 3 Hours") delta=10800 ;;
            "Last 5 Hours") delta=18000 ;;
            "Last 10 Hours") delta=36000 ;;
            "Last 12 Hours") delta=43200 ;;
            "Last 1 Day") delta=86400 ;;
            "Last 2 Days") delta=172800 ;;
            "Last 5 Days") delta=432000 ;;
        esac

        now=$(date +%s)
        threshold=$((now - delta))

        pkgs=$(awk -v thresh="$threshold" '
        BEGIN { FS="[][]"; }
        /installed/ && $0 !~ /upgraded/ {
          timestamp = $2;
          cmd = "date -d \"" timestamp "\" +%s";
          cmd | getline etime;
          close(cmd);
          if (etime >= thresh) {
              split($5, arr, " ");
              pkg = arr[2];
              print pkg;
          }
        }' /var/log/pacman.log | sort -u)

        if [[ -z "$pkgs" ]]; then
            echo -e "\n${DARK_YELLOW}No packages installed in the selected time range.${RESET}"
            read -n 1 -s -r -p "Press any key to continue..."
            continue
        fi

        IFS=$'\n' read -d '' -r -a pkg_array <<< "$pkgs"

        echo -e "\nPackages installed in the selected time range:"
        for i in "${!pkg_array[@]}"; do
            printf "%d) %s\n" $((i+1)) "${pkg_array[$i]}"
        done

        read -p "Enter package numbers to exclude (space or comma separated) or type 'n' to cancel: " exclude_input
        if [[ "${exclude_input,,}" == "n" ]]; then
            echo "Operation canceled."
            read -n 1 -s -r -p "Press any key to continue..."
            continue
        fi

        exclude_indices=($(parse_exclusion_input "$exclude_input"))

        remove_pkgs=()
        for i in "${!pkg_array[@]}"; do
            skip=false
            for j in "${exclude_indices[@]}"; do
                if [[ $i -eq $j ]]; then
                    skip=true
                    break
                fi
            done
            if ! $skip; then
                remove_pkgs+=("${pkg_array[$i]}")
            fi
        done

        if [ ${#remove_pkgs[@]} -eq 0 ]; then
            echo -e "\n${DARK_YELLOW}No packages left after applying exclusions.${RESET}"
            read -n 1 -s -r -p "Press any key to continue..."
            continue
        fi

        echo -e "\nThe following packages will be removed:"
        for pkg in "${remove_pkgs[@]}"; do
            echo "$pkg"
        done

        read -p "Are you sure you want to remove these packages? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Operation canceled."
            read -n 1 -s -r -p "Press any key to continue..."
            continue
        fi

        pkg_list=$(printf "%s " "${remove_pkgs[@]}")
        run_cmd --no-confirm "Remove Recent Packages" "sudo pacman -Rns --noconfirm $pkg_list"
    done
}
