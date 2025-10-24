# OneDrive Direct Upload Implementation

## 概述

本实现为OpenList添加了OneDrive直连上传功能。当启用此功能时，文件将直接从客户端浏览器上传到OneDrive，而不经过服务器中转，大大提高了上传效率并节省服务器带宽。

## 功能特性

### 后端实现

1. **OneDrive驱动配置扩展** (`drivers/onedrive/meta.go`)
   - 新增 `EnableDirectUpload` 配置字段
   - 默认值为 `false`，需要管理员手动启用

2. **直连上传URL获取** (`drivers/onedrive/util.go`)
   - 实现 `GetDirectUploadURL` 方法
   - 调用OneDrive API的 `createUploadSession` 接口
   - 返回可用于直接上传的uploadUrl

3. **API端点** (`server/handles/direct_upload.go`)
   - `GET /api/fs/check_direct_upload` - 检查当前路径是否启用直连上传
   - `POST /api/fs/get_direct_upload_url` - 获取直连上传URL和分块大小

### 前端实现

1. **直连上传实现** (`src/pages/home/uploads/direct.ts`)
   - 实现分块直连上传到OneDrive
   - 支持进度显示和速度计算
   - 使用标准的HTTP PUT请求和Content-Range头

2. **动态上传方式选择** (`src/pages/home/uploads/uploads.ts`)
   - 新增 `Direct` 上传选项
   - 实现 `checkDirectUpload` 函数检查是否启用
   - 当启用直连时，仅显示 `Direct` 选项
   - 未启用时显示 `Stream` 和 `Form` 选项

3. **UI更新** (`src/pages/home/uploads/Upload.tsx`)
   - 支持异步加载上传方式列表
   - 路径变化时自动重新检查可用上传方式
   - 动态显示/隐藏上传方式选择器

## 使用方法

### 管理员配置

1. 进入管理后台的存储管理页面
2. 编辑OneDrive存储配置
3. 找到 `Enable Direct Upload` 选项
4. 勾选启用
5. 保存配置

### 用户使用

1. 导航到已启用直连上传的OneDrive存储目录
2. 点击上传按钮
3. 系统会自动检测并显示 `Direct` 上传方式
4. 选择文件上传，文件将直接上传到OneDrive

## 技术实现细节

### 上传流程

1. **检查阶段**
   - 前端通过 `/api/fs/check_direct_upload` 检查当前路径是否支持直连
   - 如果支持，前端仅显示 `Direct` 上传选项

2. **获取URL阶段**
   - 用户选择文件后，前端调用 `/api/fs/get_direct_upload_url`
   - 后端调用OneDrive API的 `createUploadSession` 获取uploadUrl
   - 返回uploadUrl和推荐的分块大小（默认5MB）

3. **上传阶段**
   - 前端将文件分块
   - 使用标准HTTP PUT请求直接上传到OneDrive的uploadUrl
   - 每个分块带有 `Content-Range` 头指示位置
   - 显示实时进度和速度

### 与原有上传的区别

| 特性 | 传统上传 (Stream/Form) | 直连上传 (Direct) |
|------|----------------------|------------------|
| 数据流向 | 客户端 → 服务器 → OneDrive | 客户端 → OneDrive |
| 服务器负载 | 高（需要中转数据） | 低（仅获取URL） |
| 网络带宽 | 双倍（上传+转发） | 单倍 |
| 上传速度 | 受服务器带宽限制 | 仅受客户端带宽限制 |
| 适用场景 | 小文件、服务器网络好 | 大文件、客户端网络好 |

## 兼容性

- ✅ 仅影响启用了该功能的OneDrive存储
- ✅ 不影响其他存储类型（Aliyun、S3等）
- ✅ 不影响未启用直连的OneDrive存储
- ✅ 向后兼容，可随时启用/禁用

## 注意事项

1. **CORS限制**: OneDrive的uploadUrl已配置允许跨域访问，无需额外配置
2. **会话超时**: uploadUrl有效期约24小时，超时后需重新获取
3. **分块大小**: 建议使用5MB或10MB的分块大小以获得最佳性能
4. **失败重试**: 当前实现不支持断点续传，上传失败需要重新开始

## 文件清单

### 后端
- `drivers/onedrive/meta.go` - 添加配置字段
- `drivers/onedrive/util.go` - 实现GetDirectUploadURL方法
- `server/handles/direct_upload.go` - API处理器（新建）
- `server/router.go` - 路由注册

### 前端
- `src/pages/home/uploads/direct.ts` - 直连上传实现（新建）
- `src/pages/home/uploads/uploads.ts` - 上传方式管理
- `src/pages/home/uploads/Upload.tsx` - UI组件更新

## 测试建议

1. **功能测试**
   - 启用直连上传后，确认上传方式只显示 `Direct`
   - 禁用直连上传后，确认恢复显示 `Stream` 和 `Form`
   - 测试小文件（<5MB）和大文件（>100MB）上传
   - 测试文件夹上传

2. **边界测试**
   - 在不同路径下切换，确认正确检测
   - 测试网络中断后的错误提示
   - 测试超大文件（>1GB）的分块上传

3. **性能测试**
   - 对比直连上传和传统上传的速度
   - 监控服务器资源使用情况

## 参考资料

- [OneDrive API - Upload Large Files](https://learn.microsoft.com/en-us/onedrive/developer/rest-api/api/driveitem_createuploadsession)
- [OneManager-php 项目](https://github.com/qkqpttgf/OneManager-php)
