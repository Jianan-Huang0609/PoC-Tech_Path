#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

/**
 * 更新日志生成器
 * 自动在 update.md 中追加提交记录
 */

// 获取命令行参数
const [date, commitHash, branch, commitMsg, author] = process.argv.slice(2);

if (!date || !commitHash || !branch || !commitMsg || !author) {
  console.error('❌ 缺少必要参数');
  console.log('用法: node update-log.mjs <日期> <提交哈希> <分支> <提交信息> <作者>');
  process.exit(1);
}

const updateLogPath = path.join(process.cwd(), 'update.md');

try {
  // 读取现有的更新日志
  let content = fs.readFileSync(updateLogPath, 'utf8');
  
  // 找到提交记录表格的位置
  const tableStart = content.indexOf('| 日期 | 版本 | 分支 | 短哈希 | 摘要（作者） |');
  const tableEnd = content.indexOf('---', tableStart);
  
  if (tableStart === -1) {
    console.error('❌ 未找到提交记录表格');
    process.exit(1);
  }
  
  // 构建新的提交记录行
  const newRecord = `| ${date} | - | ${branch} | ${commitHash} | ${commitMsg} (${author}) |`;
  
  // 在表格头部后插入新记录
  const beforeTable = content.substring(0, tableStart + 1);
  const afterTable = content.substring(tableStart + 1);
  
  // 找到表格内容的开始位置（跳过表头）
  const contentStart = afterTable.indexOf('\n') + 1;
  const tableContent = afterTable.substring(0, contentStart);
  const remainingContent = afterTable.substring(contentStart);
  
  // 组合新的内容
  const newContent = beforeTable + 
                    afterTable.substring(0, contentStart) + 
                    newRecord + '\n' + 
                    remainingContent;
  
  // 写回文件
  fs.writeFileSync(updateLogPath, newContent, 'utf8');
  
  console.log('✅ 更新日志已更新');
  console.log(`📝 记录: ${date} | ${branch} | ${commitHash} | ${commitMsg}`);
  
} catch (error) {
  console.error('❌ 更新日志失败:', error.message);
  process.exit(1);
}
