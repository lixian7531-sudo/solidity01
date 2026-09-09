// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BigBank.sol";

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
