# Windows 符号链接问题排查指南

## 问题描述

在 Windows 上运行 `cvm install` 时出现 "could not create symlink" 错误，即使已经启用了 Developer Mode。

## 快速诊断

### 步骤 1: 运行诊断脚本

将以下代码保存为 `test-symlink.ps1` 或直接在 PowerShell 中运行：

```powershell
# ============================================================================
# Windows 符号链接诊断脚本
# ============================================================================

Write-Host "=== Windows Symlink Diagnostic Tool ===" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 Windows 版本
Write-Host "1. Checking Windows version..." -ForegroundColor Yellow
$osVersion = [System.Environment]::OSVersion.Version
Write-Host "   Windows Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)"

if ($osVersion.Major -lt 10) {
    Write-Host "   ✗ Windows 10+ required for Developer Mode" -ForegroundColor Red
    exit 1
} else {
    Write-Host "   ✓ Windows version compatible" -ForegroundColor Green
}
Write-Host ""

# 2. 检查 Developer Mode 状态
Write-Host "2. Checking Developer Mode status..." -ForegroundColor Yellow
try {
    $devMode = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction Stop).AllowDevelopmentWithoutDevLicense

    if ($devMode -eq 1) {
        Write-Host "   ✓ Developer Mode is ENABLED" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Developer Mode is DISABLED" -ForegroundColor Red
        Write-Host "   Please enable it in Settings > Update & Security > For developers"
    }
} catch {
    Write-Host "   ✗ Developer Mode registry key not found" -ForegroundColor Red
    Write-Host "   Developer Mode may not be enabled"
}
Write-Host ""

# 3. 检查 PowerShell 执行权限
Write-Host "3. Checking PowerShell execution context..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "   ℹ Running as Administrator" -ForegroundColor Cyan
} else {
    Write-Host "   ℹ Running as regular user (this is OK if Developer Mode is enabled)" -ForegroundColor Cyan
}
Write-Host ""

# 4. 测试符号链接创建（文件）
Write-Host "4. Testing symbolic link creation (file)..." -ForegroundColor Yellow
$testDir = Join-Path $env:TEMP "cvm-symlink-test-$(Get-Random)"
$testFile = Join-Path $testDir "test.txt"
$testLink = Join-Path $testDir "test-link.txt"

try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    "test content" | Out-File -FilePath $testFile -Encoding UTF8

    New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null

    $linkContent = Get-Content $testLink -Raw
    if ($linkContent -match "test content") {
        Write-Host "   ✓ File symlink creation SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "   ✗ File symlink created but content wrong" -ForegroundColor Red
    }

    Remove-Item -Path $testDir -Recurse -Force
} catch {
    Write-Host "   ✗ File symlink creation FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""

# 5. 测试符号链接创建（目录）
Write-Host "5. Testing symbolic link creation (directory)..." -ForegroundColor Yellow
$testDir = Join-Path $env:TEMP "cvm-symlink-test-$(Get-Random)"
$targetDir = Join-Path $testDir "target"
$linkDir = Join-Path $testDir "link"

try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    "test" | Out-File -FilePath (Join-Path $targetDir "file.txt")

    New-Item -ItemType SymbolicLink -Path $linkDir -Target $targetDir -ErrorAction Stop | Out-Null

    if (Test-Path (Join-Path $linkDir "file.txt")) {
        Write-Host "   ✓ Directory symlink creation SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Directory symlink created but files not accessible" -ForegroundColor Red
    }

    Remove-Item -Path $testDir -Recurse -Force
} catch {
    Write-Host "   ✗ Directory symlink creation FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""

# 6. 检查 SeCreateSymbolicLinkPrivilege 权限
Write-Host "6. Checking symbolic link privilege..." -ForegroundColor Yellow
try {
    $whoamiOutput = whoami /priv | Select-String "SeCreateSymbolicLinkPrivilege"
    if ($whoamiOutput) {
        Write-Host "   ✓ SeCreateSymbolicLinkPrivilege found" -ForegroundColor Green
        Write-Host "   $whoamiOutput"
    } else {
        Write-Host "   ✗ SeCreateSymbolicLinkPrivilege NOT found" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠ Could not check privileges" -ForegroundColor Yellow
}
Write-Host ""

# 7. 检查 npm 和 node 版本
Write-Host "7. Checking Node.js and npm..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null

    if ($nodeVersion) {
        Write-Host "   ✓ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Node.js not found" -ForegroundColor Red
    }

    if ($npmVersion) {
        Write-Host "   ✓ npm: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "   ✗ npm not found" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Node.js/npm check failed" -ForegroundColor Red
}
Write-Host ""

# 总结和建议
Write-Host "=== Diagnostic Summary ===" -ForegroundColor Cyan
Write-Host ""

if ($devMode -ne 1) {
    Write-Host "⚠ ACTION REQUIRED: Enable Developer Mode" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Method 1 - Via Settings UI:" -ForegroundColor Cyan
    Write-Host "  1. Open Settings (Win + I)"
    Write-Host "  2. Go to 'Update & Security' > 'For developers'"
    Write-Host "  3. Toggle 'Developer mode' to ON"
    Write-Host "  4. Restart your computer"
    Write-Host ""
    Write-Host "Method 2 - Via Registry (Run as Administrator):" -ForegroundColor Cyan
    Write-Host '  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f'
    Write-Host ""
} else {
    Write-Host "Developer Mode is enabled. If symlink creation still fails:" -ForegroundColor Cyan
    Write-Host "  1. Restart your computer (changes may require reboot)"
    Write-Host "  2. Try running PowerShell as Administrator"
    Write-Host "  3. Check if antivirus/security software is blocking symlinks"
    Write-Host "  4. Try the alternative hardlink method (see below)"
    Write-Host ""
}

Write-Host "For more help, visit: https://github.com/kimmykuang/cvm/blob/main/docs/WINDOWS.md" -ForegroundColor Cyan
```

### 步骤 2: 保存并运行

```powershell
# 保存上面的脚本到文件
notepad test-symlink.ps1

# 运行诊断
.\test-symlink.ps1
```

## 常见原因和解决方案

### 原因 1: Developer Mode 未真正生效

**症状**: 注册表显示已启用，但符号链接仍然失败

**解决方案**:
```powershell
# 1. 重启计算机（最重要！）
# Developer Mode 的更改需要重启才能生效

# 2. 重启后验证
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock").AllowDevelopmentWithoutDevLicense

# 3. 再次测试符号链接
$test = Join-Path $env:TEMP "test.txt"
"test" | Out-File $test
New-Item -ItemType SymbolicLink -Path "$test-link" -Target $test
```

### 原因 2: 本地安全策略限制

**症状**: Developer Mode 已启用且重启，但仍然失败

**解决方案**:

1. 以**管理员身份**打开 PowerShell
2. 运行本地安全策略编辑器:

```powershell
# 方法 1: 通过 GUI
secpol.msc
# 导航到: 本地策略 > 用户权限分配 > 创建符号链接
# 添加你的用户账户

# 方法 2: 通过命令（管理员）
# 查看当前有权限的用户
whoami /priv | Select-String "SeCreateSymbolicLinkPrivilege"
```

### 原因 3: 企业/组织策略限制

**症状**: 公司电脑，即使管理员也无法启用

**解决方案**: 联系 IT 部门，或使用以下替代方案

### 原因 4: npm 特定问题

**症状**: PowerShell 测试通过，但 npm install 时失败

**解决方案**:

```powershell
# 1. 清理 npm 缓存
npm cache clean --force

# 2. 配置 npm 不使用符号链接
npm config set legacy-peer-deps true

# 3. 或者以管理员身份运行
# 右键 PowerShell > 以管理员身份运行
npm install
```

### 原因 5: 杀毒软件/安全软件干扰

**症状**: 测试时断断续续成功/失败

**解决方案**:
- 临时禁用杀毒软件（Windows Defender、卡巴斯基、360等）
- 将 cvm 目录添加到白名单
- 将 PowerShell 添加到白名单

## 替代方案：使用硬链接（Hardlink）

如果符号链接实在无法使用，我们可以修改 cvm.ps1 使用硬链接作为 fallback：

```powershell
# 创建一个临时的修复版本
# 在 cvm.ps1 的 Invoke-CvmUse 函数中，将符号链接部分替换为：

try {
    if (Test-Path $claudeLink) {
        Remove-Item $claudeLink -Force
    }

    New-Item -ItemType Directory -Path $script:CVM_BIN_DIR -Force | Out-Null

    # 先尝试符号链接
    try {
        New-Item -ItemType SymbolicLink -Path $claudeLink -Target $claudeTarget -Force -ErrorAction Stop | Out-Null
        Write-Host "   Using symbolic link"
    }
    catch {
        # Fallback: 使用硬链接
        Write-CvmWarn "Symbolic link failed, using hardlink as fallback"
        New-Item -ItemType HardLink -Path $claudeLink -Target $claudeTarget -Force | Out-Null
    }

    Write-CvmEcho "Now using Claude CLI version $Version"
    return 0
}
catch {
    # 错误处理...
}
```

## 手动验证步骤

如果诊断脚本无法运行，手动验证：

```powershell
# 1. 检查 Windows 版本
winver  # 应该是 Windows 10 1607+ 或 Windows 11

# 2. 检查 Developer Mode
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" | Select-Object AllowDevelopmentWithoutDevLicense

# 3. 手动测试符号链接
$test = "C:\Temp\test.txt"
"test" | Out-File $test
New-Item -ItemType SymbolicLink -Path "C:\Temp\test-link.txt" -Target $test

# 4. 验证链接
Get-Item "C:\Temp\test-link.txt" | Select-Object Target
Get-Content "C:\Temp\test-link.txt"

# 5. 清理
Remove-Item "C:\Temp\test*"
```

## 获取详细错误信息

运行 cvm install 时获取完整错误：

```powershell
# 开启详细错误输出
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'

# 运行安装
cvm install 2.1.71

# 查看完整错误
$Error[0] | Format-List -Force
```

## 需要提供的诊断信息

如果问题仍未解决，请提供：

```powershell
# 收集系统信息
@{
    "Windows Version" = [System.Environment]::OSVersion.Version
    "PowerShell Version" = $PSVersionTable.PSVersion
    "Developer Mode" = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    "Is Admin" = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    "Node Version" = (node --version 2>$null)
    "npm Version" = (npm --version 2>$null)
} | Format-Table -AutoSize

# 符号链接测试结果
# 完整的错误消息
# 是否在企业/学校环境
```

## 快速修复检查清单

- [ ] 已启用 Developer Mode（Settings UI 或注册表）
- [ ] **已重启计算机**（这是最常被忽略的步骤！）
- [ ] 重新打开 PowerShell
- [ ] 运行 `.\test-symlink.ps1` 诊断脚本
- [ ] 所有符号链接测试通过
- [ ] 以管理员身份尝试（如果常规用户失败）
- [ ] 关闭杀毒软件后尝试
- [ ] npm 缓存已清理
- [ ] 咨询 IT 部门（企业环境）

## 最终方案

如果所有方法都失败，临时的工作方案：

```powershell
# 1. 手动创建符号链接（以管理员身份）
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.cvm\bin\claude" -Target "$env:USERPROFILE\.cvm\versions\2.1.71\bin\claude" -Force

# 2. 或者创建一个 .cmd 包装脚本
@"
@echo off
node "%USERPROFILE%\.cvm\versions\2.1.71\node_modules\@anthropic-ai\claude-code\cli.js" %*
"@ | Out-File -FilePath "$env:USERPROFILE\.cvm\bin\claude.cmd" -Encoding ASCII

# 3. 确保 .cmd 在 PATH 中
# 这样 'claude' 命令就能工作了
```

记住：**重启计算机是最重要的步骤**，很多 Developer Mode 问题都是因为没有重启！
