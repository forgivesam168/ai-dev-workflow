#!/usr/bin/env bash
# Bootstrap AI Workflow Installer - Bash Version
# 
# This script initializes the AI development workflow into the current project.
# It provides cross-platform support for Linux and macOS environments.
#
# Usage:
#   ./bootstrap.sh                # Standard initialization
#   ./bootstrap.sh --force        # Force overwrite existing files
#   ./bootstrap.sh --update       # Refresh workflow files (includes backup)
#   ./bootstrap.sh --backup       # Create backup before syncing
#   ./bootstrap.sh --verbose      # Verbose output

set -e  # Exit on error

# Version requirements
MIN_GIT="2.0.0"
MIN_PYTHON="3.7.0"
MIN_BASH="4.0.0"
MIN_NODE="16.0.0"

# Exclude patterns for file sync
EXCLUDE_PATTERNS=("workflows" "CODEOWNERS" "dependabot.yml")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parameters
FORCE_MODE=0
BACKUP_MODE=0
UPDATE_MODE=0
VERBOSE_MODE=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_MODE=1
            shift
            ;;
        --backup)
            BACKUP_MODE=1
            shift
            ;;
        --update)
            UPDATE_MODE=1
            FORCE_MODE=1
            BACKUP_MODE=1
            shift
            ;;
        --verbose)
            VERBOSE_MODE=1
            shift
            ;;
        -h|--help)
            echo "Bootstrap AI Workflow Installer"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force       Force overwrite existing workflow files"
            echo "  --update      Refresh workflow files (includes backup)"
            echo "  --backup      Create backup before syncing"
            echo "  --verbose     Verbose output"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Utility functions
log_verbose() {
    if [ $VERBOSE_MODE -eq 1 ]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# Version comparison function
version_ge() {
    # Returns 0 (success) if $1 >= $2, 1 otherwise
    local ver1=$1
    local ver2=$2
    
    # Use sort -V for version comparison
    if [ "$(printf '%s\n' "$ver2" "$ver1" | sort -V | head -n1)" = "$ver2" ]; then
        return 0
    else
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Extract version from string
extract_version() {
    local text=$1
    local pattern=$2
    echo "$text" | grep -oE "$pattern" | head -n1 || echo ""
}

# Check Git installation
check_git() {
    log_verbose "Checking Git installation..."
    
    if ! command_exists git; then
        log_error "Git 未安裝"
        echo "   請安裝: https://git-scm.com/downloads"
        return 1
    fi
    
    local git_version=$(git --version)
    local version=$(extract_version "$git_version" '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -z "$version" ]; then
        log_warning "無法解析 Git 版本"
        return 1
    fi
    
    if version_ge "$version" "$MIN_GIT"; then
        log_success "Git $version detected"
    else
        log_warning "Git $version (建議 >= $MIN_GIT)"
    fi
    
    return 0
}

# Check Python installation
check_python() {
    log_verbose "Checking Python installation..."
    
    if ! command_exists python3 && ! command_exists python; then
        log_info "Python 未安裝（可選）"
        echo "   安裝: https://www.python.org/downloads/"
        return 0
    fi
    
    local python_cmd="python3"
    if ! command_exists python3; then
        python_cmd="python"
    fi
    
    local python_version=$($python_cmd --version 2>&1)
    local version=$(extract_version "$python_version" '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -n "$version" ]; then
        if version_ge "$version" "$MIN_PYTHON"; then
            log_success "Python $version detected"
        else
            log_warning "Python $version (建議 >= $MIN_PYTHON)"
        fi
    fi
    
    return 0
}

# Check Bash version
check_bash() {
    log_verbose "Checking Bash version..."
    
    local bash_version="${BASH_VERSION%%.*}"
    local full_version="${BASH_VERSION%(*}"
    
    if version_ge "$bash_version" "4"; then
        log_success "Bash $full_version detected"
    else
        log_warning "Bash $full_version (建議 >= 4.0)"
    fi
    
    return 0
}

# Check Node.js installation
check_node() {
    log_verbose "Checking Node.js installation..."
    
    if ! command_exists node; then
        log_info "Node.js 未安裝（可選）"
        echo "   安裝: https://nodejs.org"
        return 0
    fi
    
    local node_version=$(node --version 2>&1)
    local version=$(extract_version "$node_version" '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -n "$version" ]; then
        if version_ge "$version" "$MIN_NODE"; then
            log_success "Node.js $version detected"
        else
            log_warning "Node.js $version (建議 >= $MIN_NODE)"
        fi
    fi
    
    return 0
}

# Check GitHub CLI installation
check_gh() {
    log_verbose "Checking GitHub CLI installation..."
    
    if ! command_exists gh; then
        log_info "GitHub CLI 未安裝（可選）"
        echo "   安裝: https://cli.github.com/"
        return 0
    fi
    
    local gh_version=$(gh --version 2>&1 | head -n1)
    local version=$(extract_version "$gh_version" '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -n "$version" ]; then
        log_success "GitHub CLI $version detected"
    fi
    
    return 0
}

# Calculate SHA256 hash of file
file_hash() {
    local file=$1
    
    if command_exists sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    elif command_exists shasum; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        # Fallback: compare file sizes
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    fi
}

# Check if two files are identical
files_identical() {
    local file1=$1
    local file2=$2
    
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 1
    fi
    
    local hash1=$(file_hash "$file1")
    local hash2=$(file_hash "$file2")
    
    [ "$hash1" = "$hash2" ]
}

# Create backup directory
backup_directory() {
    local source=$1
    
    if [ ! -d "$source" ]; then
        log_error "Source directory not found: $source"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="${source}.backup-${timestamp}"
    
    log_verbose "Creating backup: $backup_name"
    
    if cp -r "$source" "$backup_name" 2>/dev/null; then
        log_success "Backup created: $backup_name"
        return 0
    else
        log_error "Backup failed"
        return 1
    fi
}

# Check for uncommitted Git changes
check_uncommitted_changes() {
    local target_root=$1
    local directory=$2
    
    if [ ! -d "$target_root/.git" ]; then
        return 1
    fi
    
    cd "$target_root"
    local status=$(git status --porcelain "$directory" 2>/dev/null)
    cd - > /dev/null
    
    [ -n "$status" ]
}

# Sync workflow files
sync_workflow_files() {
    local source=$1
    local target_root=$2
    local force=$3
    local backup=$4
    
    log_verbose "Syncing workflow files from $source to $target_root"
    
    if [ ! -d "$source" ]; then
        log_error "Source path not found: $source"
        return 1
    fi
    
    mkdir -p "$target_root"
    local target_github="$target_root/.github"
    
    # Create backup if requested and target exists
    if [ $backup -eq 1 ] && [ -d "$target_github" ]; then
        backup_directory "$target_github"
    fi
    
    mkdir -p "$target_github"
    
    local files_added=0
    local files_updated=0
    local files_skipped=0
    local files_conflicted=0
    
    # Sync files
    while IFS= read -r -d '' source_file; do
        local relative_path="${source_file#$source/}"
        
        # Check exclude patterns
        local should_exclude=0
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$relative_path" == *"$pattern"* ]]; then
                should_exclude=1
                ((files_skipped++))
                log_verbose "Skipped (excluded): $relative_path"
                break
            fi
        done
        
        if [ $should_exclude -eq 1 ]; then
            continue
        fi
        
        local dest_file="$target_github/$relative_path"
        local dest_dir=$(dirname "$dest_file")
        
        mkdir -p "$dest_dir"
        
        if [ -f "$dest_file" ]; then
            # File exists, check if identical
            if files_identical "$source_file" "$dest_file"; then
                ((files_skipped++))
                log_verbose "Skipped (identical): $relative_path"
            elif [ $force -eq 1 ]; then
                cp "$source_file" "$dest_file"
                ((files_updated++))
                log_verbose "Updated: $relative_path"
            else
                ((files_conflicted++))
                log_verbose "Conflict: $relative_path"
            fi
        else
            cp "$source_file" "$dest_file"
            ((files_added++))
            log_verbose "Added: $relative_path"
        fi
    done < <(find "$source" -type f -print0)
    
    echo ""
    log_info "同步摘要:"
    echo "   新增: $files_added 個檔案"
    echo "   更新: $files_updated 個檔案"
    echo "   跳過: $files_skipped 個檔案"
    
    if [ $files_conflicted -gt 0 ]; then
        log_warning "偵測到 $files_conflicted 個衝突檔案（內容不同但未覆蓋）"
        echo "   提示：使用 --force 或 --update 參數強制覆蓋"
    fi
    
    return 0
}

# Initialize Git repository
initialize_git_repo() {
    local target_root=$1
    
    if [ -d "$target_root/.git" ]; then
        log_verbose "Git repository already exists"
        return 0
    fi
    
    log_info "初始化 Git repository..."
    
    cd "$target_root"
    if git init >/dev/null 2>&1; then
        log_success "Git repository 已初始化"
        echo ""
        echo "後續步驟:"
        echo "  1. git add ."
        echo "  2. git commit -m 'chore: initialize AI workflow'"
    else
        log_error "Git 初始化失敗"
        return 1
    fi
    cd - > /dev/null
    
    return 0
}

# Main function
main() {
    echo -e "${GREEN}🚀 Bootstrap AI Workflow Installer${NC}"
    echo ""
    
    if [ $UPDATE_MODE -eq 1 ] && [ $FORCE_MODE -eq 1 ]; then
        log_info "Running --update mode (will check for conflicts and create backup)."
        echo ""
    fi
    
    # Determine paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root="$(cd "$script_dir/.." && pwd)"
    local current_path="$(pwd)"
    
    # Detect if running from installed location (check for .github in parent)
    if [ ! -d "$repo_root/.github" ]; then
        # If not found, assume we're running in a project that used bootstrap
        # and the source is the current directory
        if [ -d "$current_path/.github" ]; then
            repo_root="$current_path"
        else
            log_error "❌ 找不到 .github 目錄。請確認："
            echo "   1. 從 ai-dev-workflow 專案根目錄執行此腳本"
            echo "   2. 或確保當前專案已有 .github/ 結構"
            exit 1
        fi
    fi
    
    local template_source="$repo_root/.github"
    
    # Environment checks
    echo "環境檢測:"
    
    if ! check_git; then
        echo ""
        log_error "Git is required but not found."
        echo "Please install Git and try again."
        exit 1
    fi
    
    check_python
    check_bash
    check_node
    check_gh
    echo ""
    
    # Check if running inside template repo
    if [ "$current_path" = "$repo_root" ]; then
        log_warning "警告：正在模板 repo 內執行 bootstrap"
        read -p "是否繼續（會複製到目前目錄）? (y/n): " response
        if [ "$response" != "y" ]; then
            echo "已取消。"
            exit 0
        fi
        echo ""
    fi
    
    # Check for uncommitted changes in update mode
    if [ $UPDATE_MODE -eq 1 ]; then
        if [ -d "$current_path/.github" ]; then
            if check_uncommitted_changes "$current_path" ".github"; then
                log_warning "檢測到 .github/ 有未提交的修改"
                read -p "是否繼續更新? (y/n): " continue_update
                if [ "$continue_update" != "y" ]; then
                    echo "取消更新"
                    exit 0
                fi
                echo ""
            fi
        fi
    fi
    
    # Sync workflow files
    log_info "同步工作流程檔案..."
    if sync_workflow_files "$template_source" "$current_path" $FORCE_MODE $BACKUP_MODE; then
        echo ""
        log_success "工作流程檔案同步完成"
    else
        echo ""
        log_error "檔案同步失敗"
        exit 1
    fi
    
    # Initialize Git repository if needed
    if [ ! -d "$current_path/.git" ]; then
        echo ""
        initialize_git_repo "$current_path"
    fi
    
    echo ""
    log_success "Bootstrap 完成！"
    echo ""
    echo "下一步："
    echo "  1. 查看同步的檔案: ls -la .github/"
    echo "  2. 提交變更: git add . && git commit -m 'chore: initialize AI workflow'"
    echo "  3. 開始開發: 參考 .github/WORKFLOW.md"
}

# Run main function
main
