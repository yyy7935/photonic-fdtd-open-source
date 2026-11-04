# 开源 FDTD / 光学仿真选型评估

> 目的：项目五「从 0 开发 AI 原生 FDTD」的开源底座评估。
> 对象：附件 `blue_1121nm_14ceng_zhengshu.fsp` 这类 14 层膜/微纳结构，以及后续多层膜、超表面、等离激元、逆向设计等实验。
> 日期：2026-11-04

## 0. 先说结论

1. **附件 `.fsp` 不能直接被开源软件打开**。它是 Lumerical 私有二进制格式；开源路线要先拿到 14 层的材料/厚度、光源/监视器设置和参考光谱，再“按参数重建”，不是“导入 .fsp”。
2. **第一层先用 TMM**：如果 14 层是平面膜，`tmm` 几分钟就能出 R/T/A，用来验证材料与膜厚理解是否正确；不需要 FDTD。
3. **FDTD 底座首选 FDTDX 或 BeamZ**：两者都是 MIT/Apache 许可、GPU、2D/3D、支持色散（Drude/Lorentz/ADE）、有伴随/自动微分，适合做“AI + 逆向设计”的自研底座。
4. **Meep 只做对照/兜底**：最成熟、最可信，但是 GPL；如果最终软件要闭源交付，不要把 Meep 嵌进产品，单独部署做基准服务也要法务确认。
5. **RCWA 单独选 torcwa**：周期光栅/超表面用 RCWA 比 FDTD 快得多；torcwa 是 PyTorch + GPU + 可微，LGPL 需法务确认。S4 只做对照。
6. **不要从零手写 3D GPU FDTD 作为第一年目标**：2 人 12 个月不现实。自研重点放在“接口层、材料拟合、选算法、收敛判断、结果解读、基准集”，求解器用 MIT/Apache 底座二次开发或参考实现。

## 1. 候选项目对比

| 项目 | 许可 | 语言/硬件 | 2D/3D | 色散材料 | 伴随/可微 | 成熟度 | 在我们项目中的角色 |
|---|---|---|---|---|---|---|---|
| **TMM** (`sbyrnes321/tmm`) | MIT | Python/NumPy，CPU | 1D 多层膜 | 直接吃 n,k 表 | 无（可数值差分） | 高，稳定 | **必用**：平面多层膜基线、数据生成、快速验证 |
| **FDTDX** (`ymahlau/fdtdx`) | MIT | Python/JAX，NVIDIA GPU/多卡 | 2D/3D | Lorentz/Drude ADE | 自动微分 + 伴随/checkpoint | 较新（JOSS 2026），活跃 | **首选底座之一**：自研 FDTD 的架构参考/二次开发 |
| **BeamZ** (`beamzorg/beamz`) | Apache-2.0 | Python/JAX + CUDA，GPU | 真 2D/3D | PoleResidue、Drude、Lorentz，自带 `fit_nk` | 自动微分 + 伴随 | 很新（2026），功能全 | **首选底座之一**：光子学工作流更完整，做性能/功能对照 |
| **Meep** (`NanoComp/meep`) | GPL | C++/Python/Scheme，CPU/MPI | 1D/2D/3D | 支持色散材料 | 有 adjoint 模块 | 很高，20+ 年 | **对照/兜底**：基准真值、复现参考；闭源产品慎用 |
| **Ceviche** (`fancompute/ceviche`) | MIT | Python/NumPy+autograd，CPU | 2D/3D（FDFD/FDTD） | 以常数 ε 为主，未见完整色散 | 自动微分 | 研究代码，维护弱 | 仅做 2D 逆向设计教学/原型；不适合宽带金属 |
| **torcwa** (`kch3782/torcwa`) | LGPL | Python/PyTorch，GPU | RCWA（周期结构） | n,k 逐频点 | 可微 | 研究级，活跃 | **RCWA 分支首选**：光栅/超表面参数扫描、逆向设计 |
| **S4** (`victorliu/S4`) | GPL | C++/Python | RCWA | n,k | 无 | 高，稳定 | 只做 RCWA 对照；闭源产品不嵌入 |
| **flaport/fdtd** | MIT | Python/PyTorch，CPU/GPU | 3D | 常数 ε 为主 | PyTorch 可微 | 教学/研究 | 学习 Yee 更新参考；不作为生产核心 |
| **Tidy3D** | 商业（非开源） | 云端 GPU | 2D/3D | 支持 | 伴随 | 商业成熟 | 只做对标，不作为底座 |
| **Lumerical** | 商业 | CPU/GPU | 2D/3D | 支持 | 伴随 | 商业成熟 | 附件来源；复现参考，不装破解 |

## 2. 附件这类算例怎么选

附件特征（从 `.fsp` 读到）：14 层、TiO2/SiO2/Al2O3/Ag、2D FDTD、10000 fs、300 K、参数化 d/e/f、SS1 结构组里有 Au 结构脚本、R/T DFT 监视器。

| 问题 | 推荐工具 | 理由 |
|---|---|---|
| 14 层平面膜的 R/T/A 基线 | **TMM** | 1D 精确、秒级、直接吃 n,k；先验证膜厚/材料 |
| 2D 截面/非周期图案的 FDTD | **FDTDX 或 BeamZ** | GPU、2D、色散、PML/CPML、DFT 监视器；可微分方便后续逆向设计 |
| 与 Lumerical/论文结果对照 | **Meep** | 成熟、可信；GPL 只做外部对照 |
| 周期光栅/超表面参数扫描 | **torcwa** | RCWA 对周期结构远快于 FDTD；GPU + 可微 |
| 金属等离激元/局域场 | FDTD（FDTDX/BeamZ/Meep） | 宽带色散 + 复杂几何；GDM（pyGDM）可做补充但需核实许可 |
| 逆向设计/拓扑优化 | FDTDX / BeamZ / Meep adjoint / torcwa | 需要梯度；FDTDX 色散+梯度只支持 checkpointed，注意显存 |

**判断顺序**：先问“有没有周期/图案” → 没有图案先 TMM；有周期先用 RCWA；非周期/复杂 2D/3D 用 FDTD。不要一上来就跑 3D FDTD。

## 3. FDTDX vs BeamZ：怎么选

| 维度 | FDTDX | BeamZ |
|---|---|---|
| 许可 | MIT（可闭源商用，保留版权声明） | Apache-2.0（可闭源商用，保留 NOTICE） |
| 后端 | JAX，多 GPU | JAX + 专用 CUDA 后端，多 GPU |
| 2D | 支持（3D 框架里做 2D） | 真 2D/3D |
| 色散 | Lorentz/Drude ADE；色散梯度只能 checkpointed | PoleResidue/Drude/Lorentz；自带 n,k 拟合 `fit_nk` |
| 光子学工作流 | 通用 FDTD/逆向设计 | 模式源、DFT/S 参数、CPML、GDSFactory、光子芯片示例更全 |
| 成熟度 | JOSS 2026，论文/文档较完整 | 2026 新项目，功能多但生态更年轻 |
| 适合 | 想要干净、可读、可改的 JAX FDTD 架构 | 想要现成的光子学模式源/S 参数/CPML 工作流 |

**建议**：不要凭感觉二选一。用附件这个 14 层 2D 算例做一次 **两周 bake-off**：
1. 同一套材料/膜厚/光源/监视器，分别用 FDTDX、BeamZ、Meep 跑；
2. 与 Lumerical 或论文 R/T 比 MAE；
3. 记录单卡跑一个波长扫的时间、显存、色散拟合误差；
4. 看 API 稳定性/文档/issue 响应。
谁在“精度、速度、可维护性”三项综合更好，谁做主力；另一个做交叉校验。

## 4. 许可风险（重要）

| 许可 | 项目 | 能不能闭源商用 | 注意 |
|---|---|---|---|
| MIT | TMM、FDTDX、Ceviche、flaport/fdtd | 可以 | 保留版权/许可声明 |
| Apache-2.0 | BeamZ | 可以 | 保留 NOTICE，注意专利条款 |
| LGPL | torcwa | 通常可以（动态链接/独立进程） | 修改库本身要开源；法务确认边界 |
| GPL | Meep、S4 | 不建议嵌入闭源产品 | 衍生作品需 GPL；单独进程/服务也要法务确认 |
| 商业 | Lumerical、Tidy3D | 按合同 | 只做对标/参考 |

如果项目最终要交付客户/申请软著，**核心产品只依赖 MIT/Apache 代码**；GPL 工具放在“验证环境”，不随产品分发。

## 5. 建议的技术栈

```text
第一层（1D 基线）      TMM (MIT)
第二层（2D/3D FDTD）   FDTDX (MIT) 或 BeamZ (Apache) 二选一为主
第三层（RCWA）         torcwa (LGPL，法务确认)
对照/基准              Meep (GPL，外部服务) + Lumerical/Tidy3D
AI 编排                MCP Python SDK/FastMCP + Pydantic schema
优化                   Optuna / BoTorch / pymoo（按需要）
材料拟合               BeamZ fit_nk 或自研 Lorentz/Drude 拟合 + K-K/无源性校验
基准集                 pytest + TMM/Meep 真值 + 20 例自定义
```

**自研边界**：
- 自研：MCP 接口、材料拟合、算法选择、收敛判断、结果解读、基准集、AI 决策日志。
- 借用/参考：Yee 更新、PML/CPML、ADE 色散、伴随/自动微分（FDTDX/BeamZ，MIT/Apache）。
- 不碰：GPL 代码进闭源产品、Lumerical 私有格式解析、从零写 3D GPU 核心。

## 6. 六周落地顺序

| 周 | 做什么 | 产出 |
|---|---|---|
| 1 | 找邢博士要 14 层材料/厚度、光源/监视器、参考光谱；TMM 复现 | 第一张 R/T 对比图 |
| 2 | 用 Meep 搭同一 2D 算例，作为对照真值 | Meep vs TMM vs 参考 |
| 3 | FDTDX / BeamZ 各搭同一算例，跑通 2D + 色散 | 两套可运行脚本 |
| 4 | 三项打分：R/T 误差、单卡速度、显存/稳定性 | bake-off 结论 |
| 5 | 材料拟合 + 收敛判断原型；20 例基准 v0 | 误差报告 + 收敛报告 |
| 6 | MCP 包装：自然语言 → 结构 → 光谱 → 解读 | 可演示最小闭环 |

## 7. 参考链接

- TMM: https://github.com/sbyrnes321/tmm
- FDTDX: https://github.com/ymahlau/fdtdx ；文档 https://fdtdx.readthedocs.io/
- BeamZ: https://github.com/beamzorg/beamz
- Meep: https://github.com/NanoComp/meep ；伴随文档 https://meep.readthedocs.io/en/latest/Python_Tutorials/Adjoint_Solver/
- Ceviche: https://github.com/fancompute/ceviche
- torcwa: https://github.com/kch3782/torcwa
- S4: https://github.com/victorliu/S4
- flaport/fdtd: https://github.com/flaport/fdtd
- Tidy3D: https://www.flexcompute.com/tidy3d/

> 备注：FDTDX/BeamZ 都是研究级新项目，API 可能变；落地时锁定版本、写回归测试，不要直接当生产软件。
