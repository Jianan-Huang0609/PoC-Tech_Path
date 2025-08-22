# PoC-Tech_Path 多人协作平台 - 产品需求文档 (PRD)

## 📋 项目概述

基于现有的 PoC 技术栈矩阵规划器，升级为支持多人登录、组队共编、云端存储的企业级协作平台。帮助研发团队和监管事务团队协同管理技术路径规划、文档生成审查流程。

## 🎯 核心价值

- **多人协作**：团队成员实时协作编辑技术规划文档
- **智能生成**：基于法规自动生成结构化框架和通俗解读
- **版本管理**：完整的文档版本控制和审批流程
- **权限管理**：细粒度的角色权限控制
- **云端存储**：安全可靠的云端数据存储和备份

## 👥 目标用户

- **RA团队**：监管事务团队，负责法规解读和文档审查
- **研发团队**：产品开发团队，负责技术实现和项目管理
- **项目经理**：负责项目进度管理和团队协调
- **管理层**：负责决策制定和资源分配

## 🏗️ 系统架构

### 技术栈选择

**前端框架**
- Next.js 14/15 (App Router)
- React 18
- TypeScript
- Tailwind CSS + shadcn/ui

**认证系统**
- Auth.js (next-auth)
- 支持邮箱/手机号注册
- OTP验证 + 可选密码

**数据层**
- Prisma ORM
- PostgreSQL (Supabase/Neon)
- 行级安全策略 (RLS)

**实时协作**
- Yjs + y-websocket
- Supabase Realtime (备选)
- TipTap 编辑器

**存储服务**
- Supabase Storage
- AWS S3 (备选)
- 预签名URL直传

**任务队列**
- Inngest
- Trigger.dev (备选)
- Supabase Functions (备选)

**部署方案**
- Vercel (前端)
- Supabase (后端服务)

## 📊 数据模型设计

### 核心实体关系

```
User (用户)
├── Membership (团队成员关系)
├── Team (团队)
    ├── Project (项目)
        ├── Document (文档)
            ├── Revision (版本)
            └── Comment (评论)
        └── Task (任务)
└── AuditLog (审计日志)
```

### 详细数据模型

```prisma
// 用户模型
model User {
  id            String       @id @default(cuid())
  email         String       @unique
  phone         String?      @unique
  name          String?
  image         String?
  emailVerified DateTime?
  memberships   Membership[]
  auditLogs     AuditLog[]
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
  
  @@map("users")
}

// 团队模型
model Team {
  id           String       @id @default(cuid())
  name         String
  slug         String       @unique
  description  String?
  image        String?
  memberships  Membership[]
  projects     Project[]
  auditLogs    AuditLog[]
  createdAt    DateTime     @default(now())
  updatedAt    DateTime     @updatedAt
  
  @@map("teams")
}

// 团队成员关系
enum Role {
  OWNER   // 团队所有者
  ADMIN   // 管理员
  EDITOR  // 编辑者
  VIEWER  // 查看者
}

model Membership {
  id        String   @id @default(cuid())
  userId    String
  teamId    String
  role      Role     @default(VIEWER)
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  team      Team     @relation(fields: [teamId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([userId, teamId])
  @@map("memberships")
}

// 项目模型
model Project {
  id          String     @id @default(cuid())
  teamId      String
  name        String
  description String?
  status      String     @default("active") // active, archived, deleted
  tags        String[]   @default([])
  team        Team       @relation(fields: [teamId], references: [id], onDelete: Cascade)
  documents   Document[]
  tasks       Task[]
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt
  
  @@map("projects")
}

// 文档模型
model Document {
  id            String     @id @default(cuid())
  projectId     String
  title         String
  type          String     // "TechMatrix", "LifeSpanReport", "PTR", "CER"
  state         String     @default("draft") // draft, in_review, approved, published
  storageKey    String?    // 对象存储路径
  currentRevId  String?
  project       Project    @relation(fields: [projectId], references: [id], onDelete: Cascade)
  revisions     Revision[]
  comments      Comment[]
  createdAt     DateTime   @default(now())
  updatedAt     DateTime   @updatedAt
  
  @@map("documents")
}

// 文档版本
model Revision {
  id         String   @id @default(cuid())
  documentId String
  number     Int
  title      String?
  content    Json     // TipTap JSON 或结构化框架JSON
  summary    String?  // 版本变更摘要
  createdBy  String
  createdAt  DateTime @default(now())
  document   Document @relation(fields: [documentId], references: [id], onDelete: Cascade)
  
  @@unique([documentId, number])
  @@map("revisions")
}

// 评论系统
model Comment {
  id         String   @id @default(cuid())
  documentId String
  authorId   String
  body       String
  range      Json?    // 选区/锚点信息
  resolved   Boolean  @default(false)
  parentId   String?  // 回复评论
  document   Document @relation(fields: [documentId], references: [id], onDelete: Cascade)
  replies    Comment[] @relation("CommentReplies")
  parent     Comment? @relation("CommentReplies", fields: [parentId], references: [id])
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  
  @@map("comments")
}

// 异步任务
model Task {
  id         String   @id @default(cuid())
  projectId  String
  kind       String   // "generate", "extract", "check", "export"
  status     String   @default("queued") // queued, running, succeeded, failed
  payload    Json     // 任务参数
  result     Json?    // 任务结果
  error      String?  // 错误信息
  progress   Int      @default(0) // 进度百分比
  createdBy  String
  project    Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  
  @@map("tasks")
}

// 审计日志
model AuditLog {
  id        String   @id @default(cuid())
  teamId    String
  actorId   String
  action    String   // "DOC.CREATE", "DOC.UPDATE", "MEMBER.INVITE" 等
  targetId  String?  // 操作目标ID
  targetType String? // 操作目标类型
  meta      Json?    // 额外元数据
  ipAddress String?
  userAgent String?
  team      Team     @relation(fields: [teamId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())
  
  @@map("audit_logs")
}
```

## 🔐 权限控制设计

### 角色定义

| 角色 | 权限范围 |
|------|----------|
| **OWNER** | 团队所有权限，包括转移/删除团队 |
| **ADMIN** | 管理成员、创建项目、修改团队设置 |
| **EDITOR** | 创建/编辑文档、创建任务、发表评论 |
| **VIEWER** | 查看项目、文档、评论，无编辑权限 |

### 访问控制规则

```typescript
// 权限矩阵
const PERMISSIONS = {
  // 团队权限
  'team:read': ['OWNER', 'ADMIN', 'EDITOR', 'VIEWER'],
  'team:update': ['OWNER', 'ADMIN'],
  'team:delete': ['OWNER'],
  'team:invite': ['OWNER', 'ADMIN'],
  
  // 项目权限
  'project:create': ['OWNER', 'ADMIN'],
  'project:read': ['OWNER', 'ADMIN', 'EDITOR', 'VIEWER'],
  'project:update': ['OWNER', 'ADMIN', 'EDITOR'],
  'project:delete': ['OWNER', 'ADMIN'],
  
  // 文档权限
  'document:create': ['OWNER', 'ADMIN', 'EDITOR'],
  'document:read': ['OWNER', 'ADMIN', 'EDITOR', 'VIEWER'],
  'document:update': ['OWNER', 'ADMIN', 'EDITOR'],
  'document:delete': ['OWNER', 'ADMIN'],
  
  // 任务权限
  'task:create': ['OWNER', 'ADMIN', 'EDITOR'],
  'task:read': ['OWNER', 'ADMIN', 'EDITOR', 'VIEWER'],
} as const;
```

## 🎨 用户界面设计

### 页面路由规划

```
/auth
├── /login              # 登录页面
├── /signup             # 注册页面
└── /verify             # 邮箱/手机验证

/dashboard              # 总览仪表板

/t/[teamSlug]          # 团队空间
├── /                   # 团队首页
├── /projects           # 项目列表
├── /members            # 成员管理
├── /settings           # 团队设置
└── /p/[projectId]      # 项目详情
    ├── /                # 项目概览
    ├── /documents       # 文档列表
    ├── /tasks           # 任务管理
    ├── /settings        # 项目设置
    └── /doc/[docId]     # 文档编辑
        ├── /edit        # 编辑模式
        ├── /history     # 版本历史
        └── /comments    # 评论管理

/api                    # API 接口
├── /auth/*             # 认证相关
├── /teams/*            # 团队管理
├── /projects/*         # 项目管理
├── /documents/*        # 文档管理
├── /tasks/*            # 任务管理
├── /comments/*         # 评论管理
└── /upload/*           # 文件上传
```

### 核心组件设计

```typescript
// 主要UI组件
components/
├── auth/
│   ├── LoginForm.tsx
│   ├── SignupForm.tsx
│   └── OTPVerification.tsx
├── dashboard/
│   ├── TeamSwitcher.tsx
│   ├── ProjectGrid.tsx
│   └── RecentActivity.tsx
├── editor/
│   ├── TipTapEditor.tsx
│   ├── CollaborationCursor.tsx
│   └── CommentSidebar.tsx
├── project/
│   ├── ProjectHeader.tsx
│   ├── TaskQueue.tsx
│   └── DocumentTree.tsx
├── team/
│   ├── MemberList.tsx
│   ├── InviteDialog.tsx
│   └── RoleSelector.tsx
└── common/
    ├── Layout.tsx
    ├── Navigation.tsx
    ├── LoadingSpinner.tsx
    └── ErrorBoundary.tsx
```

## ⚡ 核心功能模块

### 1. 用户认证系统

**功能点**
- [x] 邮箱/手机号注册登录
- [x] OTP验证码验证
- [x] 第三方登录（Google/GitHub）
- [x] 会话管理和自动刷新
- [x] 密码重置功能

**技术实现**
```typescript
// lib/auth.ts
import NextAuth from "next-auth"
import EmailProvider from "next-auth/providers/email"
import GoogleProvider from "next-auth/providers/google"

export const authOptions = {
  providers: [
    EmailProvider({
      server: process.env.EMAIL_SERVER,
      from: process.env.EMAIL_FROM,
    }),
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  adapter: PrismaAdapter(prisma),
  session: { strategy: "jwt" },
}
```

### 2. 团队协作管理

**功能点**
- [x] 创建和管理团队
- [x] 邮箱邀请成员
- [x] 角色权限分配
- [x] 团队设置管理
- [x] 成员活动记录

**核心接口**
```typescript
// app/api/teams/route.ts
export async function POST(request: Request) {
  const user = await auth()
  const { name, slug } = await request.json()
  
  const team = await prisma.team.create({
    data: {
      name,
      slug,
      memberships: {
        create: {
          userId: user.id,
          role: 'OWNER'
        }
      }
    }
  })
  
  return Response.json(team)
}
```

### 3. 项目文档管理

**功能点**
- [x] 创建项目和文档
- [x] 文档分类和标签
- [x] 版本控制和历史记录
- [x] 文档状态流转
- [x] 文档搜索和过滤

**文档编辑器**
```typescript
// components/editor/TipTapEditor.tsx
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Collaboration from '@tiptap/extension-collaboration'
import * as Y from 'yjs'

export function TipTapEditor({ documentId }: { documentId: string }) {
  const ydoc = new Y.Doc()
  
  const editor = useEditor({
    extensions: [
      StarterKit,
      Collaboration.configure({
        document: ydoc,
      }),
    ],
    content: '<p>开始协作编辑...</p>',
  })

  return <EditorContent editor={editor} />
}
```

### 4. 实时协作编辑

**功能点**
- [x] 多人同时编辑
- [x] 实时光标显示
- [x] 冲突自动解决
- [x] 离线编辑支持
- [x] 操作历史记录

**协作同步**
```typescript
// lib/collaboration.ts
import { WebsocketProvider } from 'y-websocket'
import * as Y from 'yjs'

export function setupCollaboration(documentId: string) {
  const ydoc = new Y.Doc()
  const provider = new WebsocketProvider(
    process.env.NEXT_PUBLIC_WS_URL!,
    documentId,
    ydoc
  )
  
  return { ydoc, provider }
}
```

### 5. 异步任务系统

**功能点**
- [x] 任务队列管理
- [x] 进度实时更新
- [x] 任务结果通知
- [x] 失败重试机制
- [x] 任务状态监控

**任务处理器**
```typescript
// inngest/functions.ts
import { inngest } from "./client"

export const generateFramework = inngest.createFunction(
  { id: "generate-framework" },
  { event: "task/generate.framework" },
  async ({ event, step }) => {
    const { taskId, projectId, payload } = event.data
    
    // 更新任务状态
    await step.run("update-status", async () => {
      await prisma.task.update({
        where: { id: taskId },
        data: { status: "running", progress: 10 }
      })
    })
    
    // 执行生成逻辑（集成现有PoC功能）
    const result = await step.run("generate", async () => {
      return await generateDocumentFramework(payload)
    })
    
    // 保存结果
    await step.run("save-result", async () => {
      await prisma.task.update({
        where: { id: taskId },
        data: { 
          status: "succeeded", 
          progress: 100,
          result 
        }
      })
    })
    
    return result
  }
)
```

### 6. 文件存储管理

**功能点**
- [x] 预签名URL上传
- [x] 文件类型验证
- [x] 存储空间管理
- [x] 文件版本控制
- [x] 访问权限控制

**存储服务**
```typescript
// lib/storage.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

export async function generateUploadUrl(
  fileName: string,
  contentType: string,
  teamId: string
) {
  const filePath = `teams/${teamId}/files/${Date.now()}-${fileName}`
  
  const { data, error } = await supabase.storage
    .from('documents')
    .createSignedUploadUrl(filePath)
  
  if (error) throw error
  
  return {
    uploadUrl: data.signedUrl,
    filePath,
  }
}
```

## 🔄 现有PoC功能集成

### 技术栈矩阵管理

**集成方案**
- 将现有的技术栈矩阵作为特殊文档类型
- 保留现有的交互界面和功能
- 增加多人协作编辑能力
- 支持版本历史和评论

```typescript
// components/matrix/TechMatrixEditor.tsx
import { useState, useEffect } from 'react'
import { useCollaboration } from '@/hooks/useCollaboration'

export function TechMatrixEditor({ documentId }: { documentId: string }) {
  const [matrixData, setMatrixData] = useState(null)
  const { ydoc, provider } = useCollaboration(documentId)
  
  // 同步矩阵数据到Yjs文档
  useEffect(() => {
    const yMatrix = ydoc.getMap('techMatrix')
    
    yMatrix.observe(() => {
      setMatrixData(yMatrix.toJSON())
    })
  }, [ydoc])
  
  // 现有的矩阵渲染和交互逻辑
  return (
    <div className="tech-matrix-container">
      {/* 保留现有的表格和工具栏 */}
      {/* 增加协作用户指示器 */}
      {/* 增加评论和版本控制 */}
    </div>
  )
}
```

### 智能文档生成

**集成方案**
- 将现有的框架生成逻辑包装为异步任务
- 支持法规文件上传和解析
- 提供生成进度和结果预览
- 支持生成结果的编辑和完善

```typescript
// lib/generators/framework.ts
export async function generateDocumentFramework(params: {
  regulationFile: string
  exampleFiles: string[]
  documentType: string
  customPrompts?: string[]
}) {
  // 调用现有的生成逻辑
  const framework = await callExistingPoC(params)
  
  // 转换为TipTap可编辑格式
  const editorContent = convertToTipTapJSON(framework)
  
  return {
    framework: editorContent,
    metadata: {
      generatedAt: new Date(),
      sourceFiles: [params.regulationFile, ...params.exampleFiles],
      documentType: params.documentType,
    }
  }
}
```

## 📈 开发里程碑规划

### 第一阶段：基础架构（第1-4天）

**目标**：搭建项目基础和核心认证
- [x] Next.js项目初始化和配置
- [x] 数据库设计和Prisma配置
- [x] 用户认证系统实现
- [x] 基础UI组件和路由

**交付物**
- 可运行的项目框架
- 用户注册登录功能
- 基础的团队管理页面

### 第二阶段：协作功能（第5-8天）

**目标**：实现团队协作和权限管理
- [x] 团队创建和成员管理
- [x] 项目创建和文档管理
- [x] 基础权限控制
- [x] 文档编辑器集成

**交付物**
- 完整的团队协作流程
- 文档创建和编辑功能
- 权限验证机制

### 第三阶段：高级功能（第9-12天）

**目标**：实现实时协作和任务系统
- [x] 实时协作编辑
- [x] 异步任务队列
- [x] 文件上传和存储
- [x] 评论和版本控制

**交付物**
- 多人实时编辑功能
- 完整的任务处理流程
- 文件管理系统

### 第四阶段：PoC集成（第13-16天）

**目标**：集成现有PoC功能
- [x] 技术栈矩阵编辑器迁移
- [x] 智能文档生成集成
- [x] 文档审查流程
- [x] 导出和分享功能

**交付物**
- 完整的技术栈管理功能
- 智能文档生成服务
- 文档审查和审批流程

### 第五阶段：优化完善（第17-20天）

**目标**：性能优化和安全加固
- [x] 性能监控和优化
- [x] 安全漏洞扫描和修复
- [x] 用户体验优化
- [x] 测试和部署准备

**交付物**
- 生产就绪的应用
- 完整的测试覆盖
- 部署和运维文档

## 🛡️ 安全和合规

### 数据安全

**加密策略**
- 数据库连接SSL加密
- 敏感数据字段加密存储
- API请求HTTPS强制
- 文件存储端到端加密

**访问控制**
- JWT令牌认证
- 行级安全策略（RLS）
- API速率限制
- IP白名单支持

### 合规要求

**数据保护**
- GDPR用户数据权利
- 数据备份和恢复
- 审计日志完整性
- 数据迁移和删除

**监管合规**
- 医疗器械监管要求
- 数据本地化存储
- 第三方安全认证
- 合规报告生成

## 📊 监控和运维

### 性能监控

**指标收集**
- 页面加载时间
- API响应时间
- 数据库查询性能
- 实时协作延迟

**错误追踪**
- Sentry错误监控
- 用户行为分析
- 系统日志聚合
- 告警通知机制

### 运维自动化

**CI/CD流程**
- 代码自动测试
- 自动化部署
- 数据库迁移
- 环境配置管理

**备份恢复**
- 数据库定时备份
- 文件存储冗余
- 灾难恢复计划
- 数据一致性检查

## 💰 成本预估

### 基础设施成本（月）

| 服务 | 规格 | 费用 |
|------|------|------|
| Vercel Pro | 前端托管 | $20 |
| Supabase Pro | 数据库+存储 | $25 |
| Inngest | 任务队列 | $20 |
| 总计 | | **$65/月** |

### 开发成本

| 阶段 | 工期 | 人力成本 |
|------|------|----------|
| MVP开发 | 20天 | 3-4人·月 |
| 功能完善 | 10天 | 2人·月 |
| 测试部署 | 5天 | 1人·月 |
| **总计** | **35天** | **6-7人·月** |

## 🚀 发布计划

### Beta版本（内测）

**时间**：开发完成后1周
**用户**：内部团队5-10人
**功能**：核心协作功能
**目标**：收集用户反馈，修复关键问题

### V1.0版本（正式发布）

**时间**：Beta版本后2周
**用户**：目标企业客户
**功能**：完整产品功能
**目标**：获得首批付费用户

### 后续版本规划

**V1.1**：移动端适配
**V1.2**：高级分析功能
**V1.3**：API开放平台
**V2.0**：AI智能助手

---

## 📝 总结

这个PRD为PoC-Tech_Path平台的升级提供了完整的技术路线图和实施计划。通过分阶段开发，我们可以快速构建MVP版本，并逐步完善功能。重点关注用户体验、安全性和可扩展性，确保产品能够满足企业级应用的需求。

下一步建议立即开始第一阶段的开发工作，搭建项目基础架构。
