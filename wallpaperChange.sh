#!/bin/bash

# 启用严格错误检查
set -euo pipefail

# 定义路径变量
TARGET_DIR="/usr/trim/www/static/bg"
THUMBNAIL_DIR="/usr/trim/www/static/thumbnail_bg"
TARGET_FILE="wallpaper-1.webp"
BACKUP_FILE="${TARGET_FILE}.bak"
FULL_TARGET="${TARGET_DIR}/${TARGET_FILE}"
FULL_BACKUP="${TARGET_DIR}/${BACKUP_FILE}"
FULL_THUMBNAIL="${THUMBNAIL_DIR}/${TARGET_FILE}"
FULL_THUMBNAIL_BACKUP="${THUMBNAIL_DIR}/${BACKUP_FILE}"

# 检查并安装ImageMagick
check_imagemagick() {
    if ! command -v convert &>/dev/null; then
        echo "ImageMagick未安装，正在安装..."
        sudo apt-get install -y imagemagick || {
            echo "错误：ImageMagick安装失败！" >&2
            exit 1
        }
        echo "ImageMagick安装成功！"
    fi
}

# 解除目录锁定（允许修改）
unlock_directory() {
    sudo chattr -a -i -R "$TARGET_DIR" 2>/dev/null || echo "警告：目录未锁定或解锁失败！" >&2
    sudo chattr -a -i -R "$THUMBNAIL_DIR" 2>/dev/null || echo "警告：缩略图目录未锁定或解锁失败！" >&2
}

# 锁定目录（禁止修改）
lock_directory() {
    sudo chattr +a +i -R "$TARGET_DIR" || {
        echo "错误：目录锁定失败！" >&2
        exit 1
    }
    sudo chattr +a +i -R "$THUMBNAIL_DIR" || {
        echo "错误：缩略图目录锁定失败！" >&2
        exit 1
    }
}

# 检查目标目录是否存在
check_directory() {
    if [ ! -d "$TARGET_DIR" ]; then
        echo "错误：目标目录 $TARGET_DIR 不存在！" >&2
        exit 1
    fi
}

# 备份原始文件和缩略图
create_backup() {
    unlock_directory
    
    # 备份原始大图
    if [ ! -f "$FULL_BACKUP" ]; then
        echo "创建备份文件..."
        sudo cp "$FULL_TARGET" "$FULL_BACKUP" || {
            echo "备份失败！" >&2
            exit 1
        }
        sudo chmod 644 "$FULL_BACKUP"
    fi
    
    # 备份缩略图
    if [ -f "$FULL_THUMBNAIL" ]; then
        echo "创建缩略图备份..."
        sudo cp "$FULL_THUMBNAIL" "$FULL_THUMBNAIL_BACKUP" || {
            echo "缩略图备份失败！" >&2
            exit 1
        }
        sudo chmod 644 "$FULL_THUMBNAIL_BACKUP"
    fi
    
    lock_directory
}

# 替换图片并生成缩略图
replace_image() {
    local source_img="$1"
    [ -f "$source_img" ] || {
        echo "错误：源文件 $source_img 不存在！" >&2
        exit 1
    }

    unlock_directory
    echo "替换图片..."
    sudo cp "$source_img" "$FULL_TARGET" || {
        echo "图片替换失败！" >&2
        exit 1
    }
    sudo chmod 644 "$FULL_TARGET"
    
    echo "生成缩略图..."
    sudo convert "$source_img" -resize 350x "$FULL_THUMBNAIL" || {
        echo "缩略图生成失败！" >&2
        exit 1
    }
    sudo chmod 644 "$FULL_THUMBNAIL"
    
    lock_directory
    echo "图片和缩略图替换完成！"
}

# 恢复备份
restore_backup() {
    unlock_directory
    if [ -f "$FULL_BACKUP" ]; then
        echo "从备份恢复..."
        sudo rm -f "$FULL_TARGET" 2>/dev/null
        sudo cp "$FULL_BACKUP" "$FULL_TARGET" || {
            echo "恢复失败！" >&2
            exit 1
        }
        sudo chmod 644 "$FULL_TARGET"
        
        # 恢复缩略图备份
        if [ -f "$FULL_THUMBNAIL_BACKUP" ]; then
            echo "恢复缩略图备份..."
            sudo rm -f "$FULL_THUMBNAIL" 2>/dev/null
            sudo cp "$FULL_THUMBNAIL_BACKUP" "$FULL_THUMBNAIL" || {
                echo "缩略图恢复失败！" >&2
                exit 1
            }
            sudo chmod 644 "$FULL_THUMBNAIL"
            sudo rm -f "$FULL_THUMBNAIL_BACKUP"
        fi
        
        sudo rm -f "$FULL_BACKUP"
        echo "恢复完成，备份文件已删除！"
    else
        echo "错误：备份文件不存在！" >&2
        exit 1
    fi
}

# 主函数
main() {
    check_imagemagick
    check_directory

    case "${1:-}" in
        -r|--restore)
            restore_backup
            ;;
        "")
            echo "用法: $0 [-r|--restore] 或 $0 /path/to/source/image.webp！" >&2
            exit 1
            ;;
        *)
            create_backup
            replace_image "$1"
            ;;
    esac
}

main "$@"
