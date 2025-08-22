# 技术实施指南

## 🏗️ 项目初始化

### 1. 创建Next.js项目

```bash
# 创建项目
npx create-next-app@latest poc-tech-platform --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

cd poc-tech-platform

# 安装核心依赖
npm install @prisma/client prisma @auth/prisma-adapter next-auth
npm install @supabase/supabase-js @supabase/auth-ui-react @supabase/auth-ui-shared
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-collaboration
npm install yjs y-websocket y-protocols
npm install inngest zod lucide-react date-fns
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu
npm install class-variance-authority clsx tailwind-merge

# 开发依赖
npm install -D @types/node @types/react @types/react-dom
npm install -D autoprefixer postcss tailwindcss
```

### 2. 环境配置

```bash
# .env.local
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key

# 数据库
DATABASE_URL="postgresql://username:password@localhost:5432/poc_tech_platform"

# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Inngest
INNGEST_EVENT_KEY=your-inngest-key
INNGEST_SIGNING_KEY=your-signing-key

# 邮件服务
EMAIL_SERVER_HOST=smtp.example.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-email
EMAIL_SERVER_PASSWORD=your-password
EMAIL_FROM=noreply@example.com
```

## 📦 核心文件结构

```
src/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # 认证相关页面
│   │   ├── login/
│   │   ├── signup/
│   │   └── verify/
│   ├── (dashboard)/              # 主应用页面
│   │   ├── dashboard/
│   │   └── t/[teamSlug]/
│   │       ├── page.tsx
│   │       ├── projects/
│   │       ├── members/
│   │       ├── settings/
│   │       └── p/[projectId]/
│   │           ├── page.tsx
│   │           ├── documents/
│   │           ├── tasks/
│   │           └── doc/[docId]/
│   │               ├── edit/
│   │               ├── history/
│   │               └── comments/
│   ├── api/                      # API Routes
│   │   ├── auth/
│   │   ├── teams/
│   │   ├── projects/
│   │   ├── documents/
│   │   ├── tasks/
│   │   ├── comments/
│   │   ├── upload/
│   │   └── inngest/
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── components/                   # UI组件
│   ├── auth/
│   ├── dashboard/
│   ├── editor/
│   ├── project/
│   ├── team/
│   ├── ui/                       # shadcn/ui组件
│   └── common/
├── lib/                          # 工具库
│   ├── auth.ts
│   ├── prisma.ts
│   ├── supabase.ts
│   ├── inngest.ts
│   ├── permissions.ts
│   ├── storage.ts
│   ├── utils.ts
│   └── validations.ts
├── hooks/                        # React Hooks
│   ├── useAuth.ts
│   ├── useCollaboration.ts
│   ├── usePermissions.ts
│   └── useStorage.ts
├── types/                        # TypeScript类型
│   ├── auth.ts
│   ├── database.ts
│   ├── api.ts
│   └── index.ts
├── inngest/                      # Inngest任务
│   ├── client.ts
│   ├── functions/
│   │   ├── generate-framework.ts
│   │   ├── document-check.ts
│   │   └── export-document.ts
│   └── types.ts
└── prisma/                       # 数据库
    ├── schema.prisma
    ├── migrations/
    └── seed.ts
```

## 🗄️ 数据库设置

### 1. Prisma配置

```typescript
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

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

// 其他模型... (参考PRD中的完整定义)
```

### 2. 数据库初始化

```bash
# 生成Prisma客户端
npx prisma generate

# 创建和应用迁移
npx prisma migrate dev --name init

# 填充种子数据
npx prisma db seed
```

## 🔐 认证系统实现

### 1. NextAuth配置

```typescript
// lib/auth.ts
import NextAuth, { type DefaultSession } from "next-auth"
import EmailProvider from "next-auth/providers/email"
import GoogleProvider from "next-auth/providers/google"
import { PrismaAdapter } from "@auth/prisma-adapter"
import { prisma } from "./prisma"

declare module "next-auth" {
  interface Session {
    user: {
      id: string
    } & DefaultSession["user"]
  }
}

export const authOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    EmailProvider({
      server: {
        host: process.env.EMAIL_SERVER_HOST,
        port: process.env.EMAIL_SERVER_PORT,
        auth: {
          user: process.env.EMAIL_SERVER_USER,
          pass: process.env.EMAIL_SERVER_PASSWORD,
        },
      },
      from: process.env.EMAIL_FROM,
    }),
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  session: {
    strategy: "jwt" as const,
  },
  callbacks: {
    session({ session, token }) {
      if (session.user && token.sub) {
        session.user.id = token.sub
      }
      return session
    },
  },
  pages: {
    signIn: "/auth/signin",
    verifyRequest: "/auth/verify-request",
  },
}

export const { handlers, auth, signIn, signOut } = NextAuth(authOptions)
```

### 2. 权限控制

```typescript
// lib/permissions.ts
import { prisma } from "./prisma"

export type Role = "OWNER" | "ADMIN" | "EDITOR" | "VIEWER"

export const PERMISSIONS = {
  "team:read": ["OWNER", "ADMIN", "EDITOR", "VIEWER"],
  "team:update": ["OWNER", "ADMIN"],
  "team:delete": ["OWNER"],
  "team:invite": ["OWNER", "ADMIN"],
  "project:create": ["OWNER", "ADMIN"],
  "project:read": ["OWNER", "ADMIN", "EDITOR", "VIEWER"],
  "project:update": ["OWNER", "ADMIN", "EDITOR"],
  "project:delete": ["OWNER", "ADMIN"],
  "document:create": ["OWNER", "ADMIN", "EDITOR"],
  "document:read": ["OWNER", "ADMIN", "EDITOR", "VIEWER"],
  "document:update": ["OWNER", "ADMIN", "EDITOR"],
  "document:delete": ["OWNER", "ADMIN"],
  "task:create": ["OWNER", "ADMIN", "EDITOR"],
  "task:read": ["OWNER", "ADMIN", "EDITOR", "VIEWER"],
} as const

export async function getUserRole(userId: string, teamId: string): Promise<Role | null> {
  const membership = await prisma.membership.findUnique({
    where: {
      userId_teamId: {
        userId,
        teamId,
      },
    },
  })
  
  return membership?.role || null
}

export async function hasPermission(
  userId: string, 
  teamId: string, 
  permission: keyof typeof PERMISSIONS
): Promise<boolean> {
  const role = await getUserRole(userId, teamId)
  if (!role) return false
  
  return PERMISSIONS[permission].includes(role)
}

export function createPermissionMiddleware(permission: keyof typeof PERMISSIONS) {
  return async (userId: string, teamId: string) => {
    const hasAccess = await hasPermission(userId, teamId, permission)
    if (!hasAccess) {
      throw new Error("Permission denied")
    }
  }
}
```

## 📝 文档编辑器实现

### 1. TipTap编辑器组件

```typescript
// components/editor/TipTapEditor.tsx
'use client'

import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Collaboration from '@tiptap/extension-collaboration'
import CollaborationCursor from '@tiptap/extension-collaboration-cursor'
import { WebrtcProvider } from 'y-webrtc'
import * as Y from 'yjs'
import { useEffect, useState } from 'react'
import { useAuth } from '@/hooks/useAuth'

interface TipTapEditorProps {
  documentId: string
  initialContent?: string
  onSave?: (content: string) => void
}

export function TipTapEditor({ documentId, initialContent, onSave }: TipTapEditorProps) {
  const { user } = useAuth()
  const [ydoc] = useState(() => new Y.Doc())
  const [provider, setProvider] = useState<WebrtcProvider | null>(null)

  useEffect(() => {
    // 设置协作提供者
    const webrtcProvider = new WebrtcProvider(documentId, ydoc)
    setProvider(webrtcProvider)

    return () => {
      webrtcProvider.destroy()
    }
  }, [documentId, ydoc])

  const editor = useEditor({
    extensions: [
      StarterKit,
      Collaboration.configure({
        document: ydoc,
      }),
      CollaborationCursor.configure({
        provider: provider,
        user: {
          name: user?.name || 'Anonymous',
          color: getRandomColor(),
        },
      }),
    ],
    content: initialContent,
    onUpdate: ({ editor }) => {
      const content = editor.getHTML()
      onSave?.(content)
    },
  })

  if (!editor) {
    return <div>Loading editor...</div>
  }

  return (
    <div className="prose max-w-none">
      <EditorContent editor={editor} />
    </div>
  )
}

function getRandomColor() {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57', '#FF9FF3']
  return colors[Math.floor(Math.random() * colors.length)]
}
```

### 2. 协作Hook

```typescript
// hooks/useCollaboration.ts
import { useEffect, useState } from 'react'
import * as Y from 'yjs'
import { WebrtcProvider } from 'y-webrtc'

export function useCollaboration(documentId: string) {
  const [ydoc] = useState(() => new Y.Doc())
  const [provider, setProvider] = useState<WebrtcProvider | null>(null)
  const [isConnected, setIsConnected] = useState(false)

  useEffect(() => {
    const webrtcProvider = new WebrtcProvider(documentId, ydoc)
    
    webrtcProvider.on('status', (event: { status: string }) => {
      setIsConnected(event.status === 'connected')
    })
    
    setProvider(webrtcProvider)

    return () => {
      webrtcProvider.destroy()
    }
  }, [documentId, ydoc])

  const saveSnapshot = async () => {
    const content = ydoc.toJSON()
    // 保存到数据库
    await fetch(`/api/documents/${documentId}/revisions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content }),
    })
  }

  return {
    ydoc,
    provider,
    isConnected,
    saveSnapshot,
  }
}
```

## ⚡ 异步任务系统

### 1. Inngest配置

```typescript
// lib/inngest.ts
import { Inngest } from "inngest"

export const inngest = new Inngest({
  id: "poc-tech-platform",
  eventKey: process.env.INNGEST_EVENT_KEY,
})
```

### 2. 任务函数

```typescript
// inngest/functions/generate-framework.ts
import { inngest } from "../client"
import { prisma } from "@/lib/prisma"

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
    
    // 下载源文件
    const files = await step.run("download-files", async () => {
      return await downloadSourceFiles(payload.sourceFiles)
    })
    
    // 执行生成逻辑
    const framework = await step.run("generate", async () => {
      await prisma.task.update({
        where: { id: taskId },
        data: { progress: 50 }
      })
      
      // 集成现有PoC功能
      return await generateDocumentFramework({
        regulationFiles: files.regulations,
        exampleFiles: files.examples,
        documentType: payload.documentType,
        customPrompts: payload.customPrompts,
      })
    })
    
    // 创建新版本
    const revision = await step.run("create-revision", async () => {
      const document = await prisma.document.findUnique({
        where: { id: payload.documentId },
        include: { revisions: { orderBy: { number: 'desc' }, take: 1 } }
      })
      
      const nextNumber = (document?.revisions[0]?.number || 0) + 1
      
      return await prisma.revision.create({
        data: {
          documentId: payload.documentId,
          number: nextNumber,
          title: `自动生成框架 v${nextNumber}`,
          content: framework,
          createdBy: payload.userId,
        }
      })
    })
    
    // 更新任务完成状态
    await step.run("complete-task", async () => {
      await prisma.task.update({
        where: { id: taskId },
        data: { 
          status: "succeeded", 
          progress: 100,
          result: { revisionId: revision.id }
        }
      })
    })
    
    // 发送通知
    await step.run("send-notification", async () => {
      await inngest.send({
        name: "notification/task.completed",
        data: {
          taskId,
          userId: payload.userId,
          type: "framework_generated",
          documentId: payload.documentId,
        }
      })
    })
    
    return { success: true, revisionId: revision.id }
  }
)

async function downloadSourceFiles(sourceFiles: string[]) {
  // 从对象存储下载文件
  // 实现文件下载逻辑
  return {
    regulations: [],
    examples: [],
  }
}

async function generateDocumentFramework(params: any) {
  // 集成现有的PoC生成逻辑
  // 调用现有的框架生成脚本
  return {
    type: "doc",
    content: [
      {
        type: "heading",
        attrs: { level: 1 },
        content: [{ type: "text", text: "生成的文档框架" }]
      },
      // ... 更多内容
    ]
  }
}
```

## 📁 文件存储实现

### 1. Supabase存储配置

```typescript
// lib/storage.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

export async function generateUploadUrl(
  fileName: string,
  contentType: string,
  teamId: string,
  projectId?: string
) {
  const timestamp = Date.now()
  const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9.-]/g, '_')
  const filePath = projectId 
    ? `teams/${teamId}/projects/${projectId}/files/${timestamp}-${sanitizedFileName}`
    : `teams/${teamId}/files/${timestamp}-${sanitizedFileName}`
  
  const { data, error } = await supabase.storage
    .from('documents')
    .createSignedUploadUrl(filePath, {
      expiresIn: 3600, // 1小时
    })
  
  if (error) {
    throw new Error(`Failed to generate upload URL: ${error.message}`)
  }
  
  return {
    uploadUrl: data.signedUrl,
    filePath,
    publicUrl: `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/documents/${filePath}`,
  }
}

export async function generateDownloadUrl(filePath: string, expiresIn = 3600) {
  const { data, error } = await supabase.storage
    .from('documents')
    .createSignedUrl(filePath, expiresIn)
  
  if (error) {
    throw new Error(`Failed to generate download URL: ${error.message}`)
  }
  
  return data.signedUrl
}

export async function deleteFile(filePath: string) {
  const { error } = await supabase.storage
    .from('documents')
    .remove([filePath])
  
  if (error) {
    throw new Error(`Failed to delete file: ${error.message}`)
  }
}
```

### 2. 文件上传组件

```typescript
// components/common/FileUpload.tsx
'use client'

import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, File, X, CheckCircle, AlertCircle } from 'lucide-react'

interface FileUploadProps {
  teamId: string
  projectId?: string
  onUploadComplete?: (files: UploadedFile[]) => void
  maxFiles?: number
  maxSize?: number
  acceptedTypes?: string[]
}

interface UploadedFile {
  id: string
  name: string
  size: number
  type: string
  url: string
  filePath: string
}

export function FileUpload({
  teamId,
  projectId,
  onUploadComplete,
  maxFiles = 10,
  maxSize = 10 * 1024 * 1024, // 10MB
  acceptedTypes = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
}: FileUploadProps) {
  const [uploading, setUploading] = useState(false)
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([])
  const [errors, setErrors] = useState<string[]>([])

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    setUploading(true)
    setErrors([])
    
    const newErrors: string[] = []
    const uploaded: UploadedFile[] = []

    for (const file of acceptedFiles) {
      try {
        // 验证文件
        if (file.size > maxSize) {
          newErrors.push(`${file.name}: 文件大小超过限制`)
          continue
        }
        
        if (!acceptedTypes.includes(file.type)) {
          newErrors.push(`${file.name}: 不支持的文件类型`)
          continue
        }

        // 获取上传URL
        const response = await fetch('/api/upload/url', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fileName: file.name,
            contentType: file.type,
            teamId,
            projectId,
          }),
        })

        if (!response.ok) {
          throw new Error('Failed to get upload URL')
        }

        const { uploadUrl, filePath, publicUrl } = await response.json()

        // 上传文件
        const uploadResponse = await fetch(uploadUrl, {
          method: 'PUT',
          body: file,
          headers: {
            'Content-Type': file.type,
          },
        })

        if (!uploadResponse.ok) {
          throw new Error('Failed to upload file')
        }

        uploaded.push({
          id: crypto.randomUUID(),
          name: file.name,
          size: file.size,
          type: file.type,
          url: publicUrl,
          filePath,
        })

      } catch (error) {
        newErrors.push(`${file.name}: 上传失败`)
      }
    }

    setUploadedFiles(prev => [...prev, ...uploaded])
    setErrors(newErrors)
    setUploading(false)

    if (uploaded.length > 0) {
      onUploadComplete?.(uploaded)
    }
  }, [teamId, projectId, maxSize, acceptedTypes, onUploadComplete])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    maxFiles,
    disabled: uploading,
  })

  const removeFile = (fileId: string) => {
    setUploadedFiles(prev => prev.filter(f => f.id !== fileId))
  }

  return (
    <div className="space-y-4">
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${
          isDragActive
            ? 'border-blue-500 bg-blue-50'
            : 'border-gray-300 hover:border-gray-400'
        } ${uploading ? 'opacity-50 cursor-not-allowed' : ''}`}
      >
        <input {...getInputProps()} />
        <Upload className="mx-auto h-12 w-12 text-gray-400 mb-2" />
        <p className="text-sm text-gray-600">
          {isDragActive
            ? '拖放文件到这里...'
            : '点击或拖放文件到这里上传'}
        </p>
        <p className="text-xs text-gray-500 mt-1">
          支持 PDF, Word 文档，最大 {maxSize / 1024 / 1024}MB
        </p>
      </div>

      {errors.length > 0 && (
        <div className="space-y-1">
          {errors.map((error, index) => (
            <div key={index} className="flex items-center text-red-600 text-sm">
              <AlertCircle className="h-4 w-4 mr-1" />
              {error}
            </div>
          ))}
        </div>
      )}

      {uploadedFiles.length > 0 && (
        <div className="space-y-2">
          <h4 className="text-sm font-medium">已上传文件</h4>
          {uploadedFiles.map((file) => (
            <div key={file.id} className="flex items-center justify-between p-2 bg-gray-50 rounded">
              <div className="flex items-center">
                <File className="h-4 w-4 mr-2 text-gray-400" />
                <span className="text-sm">{file.name}</span>
                <CheckCircle className="h-4 w-4 ml-2 text-green-500" />
              </div>
              <button
                onClick={() => removeFile(file.id)}
                className="text-gray-400 hover:text-red-500"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

## 🔄 现有PoC功能迁移

### 1. 技术栈矩阵组件迁移

```typescript
// components/matrix/TechMatrixEditor.tsx
'use client'

import { useState, useEffect } from 'react'
import { useCollaboration } from '@/hooks/useCollaboration'

interface TechMatrixEditorProps {
  documentId: string
  teamId: string
  canEdit: boolean
}

export function TechMatrixEditor({ documentId, teamId, canEdit }: TechMatrixEditorProps) {
  const [matrixData, setMatrixData] = useState(null)
  const { ydoc, provider, isConnected, saveSnapshot } = useCollaboration(documentId)
  
  // 同步矩阵数据到Yjs文档
  useEffect(() => {
    const yMatrix = ydoc.getMap('techMatrix')
    
    // 初始化数据结构
    if (!yMatrix.has('phases')) {
      yMatrix.set('phases', [
        '文档采集/解析',
        '清洗/归一化', 
        '切块',
        '向量化/索引',
        '检索（混合召回）',
        '重排',
        '生成（Reasoning）',
        '审核/后处理',
        '评测/监控',
        '部署/安全'
      ])
    }
    
    if (!yMatrix.has('categories')) {
      yMatrix.set('categories', [
        {
          id: 'dp',
          name: '数据处理 (Data Processing)',
          options_by_phase: {
            '文档采集/解析': [
              '简单文档加载 (Word-txt)',
              '多格式解析 (Word, PDF, 图表)',
              '多源数据接入 (注册包 + 项目包)'
            ],
            // ... 其他阶段
          }
        },
        // ... 其他类别
      ])
    }
    
    // 监听变化
    yMatrix.observe(() => {
      const data = yMatrix.toJSON()
      setMatrixData(data)
    })
    
    // 初始加载
    setMatrixData(yMatrix.toJSON())
  }, [ydoc])

  const updateSelection = (categoryId: string, phase: string, option: string, checked: boolean) => {
    if (!canEdit) return
    
    const yMatrix = ydoc.getMap('techMatrix')
    const ySelections = yMatrix.get('selections') || ydoc.getMap()
    
    const key = `${categoryId}|${phase}`
    const currentSelections = ySelections.get(key) || []
    
    if (checked) {
      if (!currentSelections.includes(option)) {
        ySelections.set(key, [...currentSelections, option])
      }
    } else {
      ySelections.set(key, currentSelections.filter(item => item !== option))
    }
    
    yMatrix.set('selections', ySelections)
  }

  const addNewOption = async (categoryId: string, phase: string, content: string) => {
    if (!canEdit) return
    
    const yMatrix = ydoc.getMap('techMatrix')
    const categories = yMatrix.get('categories') || []
    
    const updatedCategories = categories.map(cat => {
      if (cat.id === categoryId) {
        return {
          ...cat,
          options_by_phase: {
            ...cat.options_by_phase,
            [phase]: [...(cat.options_by_phase[phase] || []), content]
          }
        }
      }
      return cat
    })
    
    yMatrix.set('categories', updatedCategories)
    
    // 保存快照
    await saveSnapshot()
  }

  if (!matrixData) {
    return <div>加载中...</div>
  }

  return (
    <div className="tech-matrix-container">
      {/* 协作状态指示器 */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">技术栈矩阵</h2>
        <div className="flex items-center space-x-2">
          <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
          <span className="text-sm text-gray-600">
            {isConnected ? '已连接' : '连接中...'}
          </span>
          {canEdit && (
            <button
              onClick={() => setShowAddModal(true)}
              className="btn btn-primary"
            >
              ➕ 新增选项
            </button>
          )}
        </div>
      </div>
      
      {/* 矩阵表格 - 保留现有逻辑，增加协作功能 */}
      <div className="matrix-wrapper">
        {/* 现有的矩阵渲染逻辑 */}
        {/* 增加实时协作指示器 */}
        {/* 增加权限控制 */}
      </div>
      
      {/* 新增选项模态框 */}
      {showAddModal && (
        <AddOptionModal
          categories={matrixData.categories}
          phases={matrixData.phases}
          onAdd={addNewOption}
          onClose={() => setShowAddModal(false)}
        />
      )}
    </div>
  )
}
```

这个技术实施指南提供了从项目初始化到核心功能实现的完整代码示例。每个部分都可以直接在Cursor中实施，并且保持了与现有PoC功能的兼容性。

下一步建议：
1. 先完成项目初始化和基础架构
2. 实现用户认证和团队管理
3. 集成文档编辑器和协作功能
4. 迁移现有的技术栈矩阵功能
5. 添加异步任务处理和文件存储
