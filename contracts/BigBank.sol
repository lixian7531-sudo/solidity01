// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Bank
/// @notice 存款合约：记录每个地址的累计存款金额，并维护存款金额前 3 名。
///         单个 .sol 文件，可直接在 Remix 中编译部署。
contract Bank {
    // 管理员：合约部署者
    address public admin;

    // 每个地址的累计存款金额（单位：wei）
    mapping(address => uint256) public balances;

    // 存款金额前 3 名：topDepositors[i] 与 topAmounts[i] 一一对应
    address[3] public topDepositors;
    uint256[3] public topAmounts;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed admin, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice 在 Remix 中调用本函数，并在 VALUE 栏填入 ETH 即可存款；
    ///         直接用 MetaMask 向合约地址转账也会自动走 receive()，效果相同。
    /// @dev    标记为 virtual，允许 BigBank 重写以追加最低存款额限制。
    function deposit() public payable virtual {
        _deposit();
    }

    /// @notice 接收纯 ETH 转账（MetaMask 直接转给合约地址时触发）
    /// @dev    标记为 virtual，允许 BigBank 重写以追加最低存款额限制，
    ///         否则纯 ETH 转账会绕过 BigBank 的限制直接进入 _deposit()。
    receive() external payable virtual {
        _deposit();
    }

    /// @notice 拒绝其它未知调用，避免误调用造成 ETH 丢失
    fallback() external {
        revert("unsupported call");
    }

    /// @notice 只有管理员可以提取合约中的 ETH（amount 须大于 0 且不超过合约余额）
    function withdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "withdraw amount must be > 0");
        require(amount <= address(this).balance, "insufficient balance");

        (bool ok, ) = payable(admin).call{value: amount}("");
        require(ok, "withdraw failed");

        emit Withdrawn(admin, amount);
    }

    /// @notice 返回存款前 3 名的地址与金额
    function getTop3() external view returns (address[3] memory, uint256[3] memory) {
        return (topDepositors, topAmounts);
    }

    /// @notice 内部存款逻辑：更新余额并维护前 3 名排行榜
    function _deposit() internal {
        require(msg.value > 0, "deposit amount must be > 0");

        balances[msg.sender] += msg.value;
        _updateTop3(msg.sender);

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice 增量维护前 3 名。
    /// 存款只会增加余额、不会减少，因此只需把“原有前 3 名 + 本次存款人”
    /// （最多 4 个候选地址）按余额重新排序，取前 3 即可。
    function _updateTop3(address account) internal {
        address[4] memory candidates;
        uint256 count = 0;

        // 收集原有前 3 名（去重）
        for (uint256 i = 0; i < 3; i++) {
            address addr = topDepositors[i];
            if (addr == address(0)) continue;

            bool duplicate = false;
            for (uint256 j = 0; j < count; j++) {
                if (candidates[j] == addr) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) {
                candidates[count] = addr;
                count++;
            }
        }

        // 加入本次存款人（去重）
        bool exists = false;
        for (uint256 j = 0; j < count; j++) {
            if (candidates[j] == account) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            candidates[count] = account;
            count++;
        }

        // 按余额从高到低排序（最多 4 个元素，选择排序足够）
        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = i + 1; j < count; j++) {
                if (balances[candidates[j]] > balances[candidates[i]]) {
                    address tmp = candidates[i];
                    candidates[i] = candidates[j];
                    candidates[j] = tmp;
                }
            }
        }

        // 写入前 3 名；不足 3 人时剩余位置置空
        for (uint256 i = 0; i < 3; i++) {
            if (i < count) {
                topDepositors[i] = candidates[i];
                topAmounts[i] = balances[candidates[i]];
            } else {
                topDepositors[i] = address(0);
                topAmounts[i] = 0;
            }
        }
    }
}

/// @title BigBank
/// @notice 继承 Bank：仅允许单次存款金额 > 0.001 ether，
///         并支持把管理员（admin）转移给 Admin 合约。
contract BigBank is Bank {
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /// @notice 最低存款限制：本次随调用附带的 ETH 必须严格大于 0.001 ether
    modifier onlyMinDeposit() {
        require(msg.value > 0.001 ether, "deposit must be > 0.001 ether");
        _;
    }

    /// @notice 通过函数存款（VALUE 栏必须 > 0.001 ether）
    function deposit() public payable override onlyMinDeposit {
        _deposit();
    }

    /// @notice 直接向合约地址转 ETH 同样受最低存款额限制
    receive() external payable override onlyMinDeposit {
        _deposit();
    }

    /// @notice 只有当前管理员可以把 admin 转移给 Admin 合约
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "new admin cannot be zero address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

/// @title Admin
/// @notice 被指定为 BigBank 的管理员（admin）后，由 Admin 合约调用
///         BigBank.withdraw()；收到的 ETH 暂存在本合约，owner 可再转出。
contract Admin {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EthWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice 必须存在 payable receive，否则 BigBank.withdraw()
    ///         用 call{value: amount} 向 Admin 转账会失败并整体回滚
    receive() external payable {}

    /// @notice 以银行管理员身份调用 Bank/BigBank 的 withdraw()，
    ///         把 ETH 从银行取到 Admin 合约（注意：不是直接到 owner 账户）
    function withdrawFromBank(Bank bank, uint256 amount) external onlyOwner {
        bank.withdraw(amount);
    }

    /// @notice 把 Admin 合约中指定数量的 ETH 转给 owner
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount > 0, "withdraw amount must be > 0");
        require(amount <= address(this).balance, "insufficient balance");

        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "transfer failed");

        emit EthWithdrawn(owner, amount);
    }

    /// @notice 把 Admin 合约中的 ETH 全部转给 owner
    function withdrawAllETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance to withdraw");

        (bool ok, ) = payable(owner).call{value: balance}("");
        require(ok, "transfer failed");

        emit EthWithdrawn(owner, balance);
    }

    /// @notice owner 可以把 Admin 合约的控制权转给其它地址
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
