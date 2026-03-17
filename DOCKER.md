# Docker Compose 部署说明

## 快速开始

### 1. 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f claude-api

# 查看服务状态
docker-compose ps
```

### 2. 访问服务

- Web 控制台: http://localhost:62311
- API 端点: http://localhost:62311/v1
- 默认密码: `admin`

### 3. 停止服务

```bash
# 停止服务（保留数据）
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

## 配置说明

### 端口映射

默认映射到主机的 62311 端口，可以在 `docker-compose.yml` 中修改：

```yaml
ports:
  - "8080:62311"  # 映射到主机 8080 端口
```

### 数据持久化

数据库文件保存在 `./data` 目录：

```bash
# 查看数据文件
ls -la ./data/

# 备份数据
cp -r ./data ./data.backup.$(date +%Y%m%d)
```

### 环境变量

在 `docker-compose.yml` 中可配置的环境变量：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `PORT` | 服务端口 | `62311` |
| `DATA_DIR` | 数据目录 | `/app/data` |
| `NO_BROWSER` | 禁用浏览器自动打开 | `true` |
| `TZ` | 时区 | `Asia/Shanghai` |

### 自定义配置文件

如果需要使用 `config.yaml`：

```bash
# 1. 创建配置文件
cp config-mysql-example.yaml config.yaml

# 2. 编辑配置
vim config.yaml

# 3. 重启服务
docker-compose restart
```

## 常见操作

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 最近 100 行
docker-compose logs --tail=100

# 特定服务日志
docker-compose logs -f claude-api
```

### 重启服务

```bash
# 重启
docker-compose restart

# 重新构建并启动
docker-compose up -d --build
```

### 进入容器

```bash
# 进入容器 shell
docker-compose exec claude-api sh

# 查看进程
docker-compose exec claude-api ps aux
```

### 更新服务

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build --no-cache

# 重启服务
docker-compose up -d
```

## 生产环境建议

### 1. 使用 Nginx 反向代理

```yaml
# docker-compose.yml 添加 nginx 服务
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - claude-api
    networks:
      - claude-network
```

### 2. 配置资源限制

```yaml
services:
  claude-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 3. 定期备份

```bash
# 添加到 crontab
0 2 * * * cd /path/to/claude-api && tar -czf backup/data-$(date +\%Y\%m\%d).tar.gz data/
```

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker-compose logs claude-api

# 检查端口占用
lsof -i :62311

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 数据库权限问题

```bash
# 修复权限
sudo chown -R 1000:1000 ./data
```

### 健康检查失败

```bash
# 手动测试健康检查
docker-compose exec claude-api wget -O- http://localhost:62311/healthz

# 查看容器状态
docker-compose ps
```

## 卸载

```bash
# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi claude-api_claude-api

# 删除数据（谨慎操作）
rm -rf ./data
```
