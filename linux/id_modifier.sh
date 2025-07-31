#!/bin/bash

# Renkli loglama
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

# UUID ve rastgele hex üret
random_uuid() { cat /proc/sys/kernel/random/uuid; }
random_hex() { head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n'; }

# storage.json dosyasını bul
get_storage_path() {
    local base="$HOME/.config/Code/User"
    [[ -f "$base/storage.json" ]] && echo "$base/storage.json" && return
    [[ -f "$base/globalStorage/storage.json" ]] && echo "$base/globalStorage/storage.json" && return
    echo ""
}

# JSON dosyasını güncelle
modify_ids() {
    local file="$1"
    backup_file "$file"

    new_machine_id=$(random_hex)
    new_dev_id=$(random_uuid)

    # jq ile değiştiriyoruz
    tmp_file=$(mktemp)

    jq --arg mid "$new_machine_id" --arg did "$new_dev_id" '
        (.. | objects | select(has("machineId"))).machineId = $mid |
        (.. | objects | select(has("devDeviceId"))).devDeviceId = $did
    ' "$file" > "$tmp_file" && mv "$tmp_file" "$file"

    log_success "Telemetry ID'leri güncellendi: $file"
    log_info "Yeni machineId: $new_machine_id"
    log_info "Yeni devDeviceId: $new_dev_id"
}

# Yedekleme fonksiyonu
backup_file() {
    local filepath="$1"
    local backup="$filepath.backup"
    if [[ ! -f "$backup" ]]; then
        cp "$filepath" "$backup"
        log_success "Yedek alındı: $backup"
    else
        log_warning "Zaten yedek var: $backup"
    fi
}

# Ana
main() {
    log_info "Telemetry ID değiştirme başlatılıyor..."

    path=$(get_storage_path)
    if [[ -z "$path" ]]; then
        log_warning "storage.json bulunamadı"
        exit 0
    fi

    if ! command -v jq &> /dev/null; then
        log_error "'jq' yüklü değil. sudo apt install jq ile kurabilirsin"
        exit 1
    fi

    modify_ids "$path"
}

main

