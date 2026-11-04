# Photonic FDTD Open-Source Stack

> 面向 **AI 原生 FDTD / 光学仿真** 的开源项目选型与复现底座。  
> 维护：[@yyy7935](https://github.com/yyy7935)｜更新：2026-11-04

这个仓库把候选开源项目按 **P0 → P1 → P2** 排好序，并用 git submodule 引用上游代码，方便一次性拉取、对比和做 bake-off。仓库本身不复制第三方源码，许可证边界清晰。

## 怎么用

```bash
# 连子模块一起克隆
git clone --recurse-submodules https://github.com/yyy7935/photonic-fdtd-open-source.git
cd photonic-fdtd-open-source

# 或者先克隆，再初始化子模块
git submodule update --init --recursive --depth 1
```

Windows 也可以直接跑：

```powershell
.\scripts\clone-all.ps1
```

## 排序总表

### P0 · 先跑这三个

| # | 项目 | 许可 | 语言/硬件 | 在我们项目里的角色 |
|---|---|---|---|---|
| 1 | [TMM](https://github.com/sbyrnes321/tmm) | MIT | Python / CPU | **14 层平面膜基线**：直接吃 n,k，秒级出 R/T/A，先验证膜系理解 |
| 2 | [FDTDX](https://github.com/ymahlau/fdtdx) | MIT | Python / JAX / NVIDIA GPU | **2D/3D FDTD 主底座候选**：GPU、色散 ADE、自动微分/伴随 |
| 3 | [BeamZ](https://github.com/beamzorg/beamz) | Apache-2.0 | Python / JAX+CUDA / GPU | **FDTD 备选底座**：CPML、模式源、DFT/S 参数、PoleResidue/Drude/Lorentz、`fit_nk` |

### P1 · 对照与 RCWA

| # | 项目 | 许可 | 语言/硬件 | 在我们项目里的角色 |
|---|---|---|---|---|
| 4 | [Meep](https://github.com/NanoComp/meep) | GPL | C++/Python / CPU+MPI | **对照/兜底**：成熟 FDTD，做基准真值；闭源产品不要嵌入 |
| 5 | [torcwa](https://github.com/kch3782/torcwa) | LGPL | Python / PyTorch / GPU | **RCWA 首选**：周期光栅/超表面参数扫描、可微逆向设计 |

### P2 · 参考/教学

| # | 项目 | 许可 | 语言/硬件 | 在我们项目里的角色 |
|---|---|---|---|---|
| 6 | [S4](https://github.com/victorliu/S4) | GPL | C++/Python | RCWA 成熟对照；不嵌入闭源产品 |
| 7 | [Ceviche](https://github.com/fancompute/ceviche) | MIT | Python / NumPy+autograd | 2D 逆向设计教学原型；**色散不完整**，不适合宽带金属 |
| 8 | [flaport/fdtd](https://github.com/flaport/fdtd) | MIT | Python / PyTorch | 学习 Yee 更新和 3D FDTD 结构的参考，不作为生产核心 |

> Tidy3D、Lumerical 是商业软件，只做对标，不作为开源底座。

## 怎么选：按实验类型

| 实验/结构 | 首选 | 说明 |
|---|---|---|
| 14 层平面膜、彩色膜、辐射制冷膜 | **TMM** | 1D 精确；先用它验证材料/膜厚 |
| 2D 截面、非周期微纳结构、Au 等离激元 | **FDTDX 或 BeamZ** | GPU、2D、色散、PML/CPML、DFT 监视器 |
| 周期光栅、超表面、参数扫描 | **torcwa** | RCWA 比 FDTD 快一个量级；FDTD 只做最终验证 |
| 与 Lumerical/论文结果对照 | **Meep** | 成熟、可信；GPL 只做外部对照 |
| 逆向设计/拓扑优化 | FDTDX / BeamZ / Meep adjoint / torcwa | 需要梯度；注意显存和色散梯度限制 |

**判断顺序**：先看有没有横向图案 → 没有图案先 TMM；有周期先用 RCWA；非周期/复杂 2D/3D 用 FDTD。不要一上来跑 3D FDTD。

## 附件这类 `.fsp` 怎么处理

`.fsp` 是 Lumerical 私有格式，**开源软件不能直接打开**。正确流程：

1. 找邢博士要 14 层的材料/厚度、光源/监视器设置、参考光谱；
2. 用 **TMM** 重建平面膜，先对上 R/T；
3. 如果结构有横向图案/Au 结构，用 **FDTDX/BeamZ 2D** 重建；
4. 用 **Meep** 做第三方对照；
5. 偏差归因：网格、材料版本、膜厚、角度、PML。

## 许可证提醒

| 许可 | 项目 | 能否闭源商用 | 注意 |
|---|---|---|---|
| MIT | TMM、FDTDX、Ceviche、flaport/fdtd | 可以 | 保留版权/许可声明 |
| Apache-2.0 | BeamZ | 可以 | 保留 NOTICE，注意专利条款 |
| LGPL | torcwa | 通常可以（动态链接/独立进程） | 修改库本身要开源；法务确认边界 |
| GPL | Meep、S4 | 不建议嵌入闭源产品 | 衍生作品需 GPL；单独服务也要法务确认 |
| 商业 | Lumerical、Tidy3D | 按合同 | 只做对标 |

如果项目最终要交付客户/申请软著：**核心产品只依赖 MIT/Apache 代码**；GPL 工具放在验证环境，不随产品分发。

## 目录

```text
.
├── README.md
├── LICENSE
├── docs/
│   └── 01-selection.md        # 完整选型评估（对比、许可证、六周计划）
├── scripts/
│   ├── clone-all.ps1           # 无 submodule 时，一键 clone 到 vendor/
│   └── update-submodules.ps1   # 更新所有 submodule 到上游最新
└── vendor/                     # git submodules（不复制源码）
    ├── tmm/
    ├── fdtdx/
    ├── beamz/
    ├── meep/
    ├── torcwa/
    ├── S4/
    ├── ceviche/
    └── fdtd/
```

## 六周落地顺序

| 周 | 做什么 | 产出 |
|---|---|---|
| 1 | 14 层材料/厚度 + TMM 复现 | 第一张 R/T 对比图 |
| 2 | Meep 搭同一 2D 算例，做对照真值 | Meep vs TMM vs 参考 |
| 3 | FDTDX / BeamZ 各搭同一算例 | 两套可运行脚本 |
| 4 | 三项打分：R/T 误差、单卡速度、显存/稳定性 | bake-off 结论 |
| 5 | 材料拟合 + 收敛判断原型；20 例基准 v0 | 误差报告 + 收敛报告 |
| 6 | MCP 包装：自然语言 → 结构 → 光谱 → 解读 | 可演示最小闭环 |

## 免责声明

FDTDX、BeamZ 都是研究级新项目，API 可能变化；落地时锁定版本、写回归测试，不要直接当生产软件。各 submodule 的版权与许可归上游作者所有，详见各自 `LICENSE`。
