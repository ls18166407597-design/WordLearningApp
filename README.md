# WordLearningApp

一个纯原生 SwiftUI 单词学习 App，直接调用 DashScope / OpenAI 兼容接口生成学习卡片，内置搜索、收藏、历史与自定义配置，**无需后端即可运行**。本 README 概述项目定位、目录、运行方式与维护要点，确保第一次阅读也能快速上手。

> 🗂️ 想了解更详细的交接/运维内容，请阅读《[WordLearningApp项目文档](./WordLearningApp%E9%A1%B9%E7%9B%AE%E6%96%87%E6%A1%A3.md)》；图标流程见《[AppIcon使用说明](./AppIcon%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E.md)》。

---

## 1. 核心特性

| 功能 | 描述 |
| --- | --- |
| 🔍 智能搜索 | 支持本地自动补全，触发云端生成学习卡片。 |
| 🧠 LLM 生成 | 通过 OpenAI-compatible `/chat/completions`，返回结构化 JSON，由 `WordData` 解码。 |
| ⭐ 收藏 / 历史 | `LocalStorage` + `UserDefaults` 保留常用单词和最近学习记录。 |
| ⚙️ 自定义配置 | 在设置页填写 API Key / Base URL / Model，可切换 DashScope 与 OpenAI。 |
| 🎨 统一主题 | `ThemeManager` + `AppTheme` 规范配色与组件风格。 |
| 🧾 App Icon 流程 | SVG 底稿 + `AppIcon.appiconset`，脚本可一键导出所需尺寸。 |

---

## 2. 目录结构

```
WordLearningApp.xcodeproj/         # Xcode 工程
WordLearningApp/
├── App/                           # 应用入口
├── Models/                        # 数据模型（WordData 等）
├── Services/
│   ├── Network/APIService.swift   # OpenAI-compatible 调用
│   ├── Storage/LocalStorage.swift # 收藏/历史/本地缓存
│   ├── Config/LLMConfigStore.swift
│   └── Theme / WordForm 等子模块
├── ViewModels/                    # Home/WordDetail 等 VM
├── Views/                         # 各 Tab + 组件
├── Styles/AppTheme.swift          # 主题样式
├── Assets.xcassets/AppIcon.appiconset
└── Resources/AppIcon.svg

README.md                          # 当前文档
WordLearningApp项目文档.md         # 全量交接说明
AppIcon使用说明.md                # 图标维护指南
若干 UI/功能总结 *.md 文件         # 历史设计记录
```

> **说明**：`words/` 目录只作为运行时缓存，已从仓库忽略；如需初始化数据，可运行 App 后在沙盒自动生成。

---

## 3. 快速运行

1. **环境**：macOS + Xcode 15+，iOS 17 SDK。
2. **打开工程**：`open WordLearningApp.xcodeproj`。
3. **签名**：Target `WordLearningApp` → `Signing & Capabilities`
   - 勾选 `Automatically manage signing`
   - Team 选择个人 Apple ID；如 Bundle ID 冲突，修改为 `com.<yourname>.wordlearning`
4. **运行**：选择模拟器或真机，`Cmd + R`。
5. **首次使用**：在 App “设置” Tab 填写：
   - API Key：DashScope 或 OpenAI
   - Base URL：`https://dashscope.aliyuncs.com/compatible-mode/v1` 或 `https://api.openai.com/v1`
   - Model：如 `qwen-plus` / `gpt-4o-mini`

---

## 4. 数据与隐私

| 类型 | 存储位置 |
| --- | --- |
| 学习卡 JSON | 沙盒 `Documents/words/<word>.json` |
| 收藏 | `UserDefaults` 键 `favorites` |
| 历史 | `UserDefaults` 键 `history` |
| API 配置 | `LLMConfigStore`（保存在 `UserDefaults`） |

> ⚠️ 输入的单词与配置会发送至第三方 LLM，请自备 Key 并关注费用与隐私合规。

---

## 5. 维护提示

### App Icon
- SVG 底稿：`Resources/AppIcon.svg`
- XCAssets：`Assets.xcassets/AppIcon.appiconset`
- `project.pbxproj` 已配置 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
- 详细步骤见《AppIcon使用说明.md》，可通过脚本批量导出 18 个尺寸。

### 常见操作
- **添加/丢失文件**：使用根目录下的 `add_files_to_xcode.py`、`add_empty_state_view.py`、`fix_xcode_project.py` 辅助脚本（必要时运行，避免手动编辑 `.pbxproj`）。
- **清理缓存**：删除模拟器沙盒内 `Documents/words` 或在设置页新增开关。
- **调试 LLM**：`APIService` 中的 `generateWordData`、`extractJSONObject` 是排查请求/解析问题的入口。

---

## 6. 文档索引

1. 《[WordLearningApp项目文档](./WordLearningApp%E9%A1%B9%E7%9B%AE%E6%96%87%E6%A1%A3.md)》：架构、数据流、FAQ、未来规划。
2. 《[AppIcon使用说明](./AppIcon%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E.md)》：图标生成脚本与注意事项。
3. 其余 `*.md` 文件：UI 优化、动画、测试指南等历史记录，可用于回溯设计决策。

---

## 7. 下一步可拓展方向

- 增强学习模式（复习、提醒、错题本）
- 多模型配置模板或一键切换
- 更细粒度的日志与错误上报
- 引入 CI（Fastlane / GitHub Actions）自动打包

欢迎基于上述路线持续演进，也欢迎在 GitHub Issues 发起讨论或反馈需求。
