# OneDrive 直连上传故障排查

## 常见错误

### 1. "Resource not found for the segment 'root:XXX'"

**错误示例：**
```
Resource not found for the segment 'root:ABDownloadManager.exe'
```

**原因：**
这个错误表示传递给OneDrive API的路径格式不正确，缺少前导斜杠。

**解决方案：**

已在最新代码中修复此问题。修复内容包括：

#### 后端修复 (`drivers/onedrive/util.go`)
```go
// Build file path - ensure it starts with /
dirPath := dstDir.GetPath()
if dirPath == "" {
    dirPath = "/"
}
filePath := stdpath.Join(dirPath, fileName)
```

#### 前端修复 (`src/pages/home/uploads/direct.ts`)
```typescript
// Get directory path and file name
const pathParts = uploadPath.split("/").filter(p => p !== "")
const fileName = pathParts.pop() || file.name
const dirPath = pathParts.length > 0 ? "/" + pathParts.join("/") : "/"
```

**测试步骤：**
1. 重新编译后端（Go）
2. 重新编译前端（npm run build）
3. 重启服务
4. 尝试在根目录上传文件

### 2. 文件名包含特殊字符

**症状：**
- 文件名包含空格、中文、特殊符号时上传失败

**解决方案：**
- OneDrive驱动的 `GetMetaUrl` 方法会自动调用 `utils.EncodePath` 进行URL编码
- 确保文件名按原样传递，不要手动编码

### 3. "Direct upload is not enabled"

**原因：**
存储未启用直连上传功能

**解决方案：**
1. 进入管理后台
2. 存储管理 → 编辑对应的OneDrive存储
3. 勾选 "Enable Direct Upload"
4. 保存配置

### 4. Upload Session超时

**症状：**
- 上传大文件时中途失败
- 错误信息包含 "session" 或 "expired"

**原因：**
OneDrive的upload session有效期约24小时，但实际可能更短

**解决方案：**
- 当前实现不支持断点续传
- 上传失败后需要重新开始
- 建议上传大文件时保持网络稳定

### 5. CORS错误

**症状：**
- 浏览器控制台显示跨域错误
- 无法连接到OneDrive的uploadUrl

**原因：**
OneDrive的uploadUrl已配置允许跨域访问，这个问题不应该出现

**解决方案：**
- 检查浏览器是否禁用了跨域请求
- 检查是否有浏览器插件干扰
- 尝试在隐私模式下测试

## 调试方法

### 启用调试日志

#### 后端调试
在 `server/handles/direct_upload.go` 中，取消注释调试日志：
```go
utils.Log.Debugf("[DirectUpload] DirPath: %s, FileName: %s, FullPath: %s", 
    dir.GetPath(), req.FileName, path)
```

#### 前端调试
在浏览器控制台查看：
1. 打开浏览器开发者工具 (F12)
2. 切换到 Network 标签
3. 过滤 "get_direct_upload_url"
4. 查看请求和响应内容

### 检查路径格式

**正确的路径格式：**
- 根目录：`/`
- 一级目录：`/folder`
- 多级目录：`/folder1/folder2`
- 根目录文件：文件名 `ABDownloadManager.exe`，目录路径 `/`
- 子目录文件：文件名 `test.txt`，目录路径 `/Documents`

**错误的路径格式：**
- ❌ 空字符串（应该是 `/`）
- ❌ 不以 `/` 开头的路径（如 `folder` 应该是 `/folder`）
- ❌ 以 `/` 结尾的路径（如 `/folder/` 应该是 `/folder`）

### 验证OneDrive API调用

使用以下命令手动测试OneDrive API：

```bash
# 1. 获取access token（从数据库或配置中）
TOKEN="your_access_token"

# 2. 创建上传会话
curl -X POST \
  "https://graph.microsoft.com/v1.0/me/drive/root:/test.txt:/createUploadSession" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "item": {
      "@microsoft.graph.conflictBehavior": "rename"
    }
  }'
```

成功响应应包含 `uploadUrl` 字段。

## 性能优化建议

1. **调整分块大小**
   - 小文件：使用默认5MB
   - 大文件：可以在OneDrive存储配置中调整 `ChunkSize`
   - 建议范围：5-10MB

2. **网络条件**
   - 直连上传依赖客户端到OneDrive的网络速度
   - 如果客户端网络较慢，传统上传可能更快
   - 如果服务器网络较慢，直连上传明显更快

3. **并发上传**
   - 当前实现是串行上传分块
   - 可以修改 `direct.ts` 实现并发上传以提高速度
   - 注意：OneDrive API对并发有限制

## 回退方案

如果直连上传出现问题，可以临时禁用：

1. **方案A：禁用存储的直连功能**
   - 管理后台 → 存储管理
   - 编辑OneDrive存储
   - 取消勾选 "Enable Direct Upload"

2. **方案B：前端强制使用传统上传**
   - 修改 `uploads.ts`
   - 注释掉 Direct 上传选项
   - 重新编译前端

## 联系支持

如果以上方法都无法解决问题，请提供以下信息：

1. 错误截图
2. 浏览器控制台日志
3. 后端服务日志
4. OneDrive存储配置（隐藏敏感信息）
5. 文件名和大小
6. 上传的目录路径

## 更新历史

- 2025-01-24: 修复根目录上传路径格式问题
- 2025-01-24: 改进前端路径解析逻辑
- 2025-01-24: 添加调试日志支持
