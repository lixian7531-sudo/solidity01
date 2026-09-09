// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IBank
/// @notice Bank / BigBank 对外暴露的统一接口（Bank 必须实现这些函数）
interface IBank {
    /// @notice 存款：调用时需附带 ETH
    function deposit() external payable;

    /// @notice 管理员取款
    function withdraw(uint256 amount) external;

    /// @notice 查询当前管理员
    function admin() external view returns (address);

    /// @notice 查询某个地址的累计存款
    function balances(address account) external view returns (uint256);

    /// @notice 查询存款前 3 名
    function getTop3() external view returns (address[3] memory, uint256[3] memory);
}

/// @title Bank
/// @notice 存款合约：记录每个地址的累计存款金额，并维护存款金额前 3 名。
contract Bank is IBank {
    // 管理员：合约部署者
    address public override admin;

    // 每个地址的累计存款金额（单位：wei）
    mapping(address => uint256) public override balances;

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

    /// @notice 存款入口：VALUE 栏填 ETH 后调用即可。
    /// @dev    实现 IBank.deposit，并标记 virtual 供 BigBank 重写。
    function deposit() public payable virtual override {
        _deposit();
    }

    /// @notice 接收纯 ETH 转账（MetaMask 直转时触发），同样记账。
    /// @dev    标记 virtual 供 BigBank 重写，避免直转绕过最低存款限制。
    receive() external payable virtual {
        _deposit();
    }

    /// @notice 拒绝其它未知调用
    fallback() external {
        revert("unsupported call");
    }

    /// @notice 只有管理员可以提取合约中的 ETH（实现 IBank.withdraw）
    function withdraw(uint256 amount) external override onlyAdmin {
        require(amount > 0, "withdraw amount must be > 0");
        require(amount <= address(this).balance, "insufficient balance");

        (bool ok, ) = payable(admin).call{value: amount}("");
        require(ok, "withdraw failed");

        emit Withdrawn(admin, amount);
    }

    /// @notice 返回存款前 3 名的地址与金额
    function getTop3()
        external
        view
        override
        returns (address[3] memory, uint256[3] memory)
    {
        return (topDepositors, topAmounts);
    }

    /// @notice 内部存款逻辑：更新余额并维护前 3 名排行榜
    function _deposit() internal {
        require(msg.value > 0, "deposit amount must be > 0");

        balances[msg.sender] += msg.value;
        _updateTop3(msg.sender);

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice 增量维护前 3 名：把"原前 3 名 + 本次存款人"（最多 4 个）重新排序
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
/// @notice 继承 Bank，附加要求：
///         1) 单次存款金额必须 > 0.001 ether（modifier 控制）；
///         2) 支持转移管理员。
contract BigBank is Bank {
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /// @notice 最低存款限制：本次调用附带的 ETH 必须严格大于 0.001 ether
    modifier onlyMinDeposit() {
        require(msg.value > 0.001 ether, "deposit must be > 0.001 ether");
        _;
    }

    /// @notice 重写存款入口，加上最低存款检查
    function deposit() public payable override onlyMinDeposit {
        _deposit();
    }

    /// @notice 重写 receive，MetaMask 直转同样受最低存款限制
    receive() external payable override onlyMinDeposit {
        _deposit();
    }

    /// @notice 只有当前管理员可以把 admin 转移给其它合约/地址
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "new admin cannot be zero address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

/// @title Admin
/// @notice 有自己的 owner；owner 通过 adminWithdraw(IBank bank) 以
///         "银行管理员"身份调用 IBank.withdraw，把银行资金转到 Admin 合约。
contract Admin {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminWithdrawn(address indexed bank, uint256 amount);
    event EthWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice 必须可接收 ETH：Bank.withdraw 会 call{value:...} 转给 admin（即本合约）
    receive() external payable {}

    /// @notice 只有 owner 可调用；以本合约身份调用 IBank.withdraw，
    ///         把 bank 合约里的全部 ETH 转移到 Admin 合约地址
    function adminWithdraw(IBank bank) external onlyOwner {
        uint256 amount = address(bank).balance;
        require(amount > 0, "bank balance is 0");

        bank.withdraw(amount);

        emit AdminWithdrawn(address(bank), amount);
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
