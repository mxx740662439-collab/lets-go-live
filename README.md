# Let's go live! — GitHub 导出包

这是当前已发布的 Godot 4.5.1 Web 游戏。背景音乐为 Pixel Daydream（200 BPM）。

## 游戏内容

- 粉黑霓虹像素风、Sayo 立绘、上下移动躲避聊天弹幕。
- 绿色弹幕每次增加 1 名观众，达到 100 名获胜。
- 初始 7 颗精神力红心。每次碰到红色弹幕损失 1 颗红心，但不扣观众。
- 每收集 5 条绿色弹幕恢复 1 颗红心；精神力归零结束直播。
- 英文开场、新手引导、三种弹幕阶段、胜败界面、音乐及音效。
- ↑/↓ 或 W/S 移动；Enter/点击推进对话；Esc 暂停；M 静音。

## 两种压缩包

1. lets-go-live-pages.zip：现成 Web 构建。index.html、index.js、index.wasm、index.pck 以及 worklet 文件必须一起部署，不能只上传 index.html。
2. lets-go-live-source.zip：Godot 工程代码、场景、PNG 等运行时美术素材、字体、音乐、音效、自定义 HTML 外壳，以及 docs/ 中的现成网页构建和 GitHub Pages 工作流。

源码包提供游戏运行和继续开发所需资源。不包含 .godot 缓存、历史 QA、生成过程日志、Blender 源工程或素材生产脚本。PNG 等已导出的美术资源包含在 assets/ 中。

## GitHub Pages 部署（推荐使用源码包）

1. 在自己的 GitHub 创建一个仓库。
2. 解压 lets-go-live-source.zip，把解压后的内容放在仓库根目录并提交到 main 分支。保留 .github/ 和 docs/.nojekyll 隐藏文件。
3. 在仓库 Settings → Pages → Build and deployment 中将 Source 设为 GitHub Actions。
4. 在 Actions 中运行 Deploy game to GitHub Pages；之后提交 main 分支也会自动部署。
5. 等工作流成功，打开 Pages 显示的访问地址。

如仅使用网页包，把它解压到仓库根目录，然后在 Pages 选择 Deploy from a branch → main → /(root)。不要把 ZIP 本身当成网站入口。

无需后端服务。此构建为单线程 Web 导出，不要求跨源隔离响应头。需支持 WebAssembly / WebGL 2 的现代浏览器。浏览器可能要求点击或按键后才能播放声音。

## 修改并重新导出

使用 Godot 4.5.1 打开 project.godot，并安装对应版本的官方 Export Templates。

```sh
godot --headless --path . --editor --import
godot --headless --path . --export-release Web docs/index.html
```

export_presets.cfg 已在包内移除本沙箱专用模板绝对路径，使用本机安装的官方导出模板。音频循环等 .import 配置保留。

修改后应在浏览器中测试，再提交新的 docs/ 文件。工作流发布 docs/ 的现成构建，不会自动编译工程。

## 文件说明

- scripts/：GDScript 游戏逻辑与 UI
- scenes/：Godot 场景
- assets/sprites/：角色、表情、UI 等图片
- assets/fonts/：字体及已有许可文件
- audio/：当前背景音乐、对话提示音、收集/受伤/胜败音效
- ui/shell.html：Web 加载页模板
- docs/：可直接部署的游戏网页构建

已保留现有字体许可文件。本导出未为代码或用户提供的素材新增开源许可证；公开仓库前请按实际权利情况选择许可证。未在你的 GitHub 账户创建仓库或执行部署。
