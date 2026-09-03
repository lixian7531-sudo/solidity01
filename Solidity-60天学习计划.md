# Solidity 60 天学习计划（可执行版）

> 适用对象：有基础编程经验（如 Python）、区块链几乎零基础。  
> 投入：工作日每天 2–3 小时，周末可加量补进度或做项目。  
> 目标：60 天后能独立编写、测试、部署智能合约，并能讲解常见安全漏洞，至少交付 1 个带前端、可演示的毕业项目。

---

## 一、60 天总览

| 阶段 | 天数 | 主题 | 里程碑交付 |
|---|---|---|---|
| 1 | Day 1–7 | 区块链与 Solidity 基础（Remix 为主） | 第一个可部署合约 + 概念笔记 |
| 2 | Day 8–14 | 数据结构、继承、事件、跨合约调用 | 白名单/投票合约上线 Sepolia 测试网 |
| 3 | Day 15–21 | Hardhat 工程化 + ERC20/ERC721 | 代币/NFT 合约 + 完整单元测试 |
| 4 | Day 22–28 | Foundry + 工厂模式 + 模糊测试 | 工厂注册表项目 + fuzz 测试 |
| 5 | Day 29–35 | 安全入门 | 攻防实验 + Ethernaut 前 10 关笔记 |
| 6 | Day 36–42 | DeFi 核心概念 | 时间锁金库/托管合约 + 测试 |
| 7 | Day 43–49 | 毕业项目：合约开发 | 核心合约 + 高覆盖测试 + 自查 |
| 8 | Day 50–60 | 前端、部署、文档、收尾 | 完整可演示项目 + 博客 + 路线图 |

---

## 二、每天固定节奏（模板）

1. **10 分钟**：回看昨天的笔记 + `git log`，快速回忆。
2. **60–90 分钟**：学新概念（官方文档为主，Updraft 视频为辅）。
3. **45–60 分钟**：亲手写合约/测试——只看思路，不整段抄。
4. **10 分钟**：收尾提交，格式固定为 `Day NN: 主题一句话`。

**铁律**：当天代码当天跑通。跑不通就记下报错原文，明天先解决再学新课。

---

## 三、仓库结构（Day 1 先建好）

```text
C:\solidity01\
├─ notes\            # 每天一篇学习笔记（day01.md … day60.md）
├─ contracts\        # 平时练习的小合约（按周分子目录）
├─ projects\         # 每周项目 + 最终毕业项目
└─ 其他你已有的 Python 文件保持不变
```

每天结束前 `git add -A` + `git commit -m "Day NN: ..."`。60 天后你的提交历史本身就是学习证明。

---

## 四、核心资源（长期固定使用）

- Solidity 官方文档（第一优先级，当字典查）：<https://docs.soliditylang.org>
- Remix 在线 IDE：<https://remix.ethereum.org>
- Cyfrin Updraft Solidity 免费课程（主线视频课）：<https://updraft.cyfrin.io/courses/solidity>
- Hardhat：<https://hardhat.org>
- Foundry Book：<https://book.getfoundry.sh>
- OpenZeppelin 合约库：<https://docs.openzeppelin.com/contracts>
- Ethernaut 攻防闯关：<https://ethernaut.openzeppelin.com>
- Chainlink 数据预言机文档：<https://docs.chain.link/data-feeds>
- 中文社区：登链社区 <https://learnblockchain.cn>（翻译+文章质量好）
- 审计报告阅读：<https://solodit.xyz>、Secureum：<https://secureum.substack.com>

测试网水龙头（faucet）经常更换，别买测试币。需要时到 ethereum.org 或登链社区搜“Sepolia faucet”，选当前可用的即可。

---

## 五、逐日计划

### 第 1 周（Day 1–7）：区块链基础 + 第一个合约

- **Day 1｜区块链是什么**：读 ethereum.org 中文版“以太坊是什么/账户/交易/Gas”。看 Updraft Blockchain Basics 前几节。**产出**：`notes/day01.md`，用你自己的话写清：区块、交易、EOA 与合约账户、Gas、确认数。提交。
- **Day 2｜钱包 + 测试网**：安装 MetaMask，创建账户；添加 Sepolia 测试网并领测试币；体验一次转账。**产出**：成功转账记录截图或哈希 + 笔记“测试币≠真钱”。提交。
- **Day 3｜Remix + 第一个合约**：打开 Remix，新建 `HelloWorld.sol`：`string` 状态变量 + `set`/`get`。编译并在 Remix VM 部署。**产出**：能独立解释 pragma、contract、状态变量；合约跑通。提交。
- **Day 4｜值类型**：学 bool/int/uint/address/address payable/bytesN 与字面量；做一个小“计算器”合约（加减乘除、取余）。**产出**：知道 0.8 默认防溢出，能说出 uint256 范围。提交。
- **Day 5｜函数与可见性**：public/external/internal/private、view/pure/payable、返回值与多返回值。改造计算器加入只有 owner 能用的函数。**产出**：能画出“四种可见性谁能调用”表格。提交。
- **Day 6｜错误处理**：require/revert/assert 的区别与使用场景；给计算器加除数非零检查。**产出**：能解释“失败即回滚”，写清三种报错用法的差异。提交。
- **Day 7｜复盘周**：不参考笔记重写 Day 3–6 的合约；列出本周不懂的 5 个问题并逐个查清。**产出**：`notes/week1-review.md` 自查清单全过。提交。

### 第 2 周（Day 8–14）：数据、继承、事件、合约交互

- **Day 8｜数组与存储位置**：动态/定长数组、push/pop/length；storage/memory/calldata 第一次系统学；写“名单数组”合约。**产出**：能解释“数组存了谁、改给谁”。提交。
- **Day 9｜mapping**：mapping 语法与特性（不可遍历、默认值）；写 `address => uint` 积分合约。**产出**：能说明为什么遍历需要额外维护数组。提交。
- **Day 10｜struct + enum**：写用户注册合约：struct + mapping + struct 数组组合。**产出**：完成增查改删并用事件记录变化。提交。
- **Day 11｜事件 event**：事件的作用（低成本日志、前端监听）；indexed 参数；在 Remix 里看解码日志。**产出**：给 Day 10 合约补全事件并验证日志。提交。
- **Day 12｜继承**：is、virtual/override、super、构造函数传参；手写一个 Ownable（owner 初始化 + modifier）。**产出**：说清“先执行哪个构造函数”，练习通过。提交。
- **Day 13｜接口与跨合约调用**：interface + 地址调用其他合约；抽象合约概念；在 Remix 里 import OpenZeppelin 或 GitHub 源码。**产出**：A 合约能调用 B 合约的公开函数。提交。
- **Day 14｜周项目：白名单/投票合约**：用本周知识做“投票”合约（候选人 struct、投票、防重复、owner 开票），Remix 部署到 Sepolia 并验证源码。**产出**：测试网地址 + 交互成功。提交。

### 第 3 周（Day 15–21）：工程化 + 代币标准

- **Day 15｜本地环境**：安装 Node.js LTS（nodejs.org）、VS Code + Solidity 插件；`npx hardhat init` 建 TypeScript 工程并跑通示例测试。**产出**：`npx hardhat test` 全绿。提交。
- **Day 16｜Hardhat 测试**：用 ethers 写 Counter 合约测试：部署、调用、断言；学 describe/it、`expect(...).to.be.revertedWith`。**产出**：测试能抓住故意引入的 bug。提交。
- **Day 17｜ERC-20 规范**：读 EIP-20 原文；手写最小 MyToken（totalSupply/balanceOf/transfer/approve/transferFrom + 事件）。**产出**：说出 approve 与 transferFrom 为什么是两段式。提交。
- **Day 18｜OpenZeppelin ERC20**：用 OZ 实现带 mint 的 Token（配合 Ownable），在 Hardhat 里补全套单元测试。**产出**：测试覆盖 transfer/approve/授权扣款边界。提交。
- **Day 19｜测试强化**：学 solidity-coverage 覆盖率报告与 gas reporter；给 Day 18 合约补到 80%+ 覆盖率；用 `hardhat console` 调试。**产出**：覆盖率截图进笔记。提交。
- **Day 20｜ERC-721**：概念：tokenId、ownerOf、tokenURI、授权；用 OZ 写 MyNFT + mint 限制；测试再补。**产出**：能讲清 NFT“存的是所有权不是图片”。提交。
- **Day 21｜周项目：会员卡合约**：一个合约同时发 ERC20（积分）+ ERC721（会员卡），写完整测试；部署 Sepolia 并验证。**产出**：README + 测试网地址。提交。

### 第 4 周（Day 22–28）：Foundry + 工厂与库

- **Day 22｜Foundry 安装**：按官方文档安装 Foundry（Windows 用 Git Bash 跑 foundryup，或用官方发布二进制）；`forge init` + `forge test` 跑通；本地链 `anvil`。**产出**：forge/cast/anvil 三个命令可用。提交。
- **Day 23｜Foundry 测试**：用 Solidity 写测试：setUp、test 函数、断言；把 MyToken 测试移植一份到 Foundry。**产出**：forge test 全绿；对比 Hardhat/Foundry 各自优劣记笔记。提交。
- **Day 24｜作弊码 cheatcodes**：vm.prank/startPrank、vm.deal、vm.expectRevert、vm.expectEmit；补“只有 owner 能 mint”与“非 owner 被拒”两类测试。**产出**：能用作弊码模拟任意账户。提交。
- **Day 25｜模糊测试入门**：用随机参数 fuzz 数学函数与代币转移；验证 0.8 溢出保护。**产出**：写 2 个 fuzz 测试并解释它帮你找到了什么。提交。
- **Day 26｜工厂模式**：学“工厂合约部署子合约并登记地址”；参考 Updraft StorageFactory 练习写 RegistrationFactory。**产出**：工厂+子合约+查询列表跑通。提交。
- **Day 27｜库与 using-for**：写一个自己的 SafeMath 替代演示（0.8 不需要它，但用来学 library 语法）；学 `using X for Y`；在 Hardhat 里 npm 安装并使用 OZ。**产出**：理解库代码在哪执行（deployed 还是 internal）。提交。
- **Day 28｜周项目：合约工厂注册表**：工厂每次部署子合约自动登记，配 Foundry 常规测试 + fuzz + Hardhat 部署脚本，部署 Sepolia。**产出**：项目 README + 测试网地址。提交。

### 第 5 周（Day 29–35）：安全入门

- **Day 29｜安全地图**：看 Updraft Security 入门或 Secureum 清单；建立“漏洞分类表”：重入、访问控制、溢出、预言机、DoS、抢先交易。**产出**：每类写 1 行“是什么 + 一句话例子”。提交。
- **Day 30｜重入攻击（上）**：写一个含漏洞的提款合约 + 攻击合约，跑通攻击流程；再用 Checks-Effects-Interactions 修复。**产出**：能逐行讲解攻击如何发生。提交。
- **Day 31｜重入攻击（下）**：引入 OpenZeppelin ReentrancyGuard；测试“修复前后行为差异”；了解跨函数重入与 ERC-777 回调风险。**产出**：3 条“防重入自检清单”。提交。
- **Day 32｜访问控制**：msg.sender vs tx.origin 攻击演示；手写 Ownable 的漏洞版再修复；学 OZ AccessControl 角色管理。**产出**：知道为什么不要用 tx.origin 做鉴权。提交。
- **Day 33｜delegatecall 与代理**：学 call/delegatecall 区别、存储槽冲突、initialize 模式；跑一个最小代理演示。**产出**：能画出“逻辑合约改状态发生在谁的存储里”。提交。
- **Day 34｜抢先交易与预言机**：概念学习：滑点、AMM 价格操纵、Commit-Reveal；看 Chainlink 文档了解去中心化喂价。**产出**：笔记含 1 个真实案例链接。提交。
- **Day 35｜Ethernaut 实战**：打穿 Ethernaut Level 1–6（含 Re-entrancy、Delegation 等），每题写攻击思路笔记。**产出**：`notes/ethernaut-1-6.md` + 过关截图。提交。

### 第 6 周（Day 36–42）：DeFi 核心概念

- **Day 36｜Ethernaut 续 + 复盘**：继续 Level 7–10；把前 10 关按漏洞类型归档到安全笔记。**产出**：10 关全过（卡住可看提示，但要能复述原理）。提交。
- **Day 37｜DeFi 全景**：读一篇 DEX/借贷/稳定币概览；手推 AMM 公式 x·y=k 与滑点；做笔记含简单算例。**产出**：能向别人解释“做市商赚什么”。提交。
- **Day 38｜AMM 数学合约（教学）**：写一个纯函数合约模拟 swap 前后数量（仅教学，不部署生产）；配 fuzz 验证“乘积不减少”。**产出**：数学公式变成可运行代码。提交。
- **Day 39｜预言机集成**：在 Sepolia 用 Chainlink ETH/USD Data Feed 部署“显示最新价”合约；测试里用 mock 喂价。**产出**：合约返回实时价格。提交。
- **Day 40｜借贷概念**：抵押率、健康因子、清算阈值；写最小“抵押金库”：存款抵押、按抵押率借出稳定币（教学简化版）。**产出**：能解释为什么需要超额抵押。提交。
- **Day 41｜提款模式与 Pull-Payment**：给金库合约补 withdraw pattern、deadline、receive/fallback 安全处理；写测试覆盖超时与提前取回。**产出**：理解“谁发起转账谁付 gas”的实践意义。提交。
- **Day 42｜周项目：时间锁金库/托管**：二选一做成带时间锁与事件日志的合约（如：锁定 ETH 到期才能取），完整测试 + 部署 Sepolia。**产出**：README + 测试网地址。提交。

### 第 7 周（Day 43–49）：毕业项目——合约部分

建议项目（三选一）：**A. NFT 市场**（上架/购买/下架/可选竞价，含手续费）；**B. 任务赏金平台**；**C. 迷你 DAO**（提案/投票/金库执行）。以下按 A 示例展开，选 B/C 则替换对应功能。

- **Day 43｜定需求与架构**：写 `projects/<项目>/README.md`：功能列表、非功能要求、边界（谁能操作、什么状态能转什么状态）；画数据流图。**产出**：文档被“未来的你”能看懂。提交。
- **Day 44｜数据与接口设计**：定 struct/mapping/event/函数签名；只写骨架让合约能编译。**产出**：一份干净的类型设计，不急着写逻辑。提交。
- **Day 45｜模块一：上架/下架**：实现 listing 创建与取消（access control + 事件 + 状态校验），写单元测试。**产出**：核心状态机先跑通。提交。
- **Day 46｜模块二：购买与结算**：实现 buy：校验在架、付款、CEI 顺序、向卖家转款（或可提现），手续费预留；加 ReentrancyGuard。**产出**：买卖全流程测试通过。提交。
- **Day 47｜模块三（扩展）**：实现竞价/出价或版税；写测试覆盖恶意用例（重复出价、出价后被下架等）。**产出**：扩展功能 + 边界测试。提交。
- **Day 48｜测试总攻**：补集成测试 + fuzz；覆盖率目标 ≥ 80%；故意制造 5 个 bug 让测试抓住再修复。**产出**：覆盖率报告 + 测试全绿。提交。
- **Day 49｜安全自查**：按 Week 5 漏洞表逐项自查；安装 slither（用 Python 3.12 建独立虚拟环境：`pip install slither-analyzer`）扫合约并修复高优告警。**产出**：自查清单 + slither 报告归档。提交。

### 第 8 周（Day 50–60）：前端、部署、收尾

- **Day 50｜部署到 Sepolia**：写部署脚本；验证源码；准备好项目里所有合约地址与 ABI。**产出**：Etherscan/Sepolia 浏览器上源码已验证。提交。
- **Day 51｜前端骨架**：Vite + React 起项目，安装 viem（或 ethers）；连接钱包并读取合约只读数据。**产出**：页面上出现链上数据。提交。
- **Day 52｜前端写交易**：实现“上架/购买/取消”交互：发起交易、等待确认、处理失败回滚与 Loading。**产出**：不用 Remix 也能完整走通主流程。提交。
- **Day 53｜前端完善**：展示事件历史、空状态/错误态；在 Sepolia 端到端演示一遍并录屏。**产出**：3–5 分钟演示视频。提交。
- **Day 54｜项目文档**：写完整 README：架构图、功能、部署步骤、技术栈、安全说明；整理 `.env.example`（密钥绝不入库）。**产出**：陌生人能按 README 跑起来。提交。
- **Day 55｜写技术博客**：在登链社区/Mirror 发一篇项目复盘（架构决策 + 踩坑 + 安全取舍）。**产出**：文章链接进 README。提交。
- **Day 56｜缓冲日**：修遗留问题、补测试、重构重复代码、更新周笔记索引。**产出**：整个仓库无红色 TODO。提交。
- **Day 57｜读审计报告**：在 Solodit 精读 2–3 份真实审计报告（重点：标题、影响、修复 diff），摘录 5 条“我也可能犯”的教训。**产出**：`notes/audit-lessons.md`。提交。
- **Day 58｜作品集整理**：把 5 个周项目 + 毕业项目统一 README 风格；补截图/演示链接；检查仓库没有私钥、测试网地址等敏感信息。**产出**：可对外展示的 GitHub 主页/仓库列表。提交。
- **Day 59｜进阶路线规划**：确定下一阶段方向（合约审计 / DeFi 协议开发 / EVM 底层 + Yul / ERC-4337 账户抽象 / L2）；列出下一个 90 天计划。**产出**：`notes/roadmap-next-90.md`。提交。
- **Day 60｜结业验收**：对照总览表逐项打勾；不看代码重新口述每个项目的架构与安全点；写 `notes/graduation.md`（60 天总结 + 数据：提交数、合约数、测试数）。**产出**：完整的 60 天提交历史 + 一篇总结。提交并庆祝。

---

## 六、完成标准（随时自检）

- 能不看文档写出：带事件的 ERC20、Ownable、时间锁、工厂。
- 能解释：为什么 0.8 还要防溢出、CEI 为什么有效、delegatecall 风险、tx.origin 为什么危险。
- 能独立完成：合约 → 测试 → 部署 → 验证 → 前端交互全流程。
- 每类安全漏洞能说出“攻击路径 + 修复方式 + 一个真实案例”。

## 七、安全提醒（每天读一遍）

1. 私钥只放在本地 `.env`（已 gitignore），绝不提交、绝不发给别人。
2. 两个月内只碰测试网与假钱；上主网前先找有经验的人 review。
3. 别直接复制网上/AI 生成的合约上线——每个函数都要能讲清为什么这样写。
4. “合约一旦部署不可更改”是常态：宁可多写测试，不要急着部署。
5. 工具链迭代很快（2026 年 Solidity/Foundry/Hardhat 都在更新），遇到报错先查官方文档的当前版本，再问 AI。

