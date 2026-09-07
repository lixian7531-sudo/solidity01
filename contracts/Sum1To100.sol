// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Sum1To100
/// @notice 计算 1 ~ 100 所有整数之和的练习合约。
/// 单个 .sol 文件，可直接在 Remix 编译部署。
contract Sum1To100 {
    /// 等差数列求和公式: n * (首项 + 末项) / 2
    /// 1 + 2 + ... + 100 = 100 * (1 + 100) / 2 = 5050
    function sumByFormula() public pure returns (uint256) {
        return 100 * (1 + 100) / 2;
    }

    /// 用 for 循环逐项累加，结果应与公式版相同（5050）
    function sumByLoop() public pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= 100; i++) {
            total += i;
        }
        return total;
    }

    /// 一键验证两个实现结果一致
    function demo() public pure returns (uint256 result, bool consistent) {
        result = sumByFormula();
        consistent = (sumByLoop() == result);
    }
}
