#!/bin/bash

# PoC-Tech_Path 多人协作平台初始化脚本
# 使用方法: chmod +x scripts/init-project.sh && ./scripts/init-project.sh

set -e

echo "🚀 开始初始化 PoC-Tech_Path 多人协作平台..."

# 检查Node.js版本
echo "📋 检查环境依赖..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js 18+"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d. -f1 | cut -dv -f2)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js 版本过低，请升级到 18+"
    exit 1
fi

echo "✅ Node.js 版本检查通过"

# 创建项目目录
PROJECT_NAME="poc-tech-platform"
echo "📁 创建项目: $PROJECT_NAME"

# 创建Next.js项目
echo "🏗️  创建Next.js项目..."
npx create-next-app@latest $PROJECT_NAME \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm

cd $PROJECT_NAME

echo "📦 安装核心依赖..."

# 安装认证相关
npm install next-auth@beta @auth/prisma-adapter

# 安装数据库相关
npm install @prisma/client prisma

# 安装Supabase
npm install @supabase/supabase-js @supabase/auth-ui-react @supabase/auth-ui-shared

# 安装编辑器相关
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-collaboration
npm install yjs y-websocket y-protocols

# 安装任务队列
npm install inngest

# 安装工具库
npm install zod lucide-react date-fns clsx class-variance-authority tailwind-merge

# 安装UI组件
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-select
npm install @radix-ui/react-tabs @radix-ui/react-toast @radix-ui/react-tooltip

# 安装开发依赖
npm install -D @types/node typescript

echo "📂 创建项目结构..."

# 创建主要目录
mkdir -p src/{components,lib,hooks,types,inngest}
mkdir -p src/components/{auth,dashboard,editor,project,team,ui,common,matrix}
mkdir -p src/inngest/functions
mkdir -p prisma
mkdir -p docs

# 创建配置文件
echo "⚙️  创建配置文件..."

# Prisma配置
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

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

enum Role {
  OWNER
  ADMIN
  EDITOR
  VIEWER
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

model Project {
  id          String     @id @default(cuid())
  teamId      String
  name        String
  description String?
  status      String     @default("active")
  tags        String[]   @default([])
  team        Team       @relation(fields: [teamId], references: [id], onDelete: Cascade)
  documents   Document[]
  tasks       Task[]
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt
  
  @@map("projects")
}

model Document {
  id            String     @id @default(cuid())
  projectId     String
  title         String
  type          String
  state         String     @default("draft")
  storageKey    String?
  currentRevId  String?
  project       Project    @relation(fields: [projectId], references: [id], onDelete: Cascade)
  revisions     Revision[]
  comments      Comment[]
  createdAt     DateTime   @default(now())
  updatedAt     DateTime   @updatedAt
  
  @@map("documents")
}

model Revision {
  id         String   @id @default(cuid())
  documentId String
  number     Int
  title      String?
  content    Json
  summary    String?
  createdBy  String
  createdAt  DateTime @default(now())
  document   Document @relation(fields: [documentId], references: [id], onDelete: Cascade)
  
  @@unique([documentId, number])
  @@map("revisions")
}

model Comment {
  id         String    @id @default(cuid())
  documentId String
  authorId   String
  body       String
  range      Json?
  resolved   Boolean   @default(false)
  parentId   String?
  document   Document  @relation(fields: [documentId], references: [id], onDelete: Cascade)
  replies    Comment[] @relation("CommentReplies")
  parent     Comment?  @relation("CommentReplies", fields: [parentId], references: [id])
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt
  
  @@map("comments")
}

model Task {
  id         String   @id @default(cuid())
  projectId  String
  kind       String
  status     String   @default("queued")
  payload    Json
  result     Json?
  error      String?
  progress   Int      @default(0)
  createdBy  String
  project    Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  
  @@map("tasks")
}

model AuditLog {
  id         String   @id @default(cuid())
  teamId     String
  actorId    String
  action     String
  targetId   String?
  targetType String?
  meta       Json?
  ipAddress  String?
  userAgent  String?
  team       Team     @relation(fields: [teamId], references: [id], onDelete: Cascade)
  createdAt  DateTime @default(now())
  
  @@map("audit_logs")
}
EOF

# 环境变量模板
cat > .env.example << 'EOF'
# 应用配置
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-super-secret-key

# 数据库
DATABASE_URL="postgresql://username:password@localhost:5432/poc_tech_platform"

# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_KEY=your-supabase-service-key

# Inngest
INNGEST_EVENT_KEY=your-inngest-event-key
INNGEST_SIGNING_KEY=your-inngest-signing-key

# 邮件服务 (可选，用于邮箱验证和通知)
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-email@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
EMAIL_FROM=noreply@yourdomain.com

# Google OAuth (可选)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
EOF

# TypeScript配置优化
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# 创建基础lib文件
echo "📚 创建基础库文件..."

# Prisma客户端
cat > src/lib/prisma.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOF

# 工具函数
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date) {
  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "long", 
    day: "numeric",
  }).format(date)
}

export function formatRelativeTime(date: Date) {
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}天前`
  if (hours > 0) return `${hours}小时前`
  if (minutes > 0) return `${minutes}分钟前`
  return "刚刚"
}
EOF

# 验证schema
cat > src/lib/validations.ts << 'EOF'
import { z } from "zod"

export const teamSchema = z.object({
  name: z.string().min(2, "团队名称至少2个字符").max(50, "团队名称最多50个字符"),
  slug: z.string().min(2).max(50).regex(/^[a-z0-9-]+$/, "只能包含小写字母、数字和连字符"),
  description: z.string().max(200, "描述最多200个字符").optional(),
})

export const projectSchema = z.object({
  name: z.string().min(2, "项目名称至少2个字符").max(100, "项目名称最多100个字符"),
  description: z.string().max(500, "描述最多500个字符").optional(),
  tags: z.array(z.string()).default([]),
})

export const documentSchema = z.object({
  title: z.string().min(1, "文档标题不能为空").max(200, "标题最多200个字符"),
  type: z.enum(["TechMatrix", "LifeSpanReport", "PTR", "CER", "Other"]),
})

export const commentSchema = z.object({
  body: z.string().min(1, "评论内容不能为空").max(1000, "评论最多1000个字符"),
  range: z.object({
    from: z.number(),
    to: z.number(),
  }).optional(),
})
EOF

# 创建基础组件
echo "🎨 创建基础UI组件..."

# 按钮组件
mkdir -p src/components/ui
cat > src/components/ui/button.tsx << 'EOF'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
EOF

# 创建package.json脚本
echo "📝 更新package.json脚本..."
npm pkg set scripts.db:generate="prisma generate"
npm pkg set scripts.db:migrate="prisma migrate dev"
npm pkg set scripts.db:push="prisma db push"
npm pkg set scripts.db:seed="prisma db seed"
npm pkg set scripts.db:studio="prisma studio"

# Git初始化
echo "📡 初始化Git仓库..."
git init
git add .
git commit -m "feat: 初始化项目结构"

# 创建开发文档
echo "📖 创建开发文档..."
cat > README.md << 'EOF'
# PoC-Tech_Path 多人协作平台

一个面向研发和监管事务团队的智能协作平台，支持技术栈规划、文档协作编辑和智能生成。

## 快速开始

### 环境要求
- Node.js 18+
- PostgreSQL 14+
- npm/yarn/pnpm

### 安装和配置

1. 克隆项目并安装依赖
```bash
git clone <repository-url>
cd poc-tech-platform
npm install
```

2. 环境配置
```bash
cp .env.example .env.local
# 编辑 .env.local 填入真实配置
```

3. 数据库设置
```bash
# 生成Prisma客户端
npm run db:generate

# 运行数据库迁移
npm run db:migrate

# (可选) 查看数据库
npm run db:studio
```

4. 启动开发服务器
```bash
npm run dev
```

访问 http://localhost:3000

## 技术栈

- **前端**: Next.js 14, React, TypeScript, Tailwind CSS
- **后端**: Next.js API Routes, Prisma ORM
- **数据库**: PostgreSQL
- **认证**: NextAuth.js
- **实时协作**: Yjs, TipTap
- **任务队列**: Inngest
- **存储**: Supabase Storage
- **部署**: Vercel

## 项目结构

```
src/
├── app/                  # Next.js App Router
├── components/           # React组件
├── lib/                  # 工具库
├── hooks/                # React Hooks
├── types/                # TypeScript类型
└── inngest/              # 异步任务
```

## 开发指南

### 数据库操作
```bash
# 创建新迁移
npm run db:migrate

# 重置数据库
npx prisma migrate reset

# 填充种子数据
npm run db:seed
```

### 代码规范
- 使用TypeScript严格模式
- 遵循ESLint和Prettier规则
- 提交信息遵循Conventional Commits

## 贡献指南

1. Fork项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

MIT License
EOF

echo "✅ 项目初始化完成！"
echo ""
echo "🎉 接下来的步骤:"
echo "1. 复制 .env.example 到 .env.local 并配置环境变量"
echo "2. 设置PostgreSQL数据库"
echo "3. 运行 npm run db:migrate 初始化数据库"
echo "4. 运行 npm run dev 启动开发服务器"
echo ""
echo "📚 查看更多信息:"
echo "- 产品需求文档: docs/PRD.md"
echo "- 技术实施指南: docs/TECH_IMPLEMENTATION.md"
echo "- 开发任务清单: docs/DEV_CHECKLIST.md"
echo ""
echo "🚀 Happy coding!"
EOF

chmod +x scripts/init-project.sh
