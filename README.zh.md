# agent-backup 🛡️

> **Hermes Agent 和 OpenClaw 的一键备份工具** — 备份你的技能(skills)、记忆(memories)、配置(config)、脚本(scripts)和人设(persona)。

**🌐 语言 / Language: [中文](README.zh.md) | [English](README.md)**
![平台: macOS · Linux](https://img.shields.io/badge/Platform-macOS%20%C2%B7%20Linux-blue)

**agent-backup** 是一个开源工具，可以自动备份你的 AI Agent 自定义内容——包括你积累的所有技能、脚本、记忆、配置和人设。如果电脑坏了或要换新机器，几分钟就能恢复。

同时支持 **Hermes Agent** 和 **OpenClaw**。

---

## ✨ 功能

- ✅ **通用检测** — 自动识别 Hermes（`~/.hermes/`）或 OpenClaw（`~/.openclaw/`）
- ✅ **技能与脚本** — 备份所有 SKILL.md 文件和自定义 Python/Shell 脚本
- ✅ **记忆与人设** — 保留长期记忆、用户画像和 Agent 人格配置
- ✅ **配置（脱敏）** — 保存配置但自动移除敏感信息
- ✅ **定时任务引用** — 记录 Cron 任务元数据（不含 secrets）
- ✅ **无 secrets 泄露** — `.gitignore` 拦截 `.env`、`auth.json`、会话数据、日志、缓存
- ✅ **一键恢复** — `restore.sh` 将所有文件放回正确位置
- ✅ **自动备份（可选）** — 每周一、四上午 9 点自动备份
- ✅ **一行命令上手** — 运行 `setup.sh`，回答 2 个问题即可

---

## 🚀 快速开始

### 一键安装（新用户）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zhangyucheng0111/agent-backup/main/scripts/setup.sh)
```

脚本会：
1. 自动检测你的 Agent（Hermes 或 OpenClaw）
2. 要求输入 GitHub 用户名和 token
3. 创建 **私有** GitHub 仓库（`agent-backup`）
4. 配置 SSH 密钥用于推送
5. 执行首次备份
6. （可选）设置每周两次自动备份

> **前置条件：** 安装 [Git](https://git-scm.com/)、有 [GitHub](https://github.com) 账号、
> 创建有 `repo` 权限的 Personal Access Token（[点此创建](https://github.com/settings/tokens/new)）。
> 必须已安装 Hermes 或 OpenClaw。

### 手动安装

```bash
# 克隆仓库
git clone git@github.com:zhangyucheng0111/agent-backup.git
cd agent-backup

# 执行首次备份
bash scripts/backup.sh

# （可选）设置定时自动备份
crontab -e
# 添加: 0 9 * * 1,4 cd /path/to/agent-backup && bash scripts/backup.sh >> backup.log 2>&1
```

### 在新电脑上恢复

```bash
# 1. 先安装你的 Agent（Hermes 或 OpenClaw）

# 2. 克隆备份仓库
git clone git@github.com:你的用户名/agent-backup.git
cd agent-backup

# 3. 一键恢复
bash scripts/restore.sh

# 4. 重新配置 API keys
cp template/.env.example ~/.hermes/.env
# 编辑 ~/.hermes/.env，填入真实 keys
```

---

## 📦 备份内容

| 项目 | 来源 | 仓库中的位置 |
|------|------|-------------|
| 技能（SKILL.md） | `$AGENT_HOME/skills/` | `skills/` |
| 自定义脚本 | `$AGENT_HOME/scripts/*.py` `*.sh` | `scripts/` |
| 长期记忆 | `$AGENT_HOME/memories/MEMORY.md` | `memories/MEMORY.md` |
| 用户画像 | `$AGENT_HOME/memories/USER.md` | `memories/USER.md` |
| Agent 人设 | `$AGENT_HOME/SOUL.md` | `prompts/SOUL.md` |
| 配置（脱敏） | `$AGENT_HOME/config.yaml` | `config/config.yaml` |
| 定时任务（参考） | `$AGENT_HOME/cron/jobs.json` | `archive/cron-jobs-reference.txt` |

### ⛔ 不会备份的内容

| 文件/目录 | 原因 |
|----------|------|
| `.env` | API keys、tokens、密码 |
| `auth.json` | OAuth tokens |
| `channel_directory.json` | 平台连接信息 |
| `state.db` / `sessions/` | 对话历史 |
| `cron/jobs.json`（原始） | 可能含 token |
| `logs/` | 日志文件 |
| `hermes-agent/` / `openclaw/` | 源码（可重新安装） |
| `lsp/`, `node/` | 依赖 |
| 所有缓存目录 | 临时数据 |

> 以上模式已在 `.gitignore` 中定义，不会被意外提交。

---

## 📁 仓库结构

```
agent-backup/
├── README.md                    # 本文件（英文）
├── README.zh.md                 # 中文版
├── LICENSE                      # MIT 许可
├── .gitignore                   # 敏感文件防护
├── scripts/
│   ├── setup.sh                 # ★ 一键安装向导
│   ├── backup.sh                # 自动备份：复制 → commit → push
│   ├── restore.sh               # 恢复：提取 → 放回
│   └── detect-env.sh            # 自动检测 Hermes 或 OpenClaw
├── template/
│   └── .env.example             # API key 模板
└── docs/
    ├── getting-started.md       # 详细入门指南
    ├── customize.md             # 自定义备份内容
    └── troubleshooting.md       # 常见问题
```

---

## 🔐 安全说明

- **你的 API keys 永远不会被上传** — `.gitignore` 阻止 `.env` 和所有凭证文件
- **私有仓库** — 只有你能访问你的数据
- **SSH 密钥认证** — 不重用密码
- **Token 仅在 `.env` 中** — 不嵌入脚本或 git 历史
- **脱敏配置** — 备份脚本会检查 config.yaml 中是否嵌入了 secrets 并发出警告

### 新电脑需要重新配置

- LLM Provider API keys（DeepSeek、OpenAI、Anthropic 等）
- 平台 Bot Token（Telegram、Discord、飞书等）
- GITHUB_TOKEN

---

## 🧪 兼容性

| Agent | 状态 | 测试平台 |
|-------|------|---------|
| **Hermes Agent** | ✅ 完全支持 | macOS 12.7, Linux |
| **OpenClaw** | ✅ 完全支持 | macOS, Linux |
| Windows (WSL2) | ⚡ 应该可用 | 未测试 |

---

## 📝 许可

MIT — 自由使用、修改和分发。

---

## 🙏 致谢

为 [Hermes Agent](https://hermes-agent.nousresearch.com) 和 OpenClaw 社区构建。
