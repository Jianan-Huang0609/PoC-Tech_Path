# 贡献指南 (Contributing Guide)

感谢您对VB小助手融合项目的关注！我们欢迎所有形式的贡献，包括但不限于代码、文档、设计、测试等。

## 🤝 如何贡献

### 1. 报告问题 (Bug Reports)
如果您发现了bug或有改进建议，请通过以下方式报告：

- 在 [GitHub Issues](https://github.com/z004wtps/VB-Helps-VBer/issues) 创建新的issue
- 清楚描述问题和重现步骤
- 提供相关的环境信息（浏览器版本、操作系统等）

### 2. 功能请求 (Feature Requests)
对于新功能的建议：

- 在 GitHub Issues 中使用 "enhancement" 标签
- 详细描述功能需求和使用场景
- 如果可能，提供设计稿或参考资料

### 3. 代码贡献 (Code Contributions)

#### 开发环境设置
```bash
# 1. Fork 项目到您的 GitHub 账户
# 2. 克隆到本地
git clone https://github.com/YOUR_USERNAME/VB-Helps-VBer.git
cd VB-Helps-VBer

# 3. 安装依赖
npm install

# 4. 启动开发服务器
npm run dev

# 5. 新版本平台开发
cd poc-tech-platform
npm install
npm run dev
```

#### 提交流程
1. **创建分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **开发和测试**
   - 遵循代码规范
   - 添加必要的测试
   - 确保所有测试通过

3. **提交代码**
   ```bash
   git add .
   git commit -m "feat(scope): add new feature"
   ```

4. **推送并创建 Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 代码规范

### 提交消息规范
遵循 [Conventional Commits](https://conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### 类型 (Type)
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动
- `perf`: 性能优化
- `ci`: CI/CD 相关

#### 范围 (Scope)
- `matrix`: 技术栈矩阵功能
- `auth`: 认证系统
- `ui`: 用户界面
- `api`: API 接口
- `docs`: 文档
- `deps`: 依赖管理

#### 示例
```
feat(matrix): add new technology option modal
fix(auth): resolve login session timeout issue
docs(readme): update installation instructions
```

### 代码风格

#### TypeScript/JavaScript
- 使用 TypeScript 严格模式
- 遵循 ESLint 配置
- 使用 Prettier 格式化代码
- 函数和变量使用驼峰命名法
- 常量使用大写下划线命名

#### React 组件
- 使用函数组件和 Hooks
- 组件名使用 PascalCase
- 文件名使用 PascalCase 或 kebab-case
- Props 接口以 Props 结尾

```typescript
interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary'
}

export function Button({ children, onClick, variant = 'primary' }: ButtonProps) {
  // 组件实现
}
```

#### CSS/样式
- 使用 Tailwind CSS 类名
- 避免内联样式
- 使用语义化的类名
- 遵循移动优先的响应式设计

### 文件组织
```
src/
├── app/                  # Next.js App Router
├── components/           # React 组件
│   ├── ui/              # 基础 UI 组件
│   ├── common/          # 通用组件
│   └── features/        # 功能特定组件
├── lib/                 # 工具库和配置
├── hooks/               # 自定义 Hooks
├── types/               # TypeScript 类型定义
└── styles/              # 全局样式
```

## 🧪 测试

### 运行测试
```bash
# 单元测试
npm run test

# 端到端测试
npm run test:e2e

# 测试覆盖率
npm run test:coverage
```

### 编写测试
- 为新功能编写单元测试
- 确保测试覆盖率不低于 80%
- 使用描述性的测试名称
- 测试正常流程和边界条件

```typescript
describe('Button Component', () => {
  it('should render with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('should call onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    fireEvent.click(screen.getByText('Click me'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })
})
```

## 📚 文档

### 代码文档
- 为复杂函数添加 JSDoc 注释
- 保持 README 文件的更新
- 更新相关的 API 文档

```typescript
/**
 * 计算技术选项的优先级分数
 * @param options - 技术选项数组
 * @param weights - 权重配置
 * @returns 计算后的分数数组
 */
function calculatePriorityScores(
  options: TechOption[],
  weights: WeightConfig
): number[] {
  // 实现
}
```

### 文档更新
- 更新相关的 markdown 文档
- 保持示例代码的准确性
- 添加必要的截图或图表

## 🔍 代码审查

### 审查清单
- [ ] 代码遵循项目规范
- [ ] 有适当的测试覆盖
- [ ] 文档已更新
- [ ] 性能影响可接受
- [ ] 安全性考虑
- [ ] 向后兼容性
- [ ] 可访问性要求

### 审查流程
1. 创建 Pull Request
2. 自动化测试运行
3. 代码审查和讨论
4. 修改和完善
5. 批准并合并

## 🏷️ 版本发布

### 语义化版本控制
- `MAJOR`: 不兼容的 API 变更
- `MINOR`: 向后兼容的功能性新增
- `PATCH`: 向后兼容的问题修正

### 发布流程
1. 更新版本号
2. 更新 CHANGELOG
3. 创建 Git 标签
4. 发布到 GitHub Releases
5. 更新相关文档

## 💬 社区

### 讨论
- 使用 [GitHub Discussions](https://github.com/z004wtps/VB-Helps-VBer/discussions) 进行技术讨论
- 在 Issues 中提出具体问题
- 通过 Pull Request 进行代码审查讨论

### 行为准则
- 尊重所有贡献者
- 建设性的反馈和讨论
- 包容不同的观点和经验水平
- 专注于项目改进

## ❓ 获取帮助

如果您在贡献过程中遇到问题：

- 查看现有的 Issues 和 Discussions
- 阅读项目文档和代码注释
- 在 GitHub 上创建新的 Discussion
- 联系项目维护者

## 📧 联系信息

**项目维护者**: Jianan Huang  
**组织**: Siemens Healthineers  
**GitHub**: [@z004wtps](https://github.com/z004wtps)

---

再次感谢您的贡献！您的参与使这个项目变得更好。 🎉
