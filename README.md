# USDT 网站部署说明（宝塔小白版）

一套程序同时提供**网站页面**和**接口**。按下面顺序做，做完就能打开域名、进后台。

---

## 一、你要准备什么

1. 一台已安装 **宝塔面板** 的 Linux 服务器  
2. 一个已解析到这台服务器的 **域名**（例如 `www.example.com`）  
3. 本项目的完整文件夹（上传后路径建议：`/www/wwwroot/usdt`）

---

## 二、在宝塔里先装软件

打开宝塔 → **软件商店**，安装：

| 软件 | 说明 |
|------|------|
| Nginx | 用来绑域名、开 HTTPS |
| Python 项目管理器 | 用来跑网站程序 |
| Node.js 版本管理器 | 用来打包前端页面（装完后装 Node **18** 或 **20**） |

再打开宝塔 → **数据库** → 上面点 **MongoDB**：

1. 先 **安装** MongoDB  
2. 点 **添加数据库**  
3. 数据库名填：`exchange_db`  
4. 用户名、密码自己设一串并**抄下来**（后面要写进配置文件）

> 没有单独建用户、本机不需要密码时，用户名和密码可以留空。

---

## 三、上传项目

把整个项目上传到服务器，例如：

```text
/www/wwwroot/usdt
```

上传后目录大致是：

```text
/www/wwwroot/usdt/
  backend/          ← 网站程序（Python）
  frontend/         ← 网页源码（要先打包）
  README.md
```

---

## 四、写环境变量（最重要）

所有配置都写在：

```text
/www/wwwroot/usdt/backend/.env
```

### 怎么创建这个文件

1. 宝塔 → **文件** → 进入 `backend` 目录  
2. 新建文件，名字必须是：`.env`（前面有个点，没有 `.txt`）  
3. 也可以先复制同目录的 `.env.example`，改名为 `.env`  
4. 用记事本打开，按下面填写，保存  

**改完 `.env` 必须重启 Python 项目才会生效。**

### 环境变量对照表

#### 必须填（不填网站/后台用不了）

| 变量名 | 填什么 | 例子 |
|--------|--------|------|
| `MONGO_HOST` | 数据库地址，本机固定这个 | `127.0.0.1` |
| `MONGO_PORT` | 数据库端口，一般不用改 | `27017` |
| `MONGO_DB` | 库名，和宝塔里建的一致 | `exchange_db` |
| `MONGO_USER` | 宝塔 MongoDB 用户名；没设用户就留空 | `usdt_user` |
| `MONGO_PASSWORD` | 宝塔 MongoDB 密码；没设就留空 | `你的数据库密码` |
| `JWT_SECRET` | 一长串随机字符，给后台登录凭证用。**不是**你日常登录密码 | 见下方「如何生成」 |
| `ADMIN_PASSWORD` | **第一次**进后台用的登录密码，至少 6 位。登录成功写入数据库后，建议删掉这一行再重启 | `MyStrongPass123` |

#### 强烈建议填

| 变量名 | 填什么 | 例子 |
|--------|--------|------|
| `ADMIN_PATH` | 后台入口路径，别人猜不到更好。浏览器打开：`https://你的域名` + 这个路径 | `/my-secret-admin` |

#### 可选（按需）

| 变量名 | 什么时候填 |
|--------|------------|
| `CORS_ORIGINS` | 换了新域名、浏览器提示跨域时。多个域名用英文逗号分隔，例如 `https://a.com,https://www.a.com` |
| `TG_WEBHOOK_SECRET` | 要用 Telegram **机器人指令**（例如把 IP 加白名单）时再填。日常「有消息提醒」不靠这项，到后台「设置」里填机器人 Token 和聊天 ID |
| `DEEPSEEK_API_KEY` | 后台翻译想用 DeepSeek 时再填。不填则用谷歌翻译 |
| `DEEPSEEK_BASE_URL` / `DEEPSEEK_MODEL` | 一般不用改 |
| `REACT_APP_API_URL` | **只有自己电脑开发前端时**才填。服务器部署不要填 |
| `MONGO_URL` | 一般不要填。填了会忽略上面的 `MONGO_HOST` 等，改用整串连接地址 |

### 一份可直接复制的模板

把下面粘贴进 `backend/.env`，再改成你自己的值：

```env
MONGO_HOST=127.0.0.1
MONGO_PORT=27017
MONGO_DB=exchange_db
MONGO_USER=这里填宝塔用户名
MONGO_PASSWORD=这里填宝塔密码

JWT_SECRET=这里换成很长的随机字符串
ADMIN_PASSWORD=这里填首次后台登录密码
ADMIN_PATH=/my-secret-admin
```

### 如何生成 JWT_SECRET

在你自己的 Windows 电脑打开 PowerShell，粘贴回车：

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

把输出的那一长串复制到 `.env` 的 `JWT_SECRET=` 后面。

Linux / 宝塔终端也可以：

```bash
openssl rand -base64 48
```

---

## 五、打包前端页面（必做）

没有这一步，打开域名往往只有接口、没有好看的页面。

1. 宝塔 → **终端**（或 SSH）  
2. 执行（路径按你实际上传位置改）：

```bash
cd /www/wwwroot/usdt/frontend
npm install
npm run build
```

3. 成功后会出现文件夹：`frontend/build`  
4. 以后改了前端代码，要重新执行一次 `npm run build`，再重启 Python 项目

---

## 六、用 Python 项目管理器启动

1. 宝塔 → **软件商店** → **Python 项目管理器** → **添加项目**  
2. 按下面填：

| 项 | 填法 |
|----|------|
| 项目名称 | 随便，例如 `usdt` |
| 项目路径 | `/www/wwwroot/usdt/backend`（必须是 **backend** 这一层） |
| Python 版本 | **3.11**（没有就选 3.10 / 3.12，尽量不要用太老的） |
| 框架 | 可留空或选其他；实际用启动命令跑 |
| 启动方式 / 启动文件 | 启动命令填：`bash start.sh` |
| 端口 | `8000` |
| 安装依赖模块 | 用 `requirements.txt`（就在 `backend` 目录里） |

3. 保存并 **启动**  
4. 看运行日志：应出现类似「数据库已连上」。若写「数据库没连上」，回去检查 `.env` 里的 Mongo 账号密码，并确认 MongoDB 已启动

程序只监听本机 `127.0.0.1:8000`，外网通过 Nginx 反向代理访问，这样更安全。

---

## 七、绑定域名并开 HTTPS

1. 宝塔 → **网站** → **添加站点**  
2. 域名填你的域名，根目录可随便（实际流量会转到程序）  
3. 站点设置 → **反向代理** → 添加：

   - 目标 URL：`http://127.0.0.1:8000`  
   - 发送域名：`$host`  

4. 打开站点 → **配置文件**，在反向代理相关 `location` 里确认有（没有就补上）：

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
client_max_body_size 8m;
```

5. 站点设置 → **SSL** → 申请 Let's Encrypt 证书 → 开启 **强制 HTTPS**  
6. 浏览器打开：`https://你的域名`，应能看到首页

---

## 八、第一次进后台

1. 浏览器打开：`https://你的域名` + `ADMIN_PATH`  
   例如 `ADMIN_PATH=/my-secret-admin` 时，地址是：  
   `https://你的域名/my-secret-admin`  
2. 密码填 `.env` 里的 **`ADMIN_PASSWORD`**  
3. 登录成功后，到后台 **设置**：  
   - 可再改一次更强的管理密码并保存  
   - 可改后台路径（改完用新地址打开）  
4. 密码已能正常登录后，建议从 `.env` **删掉 `ADMIN_PASSWORD` 那一行**，再在 Python 项目管理器里 **重启** 一次（之后只认数据库里的密码）

---

## 九、计划任务（没人开网页时的未读提醒）

有人开着后台时，程序自己会检查未读。  
**没人打开网站**时，需要宝塔每分钟访问一次：

1. 宝塔 → **计划任务** → **添加任务**  
2. 任务类型：访问 URL  
3. 执行周期：每 1 分钟  
4. URL 填（把域名换成你的）：

```text
https://你的域名/api/internal/unread-notify?key=q7Nw4Km9Xp2Lv8Rt6Yb3Hc1Jd5Fs0AeU
```

Telegram 机器人 Token、聊天 ID：在后台 **设置** 里填，并打开「Telegram 推送」开关。  
不必写进 `.env`（除非你要用机器人指令加白名单，那时再填 `TG_WEBHOOK_SECRET`）。

---

## 十、部署后自检清单

按顺序打开检查：

| 检查 | 怎么看 | 正常现象 |
|------|--------|----------|
| 健康接口 | 打开 `https://你的域名/api/health` | `"status":"ok"` 且 `"database":"connected"` |
| 首页 | 打开 `https://你的域名/` | 能看到网站首页，不是空白或纯接口字 |
| 后台入口 | 打开你设的 `ADMIN_PATH` | 出现登录框（不是被送回首页） |
| 后台登录 | 用 `ADMIN_PASSWORD`（首次）或已保存的密码 | 能进联系人/聊天/设置 |
| 访客聊天 | 首页点聊天，填姓名和以色列手机号 | 能发文字；后台能看到会话 |
| 改配置后 | 改了 `.env` | 已在 Python 项目管理器里重启 |

常见问题：

- **数据库 disconnected**：Mongo 没装/没启动，或 `.env` 账号密码/库名不对  
- **只有接口没有页面**：没执行 `npm run build`，或 `frontend/build` 不存在  
- **进不了后台 / 提示首次密码**：`.env` 没写 `ADMIN_PASSWORD`，或写完没重启  
- **提示 JWT 未配置**：`.env` 没写 `JWT_SECRET`，或写完没重启  
- **图片上传失败**：Nginx 里没有 `client_max_body_size 8m;`  
- **换域名后接口异常**：在 `.env` 加 `CORS_ORIGINS=https://新域名` 并重启  

---

## 十一、本地开发（可选，服务器可跳过）

1. 本机安装 MongoDB，并准备好 `backend/.env`  
2. 后端：

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn server:app --reload --host 127.0.0.1 --port 8000
```

3. 前端另开一个终端：

```bash
cd frontend
npm install
npm start
```

前端开发时可用 `REACT_APP_API_URL=http://127.0.0.1:8000`（写在 `frontend/.env` 或系统环境变量）。本地开发不要设 `ENV=production`，否则会走生产环境的密码规则。
