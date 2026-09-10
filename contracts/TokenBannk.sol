// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IERC20
/// @notice 最小可用的 ERC20 接口，只要代币实现了这几个方法，就能存进本银行。
/// @dev    写在同一个文件里，这样本文件不需要 import，复制到 Remix 单独编译也不会报错。
///         只要接口方法签名一致，MyyToken 以及任何标准 ERC20 代币都能用。
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title TokenBannk
/// @notice 代币银行：用户调用 deposit 把 MyyToken 存进来，合约按地址记录每人存了多少；
///         管理员（部署这个合约的人）可以调用 withdraw 一次性取走合约里的全部代币。
/// @dev    典型的两文件结构：
///         1) 先部署 MyyToken，复制它的合约地址；
///         2) 部署 TokenBannk 时把这个地址填进构造函数；
///         3) 用户先 approve(银行地址, 数量)，再调用 deposit(数量)。
contract TokenBannk {
    // ------------------------------------------------------------------
    // 状态变量
    // ------------------------------------------------------------------

    /// @notice 本银行支持的代币合约（部署后不可更改）
    IERC20 public immutable token;

    /// @notice 管理员地址，部署者即管理员
    address public immutable admin;

    /// @notice 每个用户累计存入的代币数量：[用户地址] => 数量
    /// @dev    声明为 public，Remix 里会自动生成 deposits(address) 查询按钮
    mapping(address => uint256) public deposits;

    /// @notice 所有用户存入数量的总和，方便一眼看出银行总账
    uint256 public totalDeposits;

    /// @notice 重入锁
    bool private locked;

    // ------------------------------------------------------------------
    // 事件
    // ------------------------------------------------------------------

    /// @param user         存款人
    /// @param amount       本次存入数量
    /// @param userBalance  存入后该用户在银行里的累计存款
    event Deposited(address indexed user, uint256 amount, uint256 userBalance);

    /// @param admin  提款的管理员
    /// @param amount 本次提走的数量
    event AdminWithdrawn(address indexed admin, uint256 amount);

    // ------------------------------------------------------------------
    // 修饰器
    // ------------------------------------------------------------------

    modifier onlyAdmin() {
        require(msg.sender == admin, "TokenBannk: caller is not admin");
        _;
    }

    /// @dev 防止代币合约在转账时回调本合约、造成状态被重复修改
    modifier nonReentrant() {
        require(!locked, "TokenBannk: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // ------------------------------------------------------------------
    // 构造函数
    // ------------------------------------------------------------------

    /// @param _token 要存入的代币合约地址（部署 MyyToken 后得到）
    constructor(address _token) {
        require(_token != address(0), "TokenBannk: token is zero address");
        token = IERC20(_token);
        admin = msg.sender;
    }

    // ------------------------------------------------------------------
    // 用户：存款
    // ------------------------------------------------------------------

    /// @notice 存入 amount 个最小单位的代币
    /// @dev    调用前必须先在代币合约上执行 approve(银行地址, amount)；
    ///         本方法用 transferFrom 把代币从用户钱包转到本合约。
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "TokenBannk: amount must be > 0");

        // Checks-Effects-Interactions：先改状态记账，再转账
        deposits[msg.sender] += amount;
        totalDeposits += amount;

        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount, deposits[msg.sender]);
    }

    // ------------------------------------------------------------------
    // 管理员：取走全部代币
    // ------------------------------------------------------------------

    /// @notice 把银行里持有的全部代币转给管理员
    /// @dev    只有 admin 能调用；金额取的是「合约当前的真实代币余额」，
    ///         所以不管用户存了多少，一次调用就能全部提走。
    function withdraw() external onlyAdmin nonReentrant {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenBannk: nothing to withdraw");

        _safeTransfer(token, admin, amount);

        emit AdminWithdrawn(admin, amount);
    }

    // ------------------------------------------------------------------
    // 只读查询
    // ------------------------------------------------------------------

    /// @notice 银行当前实际持有的代币数量
    function bankBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice 查询某个用户在银行里的存款数量（等同于 deposits(user)）
    function depositOf(address user) external view returns (uint256) {
        return deposits[user];
    }

    // ------------------------------------------------------------------
    // 内部方法
    // ------------------------------------------------------------------

    /// @dev 用低级 call 并检查返回值，兼容不返回 bool 的非标准代币（例如部分旧版 USDT）
    function _safeTransfer(IERC20 _token, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "TokenBannk: transfer failed");
    }

    /// @dev 同上，检查 transferFrom 的返回值
    function _safeTransferFrom(IERC20 _token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "TokenBannk: transferFrom failed");
    }
}
