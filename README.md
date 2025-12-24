# WordLearningApp

一个纯原生的 SwiftUI iOS 单词学习应用，直接调用 DashScope / OpenAI 兼容接口生成学习卡片，支持搜索、收藏、历史与设置等完整体验。项目完全本地运行，不依赖后端服务。

> ✅ 如果需要更深入的交接说明，请参阅 [`WordLearningApp项目文档.md`](./WordLearningApp%E9%A1%B9%E7%9B%AE%E6%96%87%E6%A1%A3.md)。

## 功能亮点

- 🔍 **单词搜索 & 自动补全**：基于本地词表快速定位，并触发 LLM 生成学习卡。
- 🧠 **云端生成**：调用 OpenAI-compatible `/chat/completions`，输出结构化 JSON，由 `WordData` 解析和落盘。
- ⭐ **收藏 / 历史**：通过 `LocalStorage` + `UserDefaults` 保存常用单词与学习记录。
- ⚙️ **设置中心**：在 App 内配置 API Key、Base URL、模型，支持 DashScope / OpenAI。
- 🎨 **统一主题**：`AppTheme` + `ThemeManager` 提供一致的配色与 UI 体验。
- 🧾 **图标工作流**：`Resources/AppIcon.svg` + `Assets.xcassets/AppIcon.appiconset`，详情见《AppIcon使用说明.md》。

## 目录速览

```
WordLearningApp.xcodeproj/   # Xcode 工程文件
WordLearningApp/            # SwiftUI 源码
  ├── App/
  ├── Models/
  ├── Services/
  ├── ViewModels/
  ├── Views/
  ├── Styles/
  ├── Assets.xcassets/
  └── Resources/
scripts/                    # 辅助脚本 (如 generate_word_forms.py)
words/                      # 预置词表 / 示例 JSON
README.md                   # 当前文件
WordLearningApp项目文档.md   # 全量项目文档
AppIcon使用说明.md          # App Icon 维护指南
```

## 快速开始

1. **安装环境**：Xcode 15+，iOS 17 SDK。
2. **打开工程**：`open WordLearningApp.xcodeproj`。
3. **配置签名**：Target `WordLearningApp` → `Signing & Capabilities` → 勾选 `Automatically manage signing` 并选择个人 Team（如 Bundle ID 冲突可自定义）。
4. **运行**：选择模拟器或真机，`Cmd + R`。
5. **首次使用**：进入 App 的“设置” Tab，填写：
   - API Key：DashScope 或 OpenAI Key
   - Base URL：DashScope `https://dashscope.aliyuncs.com/compatible-mode/v1` / OpenAI `https://api.openai.com/v1`
   - Model：例如 `qwen-plus` / `gpt-4o-mini`

## 开发提示

- 网络与隐私：所有配置仅存储在本地 `UserDefaults`，但会把输入单词发送给第三方 LLM，请注意费用与合规。
- 数据位置：生成的学习卡片写入沙盒 `Documents/words/<word>.json`，收藏与历史为 `UserDefaults` 键 `favorites` / `history`。
- 资源管理：图标更新脚本示例见《AppIcon使用说明.md》，运行前可先备份 `AppIcon.appiconset`。
- 常见脚本：
  - `scripts/generate_word_forms.py`：扩展词形。
  - `add_files_to_xcode.py / add_empty_state_view.py / fix_xcode_project.py`：用于修正 `.pbxproj` 引用。

## 文档索引

- [WordLearningApp项目文档](./WordLearningApp%E9%A1%B9%E7%9B%AE%E6%96%87%E6%A1%A3.md)：包含架构、数据流、脚本、FAQ 等完整说明。
- [AppIcon使用说明](./AppIcon%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E.md)：App Icon 的维护与批量导出流程。
- 其他 UI/交互调优记录请查看仓库根目录的各类 Markdown 文件（如 `UI统一优化方案.md` 等）。

欢迎按照文档扩展更多学习模式或自动化流程，如需帮助可在 issues 中反馈。
