// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MyyToken
/// @notice 一个不依赖任何外部库的 ERC20 代币，可以直接复制到 Remix 里编译。
///         部署时会把 1,000,000 枚代币一次性发给部署者（msg.sender）。
/// @dev    之所以不用 import "@openzeppelin/...", 是为了避免 Remix 拉取外部依赖失败，
///         整个文件自成一体，复制粘贴即可编译。
contract MyyToken {
    // ------------------------------------------------------------------
    // 代币基本信息
    // ------------------------------------------------------------------

    /// @notice 代币全称
    string public name = "MyyToken";

    /// @notice 代币简称
    string public symbol = "MYY";

    /// @notice 精度：1 枚代币 = 10^18 个最小单位（wei）
    uint8 public constant decimals = 18;

    /// @notice 代币总发行量（最小单位）
    uint256 public totalSupply;

    // ------------------------------------------------------------------
    // 状态变量
    // ------------------------------------------------------------------

    /// @notice 每个地址拥有的代币数量
    mapping(address => uint256) private _balances;

    /// @notice 授权表：owner 允许 spender 花掉的额度
    mapping(address => mapping(address => uint256)) private _allowances;

    // ------------------------------------------------------------------
    // 事件（ERC20 标准事件，钱包和区块浏览器靠它们识别转账）
    // ------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ------------------------------------------------------------------
    // 构造函数
    // ------------------------------------------------------------------

    /// @notice 部署时铸造全部代币给部署者，无需构造参数，Remix 直接点 Deploy 即可
    constructor() {
        totalSupply = 1_000_000 * (10 ** uint256(decimals));
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ------------------------------------------------------------------
    // 只读方法
    // ------------------------------------------------------------------

    /// @notice 查询某个地址的余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice 查询 owner 授权给 spender 的剩余额度
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // ------------------------------------------------------------------
    // 写方法
    // ------------------------------------------------------------------

    /// @notice 自己转账给 to
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice 授权 spender 可以从自己账户里划走 amount 枚代币
    /// @dev    给 TokenBannk 授权就是靠这个方法：approve(bankAddress, amount)
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice 被授权方调用：把 from 的 amount 枚代币转给 to
    /// @dev    TokenBannk.deposit() 内部调用的就是这个方法
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "MyyToken: insufficient allowance");

        // type(uint256).max 表示「无限授权」，这种额度不递减，省 gas 也少一次写状态
        if (allowed != type(uint256).max) {
            _approve(from, msg.sender, allowed - amount);
        }

        _transfer(from, to, amount);
        return true;
    }

    // ------------------------------------------------------------------
    // 内部方法
    // ------------------------------------------------------------------

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "MyyToken: transfer to zero address");
        require(_balances[from] >= amount, "MyyToken: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "MyyToken: approve from zero address");
        require(spender != address(0), "MyyToken: approve to zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}
