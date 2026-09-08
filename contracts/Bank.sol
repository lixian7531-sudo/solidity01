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
    function deposit() public payable {
        _deposit();
    }

    /// @notice 接收纯 ETH 转账（MetaMask 直接转给合约地址时触发）
    receive() external payable {
        _deposit();
    }

    /// @notice 拒绝其它未知调用，避免误调用造成 ETH 丢失
    fallback() external {
        revert("unsupported call");
    }

    /// @notice 只有管理员可以提取合约中的全部 ETH
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "no ETH to withdraw");

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
