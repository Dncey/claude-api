# 构建阶段
FROM golang:1.24-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git ca-certificates tzdata

# 设置工作目录
WORKDIR /build

# 复制依赖文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 编译应用
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o claude-server main.go

# 运行阶段
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非特权用户
RUN addgroup -g 1000 claude && \
    adduser -D -u 1000 -G claude claude

# 设置工作目录
WORKDIR /app

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /build/claude-server .

# 复制前端静态文件
COPY --from=builder /build/frontend ./frontend

# 创建数据目录
RUN mkdir -p /app/data && chown -R claude:claude /app

# 切换到非特权用户
USER claude

# 暴露端口
EXPOSE 62311

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:62311/healthz || exit 1

# 启动应用
CMD ["./claude-server"]
