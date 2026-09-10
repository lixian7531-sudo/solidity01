// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IERC20
/// @notice ERC20 标准接口（只保留本项目用到的部分）
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title BaseERC20
/// @notice 一个最简 ERC20 实现，仅用于在 Remix 里测试 TokenBank。
///         部署时会把全部 100000000 枚代币发给部署者。
contract BaseERC20 is IERC20 {
    string public name = "BaseERC20";
    string public symbol = "BERC20";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 100_000_000 * (10 ** uint256(decimals));
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "ERC20: insufficient allowance");
        if (allowed != type(uint256).max) {
            _allowances[from][msg.sender] = allowed - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}

/// @title TokenBank
/// @notice 代币银行：用户可以把自己的 ERC20 代币存进来，也可以随时取回。
/// @dev    每个用户的存款数量记录在 balances 里；合约只允许用户提取「自己存的那部分」，
///         不会碰别人的份额。整个逻辑放在一个 .sol 文件里，可直接在 Remix 编译部署。
contract TokenBank {
    /// @notice 本银行支持的代币（部署时指定，之后不可更改）
    IERC20 public immutable token;

    /// @notice 每个地址在银行里的存款数量
    mapping(address => uint256) public balances;

    /// @notice 存款锁：防止代币合约在转账时回调重入（重入攻击）
    bool private locked;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    modifier nonReentrant() {
        require(!locked, "TokenBank: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    /// @param _token 要存入的代币合约地址（先部署 BaseERC20，再把它的地址填进来）
    constructor(address _token) {
        require(_token != address(0), "TokenBank: token is zero address");
        token = IERC20(_token);
    }

    /// @notice 存入 amount 数量的代币
    /// @dev    使用前必须先在本银行地址上调用代币的 approve(amount)；
    ///         这里用 transferFrom 把代币从用户钱包转到银行合约。
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "TokenBank: deposit amount must be > 0");

        // 先记账再转账（Checks-Effects-Interactions），避免重入时状态不一致
        balances[msg.sender] += amount;

        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    /// @notice 取出自己之前存入的 amount 数量的代币
    /// @dev    只能提取 balances[msg.sender] 里的数量，所以任何人都不可能取走别人的存款。
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "TokenBank: withdraw amount must be > 0");
        require(balances[msg.sender] >= amount, "TokenBank: insufficient balance");

        // 同样遵循 Checks-Effects-Interactions：先扣账，再转账
        balances[msg.sender] -= amount;

        _safeTransfer(token, msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice 银行当前持有的代币数量
    function totalTokenInBank() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice 兼容不返回 bool 的非标准代币（如部分老版本 USDT）
    function _safeTransfer(IERC20 _token, address to, uint256 amount) internal {
        (bool ok, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "TokenBank: transfer failed");
    }

    /// @notice 兼容不返回 bool 的非标准代币（如部分老版本 USDT）
    function _safeTransferFrom(IERC20 _token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "TokenBank: transferFrom failed");
    }
}
