# cvm Real-World Testing Plan

> **目的：** 验证 cvm 在真实环境中的完整安装和使用流程

**版本：** v1.0.0
**测试日期：** 2026-03-15
**GitHub 仓库：** https://github.com/kimmykuang/cvm

---

## 📋 测试目标

验证以下功能在真实环境中正常工作：

- ✅ 从 GitHub 安装 cvm
- ✅ 使用 cvm 管理多个 Claude CLI 版本
- ✅ 版本切换功能
- ✅ 别名管理功能
- ✅ 与 cc-switch 的集成
- ✅ 错误处理和用户提示
- ✅ 数据持久化（配置在版本切换后保留）

---

## 🧪 测试环境

- **操作系统：** macOS (Darwin 23.6.0)
- **Shell：** zsh
- **必需工具：**
  - git (必需)
  - npm (必需，用于安装 Claude CLI)
  - curl (必需，用于下载安装脚本)

---

## 📝 测试准备

### 清理现有环境（可选）

如果之前有测试安装，建议先清理：

```bash
# 备份现有配置（如果需要）
mv ~/.cvm ~/.cvm.backup
mv ~/.cvm-repo ~/.cvm-repo.backup

# 从 shell 配置中移除 cvm（编辑 ~/.zshrc，删除 cvm 相关行）
# 然后重新加载
source ~/.zshrc
```

---

## 🚀 测试步骤

## 第一部分：安装测试

### Test 1.1: 从 GitHub 安装 cvm

**执行命令：**
```bash
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash
```

**预期结果：**
- [ ] 显示安装横幅（`╔═══ cvm - Claude Version Manager ═══╗`）
- [ ] 检查 git 可用性（如果没有 git，应该报错退出）
- [ ] 检查 npm 可用性（如果没有 npm，应该警告但继续）
- [ ] 克隆仓库到 `~/.cvm-repo/`
- [ ] 创建目录结构：`~/.cvm/versions/`, `~/.cvm/bin/`, `~/.cvm/alias/`
- [ ] 检测 shell 类型（bash 或 zsh）
- [ ] 自动配置 `~/.zshrc`（添加 PATH 和 alias）
- [ ] 显示 "Installation Complete!" 消息
- [ ] 提示下一步操作

**验证命令：**
```bash
# 检查仓库
ls -la ~/.cvm-repo/

# 检查数据目录
ls -la ~/.cvm/

# 检查 shell 配置
grep cvm ~/.zshrc
```

**预期输出：**
```
# ~/.zshrc 应包含：
export PATH="$HOME/.cvm/bin:$PATH"
alias cvm="$HOME/.cvm-repo/cvm.sh"
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 1.2: 重启 shell 并验证 cvm 命令

**执行命令：**
```bash
exec $SHELL
cvm --version
cvm help
```

**预期结果：**
- [ ] `cvm --version` 显示 `cvm 1.0.0`
- [ ] `cvm help` 显示完整帮助信息
- [ ] 帮助信息包含所有命令（install, use, list, current, alias, unalias, uninstall）

**实际结果：**
```
[填写实际结果]
```

---

## 第二部分：版本管理测试

### Test 2.1: 安装 Claude CLI 版本

**执行命令：**
```bash
cvm install 2.1.71
```

**预期结果：**
- [ ] 显示 "Installing Claude CLI version 2.1.71..."
- [ ] 使用 npm 下载并安装（需要 1-3 分钟）
- [ ] 显示 "Successfully installed Claude CLI 2.1.71"
- [ ] 创建目录 `~/.cvm/versions/2.1.71/`
- [ ] 包含 `node_modules/` 和 `bin/claude` 符号链接

**验证命令：**
```bash
ls -la ~/.cvm/versions/2.1.71/
ls -la ~/.cvm/versions/2.1.71/bin/
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 2.2: 安装第二个版本

**执行命令：**
```bash
cvm install 2.1.63
```

**预期结果：**
- [ ] 成功安装版本 2.1.63
- [ ] 创建独立的目录 `~/.cvm/versions/2.1.63/`
- [ ] 两个版本独立共存

**验证命令：**
```bash
ls -la ~/.cvm/versions/
```

**预期输出：**
```
2.1.71/
2.1.63/
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 2.3: 切换到特定版本

**执行命令：**
```bash
cvm use 2.1.71
```

**预期结果：**
- [ ] 显示 "Now using Claude CLI version 2.1.71"
- [ ] 创建符号链接 `~/.cvm/bin/claude -> ../versions/2.1.71/bin/claude`
- [ ] 如果 `~/.cvm/bin` 不在 PATH 中，显示警告和配置提示

**验证命令：**
```bash
readlink ~/.cvm/bin/claude
claude --version
which claude
```

**预期输出：**
- `readlink` 输出包含 `2.1.71`
- `claude --version` 显示 `2.1.71 (Claude Code)`
- `which claude` 显示 `/Users/kuang/.cvm/bin/claude`

**实际结果：**
```
[填写实际结果]
```

---

### Test 2.4: 切换到另一个版本

**执行命令：**
```bash
cvm use 2.1.63
claude --version
```

**预期结果：**
- [ ] 成功切换到 2.1.63
- [ ] `claude --version` 显示 `2.1.63 (Claude Code)`

**实际结果：**
```
[填写实际结果]
```

---

### Test 2.5: 查看当前版本

**执行命令：**
```bash
cvm current
```

**预期结果：**
- [ ] 显示 "Current version: 2.1.63"
- [ ] 显示完整版本信息（包括 Claude CLI 的版本输出）

**实际结果：**
```
[填写实际结果]
```

---

### Test 2.6: 列出已安装版本

**执行命令：**
```bash
cvm list
```

**预期结果：**
- [ ] 显示 "Installed Claude CLI versions:"
- [ ] 列出两个版本：2.1.71 和 2.1.63
- [ ] 当前激活的版本有 `*` 标记和绿色显示
- [ ] 显示 "(currently active)" 标记

**预期输出示例：**
```
Installed Claude CLI versions:

    2.1.71
  * 2.1.63 (currently active)
```

**实际结果：**
```
[填写实际结果]
```

---

## 第三部分：别名管理测试

### Test 3.1: 创建别名

**执行命令：**
```bash
cvm alias provider-a 2.1.71
cvm alias provider-b 2.1.63
```

**预期结果：**
- [ ] 显示 "Created alias: provider-a -> 2.1.71"
- [ ] 显示 "Created alias: provider-b -> 2.1.63"
- [ ] 创建文件 `~/.cvm/alias/provider-a`（内容为 "2.1.71"）
- [ ] 创建文件 `~/.cvm/alias/provider-b`（内容为 "2.1.63"）

**验证命令：**
```bash
cat ~/.cvm/alias/provider-a
cat ~/.cvm/alias/provider-b
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 3.2: 使用别名切换版本

**执行命令：**
```bash
cvm use provider-a
```

**预期结果：**
- [ ] 显示 "Using alias 'provider-a' -> version 2.1.71"
- [ ] 显示 "Now using Claude CLI version 2.1.71"
- [ ] `claude --version` 显示 2.1.71

**验证命令：**
```bash
claude --version
cvm current
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 3.3: 查看别名列表

**执行命令：**
```bash
cvm list
```

**预期结果：**
- [ ] 在版本列表后显示 "Aliases:" 部分
- [ ] 列出所有别名：
  ```
  Aliases:
    provider-a -> 2.1.71
    provider-b -> 2.1.63
  ```

**实际结果：**
```
[填写实际结果]
```

---

### Test 3.4: 删除别名

**执行命令：**
```bash
cvm unalias provider-b
cvm list
```

**预期结果：**
- [ ] 显示 "Removed alias: provider-b"
- [ ] `cvm list` 不再显示 provider-b 别名
- [ ] 版本 2.1.63 仍然存在（只是别名被删除）

**实际结果：**
```
[填写实际结果]
```

---

## 第四部分：cc-switch 集成测试

### Test 4.1: 验证配置数据分离

**背景：** Claude CLI 的配置存储在 `~/.claude/`，与 cvm 安装的版本无关。

**执行命令：**
```bash
# 检查配置目录
ls -la ~/.claude/

# 检查配置文件
ls -la ~/.claude.json

# 切换版本
cvm use 2.1.71
cvm use 2.1.63
cvm use 2.1.71

# 再次检查配置
ls -la ~/.claude/
```

**预期结果：**
- [ ] `~/.claude/` 目录存在且不受版本切换影响
- [ ] 配置文件（`~/.claude.json`、`~/.claude/settings.json` 等）内容保持不变
- [ ] 历史记录（`~/.claude/history.jsonl`）保留
- [ ] 项目配置（`~/.claude/projects/`）保留
- [ ] 插件（`~/.claude/plugins/`）保留

**实际结果：**
```
[填写实际结果]
```

---

### Test 4.2: cc-switch 协同工作（如果安装了 cc-switch）

**执行命令：**
```bash
# 创建与 provider 对应的别名
cvm alias anthropic-official 2.1.63
cvm alias provider-restricted 2.1.71

# 切换到特定 provider 的版本
cvm use provider-restricted
# 然后使用 cc-switch 切换到对应的 provider

# 验证
which claude
readlink ~/.cvm/bin/claude
claude --version
```

**预期结果：**
- [ ] cvm 和 cc-switch 可以独立配置
- [ ] cvm 管理 CLI 版本，cc-switch 管理 provider URL
- [ ] 两者配合使用时，可以为不同 provider 使用不同 CLI 版本

**实际结果：**
```
[填写实际结果]
```

---

## 第五部分：错误处理测试

### Test 5.1: 无效版本格式

**执行命令：**
```bash
cvm install invalid-version
```

**预期结果：**
- [ ] 显示 "[cvm ERROR] Invalid version format: invalid-version"
- [ ] 显示 "Expected format: X.Y.Z (e.g., 2.1.71)"
- [ ] 命令返回非零退出码
- [ ] 不创建任何目录

**实际结果：**
```
[填写实际结果]
```

---

### Test 5.2: 使用未安装的版本

**执行命令：**
```bash
cvm use 9.9.9
```

**预期结果：**
- [ ] 显示 "[cvm ERROR] Version 9.9.9 is not installed"
- [ ] 显示 "Run 'cvm install 9.9.9' first"
- [ ] 当前激活的版本不受影响

**验证命令：**
```bash
cvm current
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 5.3: 删除不存在的别名

**执行命令：**
```bash
cvm unalias nonexistent-alias
```

**预期结果：**
- [ ] 显示 "[cvm ERROR] Alias 'nonexistent-alias' does not exist"

**实际结果：**
```
[填写实际结果]
```

---

### Test 5.4: 命令缺少参数

**执行命令：**
```bash
cvm install
cvm use
cvm alias
cvm unalias
cvm uninstall
```

**预期结果：**
- [ ] 每个命令显示相应的错误消息
- [ ] 显示正确的用法提示（Usage: ...）

**实际结果：**
```
[填写实际结果]
```

---

### Test 5.5: 未知命令

**执行命令：**
```bash
cvm unknown-command
```

**预期结果：**
- [ ] 显示 "[cvm ERROR] Unknown command: unknown-command"
- [ ] 显示完整的帮助信息

**实际结果：**
```
[填写实际结果]
```

---

## 第六部分：卸载测试

### Test 6.1: 卸载非激活版本

**执行命令：**
```bash
cvm use 2.1.71
cvm uninstall 2.1.63
```

**预期结果：**
- [ ] 直接删除版本（不需要确认）
- [ ] 显示 "Uninstalled Claude CLI version 2.1.63"
- [ ] 当前激活的版本（2.1.71）不受影响

**验证命令：**
```bash
ls -la ~/.cvm/versions/
cvm list
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 6.2: 卸载激活版本

**执行命令：**
```bash
cvm use 2.1.71
cvm uninstall 2.1.71
# 输入 'y' 确认
```

**预期结果：**
- [ ] 显示 "[cvm WARN] This is the currently active version"
- [ ] 提示 "Continue with uninstall? [y/N]"
- [ ] 输入 'y' 后继续删除
- [ ] 显示 "Deactivated version 2.1.71"
- [ ] 显示 "Uninstalled Claude CLI version 2.1.71"
- [ ] 删除符号链接 `~/.cvm/bin/claude`
- [ ] 删除版本目录

**验证命令：**
```bash
ls -la ~/.cvm/bin/
ls -la ~/.cvm/versions/
cvm current  # 应该显示 "No active Claude CLI version"
```

**实际结果：**
```
[填写实际结果]
```

---

### Test 6.3: 卸载时清理关联别名

**执行命令：**
```bash
# 重新安装和设置
cvm install 2.1.63
cvm alias test-alias 2.1.63
cvm uninstall 2.1.63
cvm list
```

**预期结果：**
- [ ] 卸载版本时显示 "[cvm WARN] Removed alias 'test-alias' (was pointing to 2.1.63)"
- [ ] `cvm list` 不再显示 test-alias

**实际结果：**
```
[填写实际结果]
```

---

## 第七部分：边缘场景测试

### Test 7.1: 重复安装相同版本

**执行命令：**
```bash
cvm install 2.1.71
cvm install 2.1.71
```

**预期结果：**
- [ ] 第二次安装显示 "[cvm WARN] Version 2.1.71 is already installed"
- [ ] 不重新下载或覆盖
- [ ] 命令成功返回（退出码 0）

**实际结果：**
```
[填写实际结果]
```

---

### Test 7.2: 创建同名别名（覆盖）

**执行命令：**
```bash
cvm install 2.1.71
cvm install 2.1.63
cvm alias test 2.1.71
cvm alias test 2.1.63
cat ~/.cvm/alias/test
```

**预期结果：**
- [ ] 第二次创建别名覆盖第一次
- [ ] `cat` 显示 "2.1.63"
- [ ] 没有错误或警告

**实际结果：**
```
[填写实际结果]
```

---

### Test 7.3: 空的 versions 目录

**执行命令：**
```bash
# 确保没有安装任何版本
cvm list
```

**预期结果：**
- [ ] 显示 "Installed Claude CLI versions:"
- [ ] 显示 "(none installed)"
- [ ] 显示 "Install a version with: cvm install <version>"

**实际结果：**
```
[填写实际结果]
```

---

### Test 7.4: 没有激活版本时的操作

**执行命令：**
```bash
cvm current
```

**预期结果：**
- [ ] 显示 "[cvm WARN] No active Claude CLI version"
- [ ] 显示 "Run 'cvm use <version>' to activate a version"
- [ ] 返回非零退出码

**实际结果：**
```
[填写实际结果]
```

---

## 📊 测试总结

### 测试统计

- **总测试数：** 28
- **通过：** ___ / 28
- **失败：** ___ / 28
- **跳过：** ___ / 28

### 关键功能状态

| 功能模块 | 状态 | 备注 |
|---------|------|------|
| 安装 | ⬜ 通过 / ⬜ 失败 | |
| 版本管理 | ⬜ 通过 / ⬜ 失败 | |
| 别名管理 | ⬜ 通过 / ⬜ 失败 | |
| cc-switch 集成 | ⬜ 通过 / ⬜ 失败 | |
| 错误处理 | ⬜ 通过 / ⬜ 失败 | |
| 卸载功能 | ⬜ 通过 / ⬜ 失败 | |
| 边缘场景 | ⬜ 通过 / ⬜ 失败 | |

---

## 🐛 问题记录

### 已发现问题

#### 问题 #1
- **测试编号：**
- **描述：**
- **严重程度：** 🔴 严重 / 🟡 一般 / 🟢 轻微
- **复现步骤：**
  1.
  2.
  3.
- **实际结果：**
- **预期结果：**
- **解决方案：**

#### 问题 #2
- **测试编号：**
- **描述：**
- **严重程度：** 🔴 严重 / 🟡 一般 / 🟢 轻微
- **复现步骤：**
- **实际结果：**
- **预期结果：**
- **解决方案：**

---

## ✅ 测试结论

### 是否通过发布标准？

⬜ **通过** - 所有关键功能正常，可以正式发布
⬜ **有保留通过** - 有轻微问题但不影响核心功能
⬜ **不通过** - 存在严重问题，需要修复后重新测试

### 测试人员签名

- **测试人：**
- **日期：**
- **环境：**

---

## 📚 附录

### A. 有用的调试命令

```bash
# 查看 cvm 目录结构
tree ~/.cvm -L 3

# 查看符号链接
ls -la ~/.cvm/bin/
readlink -f ~/.cvm/bin/claude

# 查看别名文件
ls -la ~/.cvm/alias/
cat ~/.cvm/alias/*

# 查看 shell 配置
grep cvm ~/.zshrc

# 测试 PATH
echo $PATH | grep cvm
which claude

# 清理测试数据（谨慎使用）
rm -rf ~/.cvm
rm -rf ~/.cvm-repo
```

### B. 快速恢复脚本

如果测试环境损坏，使用此脚本恢复：

```bash
#!/bin/bash
# quick-reset.sh

echo "清理 cvm 环境..."
rm -rf ~/.cvm
rm -rf ~/.cvm-repo

echo "重新安装 cvm..."
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash

echo "重启 shell..."
exec $SHELL

echo "完成！运行 'cvm help' 验证安装"
```

### C. 测试数据

**推荐使用的版本：**
- 2.1.71 - 较旧版本，适合测试兼容性
- 2.1.63 - 当前版本
- 2.1.60 - 另一个测试版本（如果需要）

**避免使用的版本：**
- 非常旧的版本（可能不可用）
- beta 或 alpha 版本（可能不稳定）

---

**文档版本：** 1.0
**最后更新：** 2026-03-15
**维护者：** kimmykuang
