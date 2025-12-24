# WordLearningApp 项目文档

> 适用范围：`/Users/liusong/Downloads/Trae/iOS` 仓库内的 SwiftUI iOS 应用。本说明覆盖项目概览、运行步骤、配置、脚本、资源与常见问题，可直接作为交接/维护文档。

---

## 1. 项目概览

- **平台**：原生 iOS，SwiftUI + Combine。
- **功能定位**：调用 DashScope / OpenAI 兼容接口生成单词学习卡片，支持搜索、收藏、历史、设置等核心体验。
- **离线依赖**：无后端，本地持久化 JSON + `UserDefaults`。

### 1.1 核心能力
1. 单词搜索与自动补全（基于本地缓存词表）。
2. 云端 LLM 生成学习卡片，结果落地到本地 JSON。
3. 收藏、历史与设置（API Key/Base URL/Model）管理。

---

## 2. 环境与依赖

| 项目 | 说明 |
| --- | --- |
| Xcode | 15+（项目 `objectVersion = 60`，对应 Xcode 15）。 |
| iOS Deployment Target | 17.2（已写在 Build Settings）。 |
| 最低系统 | iOS 17（包含 iPhone / iPad）。 |
| 第三方库 | 无（全系统库）。 |

**注意**：若使用 DashScope，需要可访问外网；使用 OpenAI 则需科学上网。

---

## 3. 目录结构（关键路径）

```
iOS/
├── WordLearningApp.xcodeproj     # Xcode 工程
├── WordLearningApp/              # 源码根目录
│   ├── App/WordLearningApp.swift # App 入口
│   ├── Models/                   # 数据模型（WordData.swift 等）
│   ├── Services/
│   │   ├── Network/APIService.swift
│   │   ├── Storage/LocalStorage.swift
│   │   ├── Config/LLMConfigStore.swift
│   │   ├── Theme/ThemeManager.swift
│   │   └── WordForm/WordFormService.swift
│   ├── ViewModels/
│   │   ├── HomeViewModel.swift
│   │   └── WordDetailViewModel.swift
│   ├── Views/
│   │   ├── Root/RootTabView.swift
│   │   ├── Home/HomeView.swift
│   │   ├── WordDetail/WordDetailView.swift
│   │   ├── Favorites/FavoritesView.swift
│   │   ├── History/HistoryView.swift
│   │   ├── Settings/SettingsView.swift
│   │   └── Components/EmptyStateView.swift
│   ├── Styles/AppTheme.swift
│   ├── Assets.xcassets/AppIcon.appiconset
│   └── Resources/AppIcon.svg
├── words/                        # 预置词表/示例数据
├── scripts/                      # 额外脚本（如 generate_word_forms.py）
├── add_files_to_xcode.py         # 批量写入 pbxproj 的辅助脚本
├── add_empty_state_view.py       # 向 pbxproj 添加 EmptyStateView 的脚本
├── fix_xcode_project.py          # 修正工程分组/引用脚本
├── README.md                     # 简要运行指南（原有）
├── AppIcon使用说明.md            # App Icon 专用说明
└── WordLearningApp项目文档.md    # （即本文）
```

---

## 4. 构建 & 运行

1. **打开工程**：`open WordLearningApp.xcodeproj`
2. **签名配置**（首次必做）：
   - Target `WordLearningApp` → `Signing & Capabilities`
   - 勾选 `Automatically manage signing`
   - Team 选择个人 Apple ID，如有 Bundle ID 冲突，改名 `com.<yourname>.wordlearning`
3. **运行**：选择模拟器或真机，`Cmd + R`。
4. **首次进入 App**：在“设置” Tab 配置 API Key/Base URL/Model（详见 README.md 第 4 章）。

> 如果只想查看 UI，可使用 Mock 数据，但当前版本默认直连 LLM，缺少配置会提示错误。

---

## 5. 配置项说明

| 项 | 说明 | 默认值 |
| --- | --- | --- |
| API Key | DashScope 或 OpenAI Key | 空 |
| Base URL | DashScope: `https://dashscope.aliyuncs.com/compatible-mode/v1`；OpenAI: `https://api.openai.com/v1` | DashScope 地址 |
| Model | DashScope 示例 `qwen-plus`；OpenAI 示例 `gpt-4o-mini` | 空 |
| 数据落盘 | `Documents/words/<word>.json` | - |
| 收藏/历史 | `UserDefaults`，键分别为 `favorites` / `history` | - |

所有配置均保存在本机，不上传远端。

---

## 6. 功能模块概述

| 模块 | 位置 | 描述 |
| --- | --- | --- |
| Root Tab | `Views/Root/RootTabView.swift` | 包含学习/收藏/历史/设置四个 Tab。 |
| 搜索页 | `Views/Home/HomeView.swift` & `HomeViewModel` | 搜索 + 自动补全，发起生成请求。 |
| 详情页 | `Views/WordDetail/WordDetailView.swift` | 展示 LLM 结果，支持收藏。 |
| 收藏页 | `Views/Favorites/FavoritesView.swift` | 列出收藏的单词卡片。 |
| 历史页 | `Views/History/HistoryView.swift` | 按时间查看历史记录。 |
| 设置页 | `Views/Settings/SettingsView.swift` | 填写/修改 API 相关配置。 |
| 样式系统 | `Styles/AppTheme.swift` + `Services/Theme/ThemeManager.swift` | 统一颜色与主题逻辑。 |

---

## 7. 数据流 & 容错

1. 用户输入单词 → `HomeViewModel` 调 `APIService`（OpenAI-compatible `/chat/completions`）。
2. 返回 JSON → 解析为 `WordData`。缺失字段时，`WordData` 的解码逻辑会填充默认值，避免崩溃。
3. `LocalStorage` 负责：
   - 缓存单词 JSON
   - 维护收藏、历史列表（`UserDefaults`）
4. 界面通过 `ViewModel` + `@Published` 触发刷新。

**异常兜底**：若 LLM 返回非 JSON，将提示错误；如需更严格校验，可增加服务器端代理（当前未提供）。

---

## 8. 资源与资产

### 8.1 App Icon
- 资产目录：`WordLearningApp/Assets.xcassets/AppIcon.appiconset`
- 底稿：`WordLearningApp/Resources/AppIcon.svg`
- Xcode 已配置 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
- 详细维护步骤见《AppIcon使用说明.md》，包含批量导出脚本。

### 8.2 词表
- `words/` 目录下存放预制 JSON，可用于初始化或测试。

### 8.3 其它 UI 文档
- 根目录保留了多份 UI/交互调优的 Markdown（如 `UI统一优化方案.md`、`动画效果测试指南.md` 等），可查阅历史设计决策。

---

## 9. 脚本与工具

| 脚本 | 作用 | 说明 |
| --- | --- | --- |
| `scripts/generate_word_forms.py` | 词形生成工具 | 位于 `scripts/`，用于扩展词表。 |
| `add_files_to_xcode.py` | 批量把 Theme/Styles 写入 `.pbxproj` | 已执行完成，保留以备后续扩展。 |
| `add_empty_state_view.py` | 把 `EmptyStateView.swift` 注入 `.pbxproj` | 适用于工程引用丢失的情况。 |
| `fix_xcode_project.py` | 修复 `.pbxproj` 中 Theme/Styles 分组 | 若 Xcode 结构错乱，可运行该脚本。 |
| （推荐自建）`regenerate_app_icon.sh` | 重新导出 App Icon | 示例脚本已写入《AppIcon使用说明.md》。 |

> 所有脚本默认在仓库根目录执行。运行前建议备份 `project.pbxproj`。

---

## 10. 测试与调试建议

1. **基础流程**：启动 → 设置 API → 搜索单词 → 校验生成结果 → 收藏 & 历史。
2. **网络问题排查**：查看 Xcode 控制台的 `APIService` 日志；若返回 401/403，检查 Key；如超时，确认网络环境。
3. **UI 验收**：参考根目录下的 UI 测试/总结文档，逐项对照（动画、主题、交互反馈等）。
4. **数据文件**：模拟器可通过 `~/Library/Developer/CoreSimulator/Devices/.../Documents/words` 查看生成的 JSON。

---

## 11. 常见问题 (FAQ)

| 问题 | 解决方案 |
| --- | --- |
| 构建后显示旧图标 | `Product → Clean Build Folder`，或删除旧 App 重装。 |
| LLM 返回格式错误 | 检查 prompt 设置或模型；必要时捕获响应保存到文件，调整提示词。 |
| 数据未保存 | 确认 `LocalStorage` 的路径权限；真机需打开文件共享或通过 Xcode 下载容器。 |
| 更换 API 供应商 | 在设置页更改 Base URL + Model；如需额外 Header，可在 `APIService` 中扩展。 |
| `.pbxproj` 冲突 | 使用 `fix_xcode_project.py` 或手动合并；修改前最好先备份。 |

---

## 12. 后续可扩展方向

1. **更丰富的学习模式**：如复习计划、提醒通知、错题本。
2. **多模型/多账号切换**：允许用户配置多个 API Profile。
3. **本地化**：当前界面为中文，可扩展英语或其他语言。
4. **更细粒度的日志记录**：方便诊断 LLM 调用失败原因。
5. **CI/自动化**：可考虑添加 Fastlane / GitHub Actions，自动打包与测试。

---

## 13. 关联文档索引

| 文件 | 说明 |
| --- | --- |
| `README.md` | 快速上手指南（此前已有）。 |
| `AppIcon使用说明.md` | App 图标维护手册。 |
| `UI统一优化方案.md` 等 | 历史 UI/交互总结，位于仓库根目录。 |
| `WordLearningApp项目文档.md` | （本文）完整项目文档。 |

如需新增功能或重构，请优先更新本文与 README 保持一致，确保交接信息完整。
