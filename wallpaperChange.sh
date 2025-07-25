#!/bin/bash
# -----------------------------------------------------------
#  wallpaper-setter.sh - 壁纸设置工具
#  用法:
#    ./wallpaper-setter.sh /path/to/source.webp  # 设置新壁纸
#    ./wallpaper-setter.sh -r|--restore         # 恢复备份
# -----------------------------------------------------------

set -euo pipefail

#############################
# 1. 基础配置（可调）
#############################
target_dir="/usr/trim/www/static/bg"
thumbnail_dir="/usr/trim/www/static/thumbnail_bg"
target_file="wallpaper-1.webp"
backup_file="${target_file}.bak"
sync_delay=0.2

# 可能的 chattr 路径列表（按优先级）
chattr_candidates=("/usr/bin/chattr" "/usr/bin/chattrx")

# 动态决定最终要用的 chattr 绝对路径
CHATTR_BIN=""
for c in "${chattr_candidates[@]}"; do
    [[ -x "$c" ]] && { CHATTR_BIN="$c"; break; }
done
[[ -n "$CHATTR_BIN" ]] || die "找不到可用的 chattr/chattrx 可执行文件！"

#############################
# 2. 工具函数
#############################
die() { echo -e "$*" >&2; exit 1; }

# 检查命令是否存在
check_command() {
  command -v "$1" &>/dev/null
}

# 重命名 chattr 为 chattrx
rename_chattr() {
  [[ "$CHATTR_BIN" == "/usr/bin/chattr" ]] || return 0
  sudo mv "/usr/bin/chattr" "/usr/bin/chattrx"
  CHATTR_BIN="/usr/bin/chattrx"
}

# 还原 chattrx 为 chattr
restore_chattr() {
  [[ "$CHATTR_BIN" == "/usr/bin/chattrx" ]] || return 0
  sudo mv "/usr/bin/chattrx" "/usr/bin/chattr"
  CHATTR_BIN="/usr/bin/chattr"
}

remove_attrAI() {
  for f in \
    "${target_dir}/${target_file}" \
    "${thumbnail_dir}/${target_file}" \
    "${target_dir}/${backup_file}" \
    "${thumbnail_dir}/${backup_file}"
  do
    sudo "$CHATTR_BIN" -ai "$f" 2>/dev/null || true
  done
}

add_attrAI() {
  for f in \
    "${target_dir}/${target_file}" \
    "${thumbnail_dir}/${target_file}" \
    "${target_dir}/${backup_file}" \
    "${thumbnail_dir}/${backup_file}"
  do
    sudo "$CHATTR_BIN" +ai "$f" 2>/dev/null || true
  done
}

# 安全复制文件
safe_cp() {
  local src=$1 dst=$2
  if [[ -f "$src" ]]; then
    sudo cp "$src" "$dst"
    sudo chmod 644 "$dst"
    sync && sleep "$sync_delay"
    return 0
  else
    die "源文件不存在: $src"
  fi
}

# 通用逻辑：对一个目录执行"备份->替换->生成缩略图"
process_dir() {
  local dir=$1
  local src_img=$2          # 仅 replace 时用到
  local mode=$3             # "create_backup" | "restore" | "replace"

  local full_target="${dir}/${target_file}"
  local full_backup="${dir}/${backup_file}"

  case $mode in
    create_backup)
      [[ -f "$full_backup" ]] && return 0
      [[ -f "$full_target" ]] || die "目标文件 $full_target 不存在！"
      echo "备份 $full_target -> $full_backup"
      safe_cp "$full_target" "$full_backup"
      ;;
    replace)
      echo "替换 $full_target"
      safe_cp "$src_img" "$full_target"
      if [[ $dir == "$thumbnail_dir" ]] && check_command convert; then
        echo "生成缩略图 $full_target"
        {
          sudo convert "$src_img" -resize 350x "$full_target"
          sudo chmod 644 "$full_target"
          sync && sleep "$sync_delay"
        }
      fi
      ;;
    restore)
      [[ -f "$full_backup" ]] || die "备份文件 $full_backup 不存在！"
      echo "恢复 $full_backup -> $full_target"
      {
        sudo rm -f "$full_target"
        safe_cp "$full_backup" "$full_target"
        sudo rm -f "$full_backup"
      }
      ;;
  esac
}

# 检查并安装依赖
install_dependencies() {
  if ! check_command convert; then
    echo "需要安装 ImageMagick..."
    if check_command apt-get; then
      sudo apt-get install -y imagemagick
    elif check_command brew; then
      brew install imagemagick
    else
      die "无法安装 ImageMagick，请手动安装后再运行"
    fi
  fi
}

# 检查 nginx 服务
manage_nginx() {
  local action=$1
  if check_command systemctl; then
    sudo systemctl $action trim_nginx 2>/dev/null || sudo systemctl $action nginx 2>/dev/null || true
  elif check_command service; then
    sudo service trim_nginx $action 2>/dev/null || sudo service nginx $action 2>/dev/null || true
  fi
}

#############################
# 3. 主流程
#############################
main() {
  # 3.1 检查依赖
  install_dependencies

  # 3.2 检查目录
  for d in "$target_dir" "$thumbnail_dir"; do
    [[ -d "$d" ]] || die "目录不存在: $d"
  done

  # 3.3 处理参数
  case "${1:-}" in
    -r|--restore)
      restore_chattr
      remove_attrAI
      
      for d in "$target_dir" "$thumbnail_dir"; do
        process_dir "$d" "" "restore"
      done
      echo "已恢复备份。"
      ;;
    "")
      die "用法: $0 [-r|--restore] 或 $0 /path/to/source.webp"
      ;;
    *)
      rename_chattr
      remove_attrAI
      [[ -f "$1" ]] || die "源文件不存在: $1"
      src_img=$1
      manage_nginx stop
      for d in "$target_dir" "$thumbnail_dir"; do
        process_dir "$d" "" "create_backup"
        process_dir "$d" "$src_img" "replace"
      done
      echo "壁纸及缩略图已全部更新！"
      add_attrAI
      manage_nginx start
      ;;
  esac
}

main "$@"
