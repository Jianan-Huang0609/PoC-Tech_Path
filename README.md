# VB小助手融合项目 (VB-Helps-VBer × PoC-Tech_Path)

<div align="center">

![Version](https://img.shields.io/badge/version-v1.2.1-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Node](https://img.shields.io/badge/node-%3E%3D16.0.0-brightgreen.svg)
![Next.js](https://img.shields.io/badge/Next.js-15.5.0-black.svg)

**一页式展示 注册项目全周期 × 技术路径（V1–V5）的可视化网站**  
*用于快速对齐 PoC 目标、技术路线、ROI 与成本，并支持后续按模块逐步落地*

</div>

---

## 📋 项目概述

VB小助手融合项目是一个企业级协作平台，专为医疗器械研发和监管事务团队设计。项目整合了：

- **技术栈矩阵规划器**：可视化技术选择和进度管理
- **多人协作系统**：实时编辑、团队管理、权限控制
- **智能文档生成**：基于法规自动生成结构化框架
- **项目全周期管理**：从概念验证到产品部署的完整流程

### 🎯 核心价值

- 📊 **可视化规划**：直观展示技术栈演进路径（V1-V5）
- 👥 **团队协作**：多人实时编辑，权限分级管理
- 🤖 **智能助手**：AI驱动的文档生成和技术推荐
- 📈 **进度追踪**：完整的项目里程碑和任务管理
- 🔄 **版本控制**：文档版本历史和变更追踪

---

## 🏗️ 项目架构

### 当前版本（v1.2.1）- 单页应用
```
PoC-Tech_Path/
├── index.html              # 技术栈矩阵核心页面
├── docs/                   # 项目文档
│   ├── PRD.md             # 产品需求文档
│   ├── TECH_IMPLEMENTATION.md  # 技术实施指南
│   └── DEV_CHECKLIST.md   # 开发任务清单
├── scripts/               # 自动化脚本
└── 进度记录_20250825.md   # 项目进度记录
```

### 目标版本（v2.0.0）- 多人协作平台
```
poc-tech-platform/         # Next.js 应用
├── src/
│   ├── app/               # App Router 页面
│   ├── components/        # UI 组件
│   ├── lib/              # 工具库
│   ├── hooks/            # React Hooks
│   └── types/            # TypeScript 类型
├── prisma/               # 数据库模型
├── inngest/              # 异步任务
└── docs/                 # API 文档
```

---

## 🛠️ 技术栈

### 前端技术
- **Framework**: Next.js 15.5.0 (App Router)
- **Language**: TypeScript 5+
- **Styling**: Tailwind CSS 4.0
- **UI Components**: shadcn/ui + Radix UI
- **Editor**: TipTap (协作编辑)
- **Collaboration**: Yjs (实时同步)

### 后端技术
- **Database**: PostgreSQL + Prisma ORM
- **Authentication**: NextAuth.js
- **Storage**: Supabase Storage
- **Tasks**: Inngest (异步任务队列)
- **Deployment**: Vercel + Supabase

### 开发工具
- **Version Control**: Git + GitHub
- **Code Quality**: ESLint + Prettier
- **Package Manager**: npm
- **CI/CD**: GitHub Actions

---

## 🚀 快速开始

### 环境要求
- Node.js >= 16.0.0
- npm >= 8.0.0
- Git

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/z004wtps/PoC-Tech_Path.git
   cd PoC-Tech_Path
   ```

2. **体验当前版本（单页应用）**
   ```bash
   # 本地运行
   python -m http.server 8000
   # 或使用 npm
   npm start
   
   # 访问 http://localhost:8000
   ```

3. **开发新版本（Next.js平台）**
   ```bash
   cd poc-tech-platform
   
   # 安装依赖
   npm install
   
   # 启动开发服务器
   npm run dev
   
   # 访问 http://localhost:3000
   ```

### 配置环境变量
```bash
# 复制环境变量模板
cp .env.local.example .env.local

# 配置必要的环境变量
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
DATABASE_URL="postgresql://..."
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

---

## 📖 功能特性

### 🎯 技术栈矩阵管理
- ✅ 可视化技术选择矩阵（阶段 × 版本）
- ✅ 动态添加技术选项和阶段
- ✅ 实时保存和导入导出功能
- ✅ 技术选项备注和说明

### 📋 项目进度管理
- ✅ Calendar ToDo 任务管理
- ✅ 项目里程碑追踪
- ✅ 进度可视化概览
- ✅ 备注和改进方向记录

### 👥 多人协作（开发中）
- 🔄 实时协作编辑
- 🔄 团队和权限管理
- 🔄 文档版本控制
- 🔄 评论和审查流程

### 🤖 智能助手（规划中）
- 📋 AI驱动的框架生成
- 📋 法规文档智能解析
- 📋 技术推荐和优化建议
- 📋 自动化报告生成

---

## 📊 开发路线图

### 第一阶段：基础架构 ✅
- [x] 项目初始化和技术选型
- [x] 数据库设计和API架构
- [x] 用户认证和权限系统
- [x] 基础UI组件和布局

### 第二阶段：协作功能 🔄
- [ ] 团队管理和成员邀请
- [ ] 项目创建和文档管理
- [ ] 实时协作编辑器
- [ ] 权限控制和安全策略

### 第三阶段：高级功能 📋
- [ ] 文件存储和版本控制
- [ ] 异步任务和通知系统
- [ ] 搜索和数据分析
- [ ] 移动端适配

### 第四阶段：AI集成 📋
- [ ] 智能文档生成
- [ ] 技术推荐引擎
- [ ] 自动化测试和部署
- [ ] 性能优化和监控

---

## 🤝 参与贡献

### 贡献指南
1. Fork 项目仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 开发规范
- 遵循 TypeScript 严格模式
- 使用 ESLint 和 Prettier 代码格式化
- 编写单元测试覆盖核心功能
- 遵循 Conventional Commits 提交规范

### 提交格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

类型说明：
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

---

## 📄 文档和资源

### 项目文档
- [产品需求文档 (PRD)](docs/PRD.md)
- [技术实施指南](docs/TECH_IMPLEMENTATION.md)
- [开发任务清单](docs/DEV_CHECKLIST.md)
- [项目进度记录](进度记录_20250825.md)

### 外部资源
- [Next.js 官方文档](https://nextjs.org/docs)
- [Prisma 文档](https://www.prisma.io/docs)
- [Supabase 文档](https://supabase.io/docs)
- [TipTap 编辑器](https://tiptap.dev/)

---

## 📊 项目统计

### 开发进度
- **总体进度**: 30% (第一阶段基础架构)
- **功能模块**: 15个已规划，4个已实现
- **代码行数**: ~2000+ 行 (单页应用)
- **预计完成**: 2025年9月 (24个工作日)

### 技术指标
- **性能**: 首屏加载 < 2秒
- **兼容性**: 支持现代浏览器
- **安全性**: HTTPS + 数据加密
- **可扩展**: 支持100+并发用户

---

## 📧 联系信息

**项目维护者**: Jianan Huang  
**组织**: Siemens Healthineers · 医械RA圈  
**标语**: *最懂AI · 爱游泳的辩论选手*

- 📧 Email: [项目邮箱]
- 🐛 Issues: [GitHub Issues](https://github.com/z004wtps/PoC-Tech_Path/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/z004wtps/PoC-Tech_Path/discussions)

---

## 📜 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

内部 PoC 资料，仅限团队内评审与演示。外发前请进行敏感信息脱敏与法务确认。

---

<div align="center">

**⭐ 如果这个项目对您有帮助，请给我们一个星星！**

[![Stars](https://img.shields.io/github/stars/z004wtps/PoC-Tech_Path?style=social)](https://github.com/z004wtps/PoC-Tech_Path/stargazers)
[![Forks](https://img.shields.io/github/forks/z004wtps/PoC-Tech_Path?style=social)](https://github.com/z004wtps/PoC-Tech_Path/network/members)

</div>
