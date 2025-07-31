#!/bin/bash

# Renkli loglama
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

# sqlite3 kontrolü
check_sqlite3() {
    if ! command -v sqlite3 &> /dev/null; then
        log_error "sqlite3 bulunamadı. Lütfen SQLite3'ü kur."
        exit 1
    fi
}

# VS Code veri dizinleri
get_vscode_locations() {
    local locations=()
    local config_dir="$HOME/.config/Code"

    [[ -d "$config_dir/User" ]] && locations+=("$config_dir/User")
    [[ -d "$config_dir/workspaceStorage" ]] && locations+=("$config_dir/workspaceStorage")
    [[ -d "$config_dir/User/globalStorage" ]] && locations+=("$config_dir/User/globalStorage")

    echo "${locations[@]}"
}

# Yedek al
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

# Veritabanını temizle
clean_sqlite_db() {
    local db="$1"
    backup_file "$db"
    tables=$(sqlite3 "$db" ".tables")
    for table in $tables; do
        columns=$(sqlite3 "$db" "PRAGMA table_info($table);")
        while IFS= read -r line; do
            col_type=$(echo "$line" | awk -F'|' '{print $3}')
            col_name=$(echo "$line" | awk -F'|' '{print $2}')
            if [[ "$col_type" == *TEXT* ]]; then
                sqlite3 "$db" "DELETE FROM $table WHERE $col_name LIKE '%augment%';"
            fi
        done <<< "$columns"
    done
    log_success "Temizlendi: $db"
}

# Ana fonksiyon
main() {
    log_info "VS Code veritabanı temizleme başlatılıyor..."
    check_sqlite3

    db_count=0
    locations=($(get_vscode_locations))

    if [[ ${#locations[@]} -eq 0 ]]; then
        log_warning "Hiçbir VS Code veri dizini bulunamadı"
        exit 0
    fi

    for dir in "${locations[@]}"; do
        while IFS= read -r db; do
            log_info "Veritabanı bulundu: $db"
            clean_sqlite_db "$db"
            ((db_count++))
        done < <(find "$dir" -type f \( -iname "*.db" -o -iname "*.vscdb" \))
    done

    if [[ $db_count -eq 0 ]]; then
        log_warning "Veritabanı dosyası bulunamadı"
    else
        log_success "$db_count veritabanı temizlendi"
    fi
}

main

