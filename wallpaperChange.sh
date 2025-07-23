#!/bin/bash

# 启用严格错误检查
set -euo pipefail

# 定义路径变量
TARGET_DIR="/usr/trim/www/static/bg"
TARGET_FILE="wallpaper-1.webp"
BACKUP_FILE="${TARGET_FILE}.bak"
FULL_TARGET="${TARGET_DIR}/${TARGET_FILE}"
FULL_BACKUP="${TARGET_DIR}/${BACKUP_FILE}"

# 解除目录锁定（允许修改）
unlock_directory() {
    sudo chattr -a -i -R "$TARGET_DIR" 2>/dev/null || echo "警告：目录未锁定或解锁失败" >&2
}

# 锁定目录（禁止修改）
lock_directory() {
    sudo chattr +a +i -R "$TARGET_DIR" || {
        echo "错误：目录锁定失败" >&2
        exit 1
    }
}

# 检查目标目录是否存在
check_directory() {
    if [ ! -d "$TARGET_DIR" ]; then
        echo "错误：目标目录 $TARGET_DIR 不存在" >&2
        exit 1
    fi
}

# 备份原始文件
create_backup() {
    if [ ! -f "$FULL_BACKUP" ]; then
        unlock_directory
        echo "创建备份文件..."
        sudo cp "$FULL_TARGET" "$FULL_BACKUP" || {
            echo "备份失败" >&2
            exit 1
        }
        sudo chmod 644 "$FULL_BACKUP"
        lock_directory
    fi
}

# 替换图片
replace_image() {
    local source_img="$1"
    [ -f "$source_img" ] || {
        echo "错误：源文件 $source_img 不存在" >&2
        exit 1
    }

    unlock_directory
    echo "替换图片..."
    sudo cp "$source_img" "$FULL_TARGET" || {
        echo "图片替换失败" >&2
        exit 1
    }
    sudo chmod 644 "$FULL_TARGET"
    lock_directory
    echo "图片替换成功"
}

# 恢复备份
restore_backup() {
    unlock_directory
    if [ -f "$FULL_BACKUP" ]; then
        echo "从备份恢复..."
        sudo rm -f "$FULL_TARGET" 2>/dev/null
        sudo cp "$FULL_BACKUP" "$FULL_TARGET" || {
            echo "恢复失败" >&2
            exit 1
        }
        sudo chmod 644 "$FULL_TARGET"
        sudo rm -f "$FULL_BACKUP"
        echo "恢复完成，备份文件已删除"
    else
        echo "错误：备份文件不存在" >&2
        exit 1
    fi
}

# 主函数
main() {
    check_directory

    case "${1:-}" in
        -r|--restore)
            restore_backup
            ;;
        "")
            echo "用法: $0 [-r|--restore] 或 $0 /path/to/source/image.webp" >&2
            exit 1
            ;;
        *)
            create_backup
            replace_image "$1"
            ;;
    esac
}

main "$@"
