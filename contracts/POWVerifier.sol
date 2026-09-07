// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title POWVerifier
/// @notice 与 Python 练习对应的 PoW 校验合约：
/// 检查 sha256("shiguang" + nonce) 的十六进制是否以 N 个 0 开头。
/// 单个 .sol 文件，可直接在 Remix 编译部署。
contract POWVerifier {
    /// 昵称前缀，和 Python 里的 PREFIX = "shiguang" 保持一致
    string public constant NICKNAME = "shiguang";

    /// 根据 nonce 拼出原始消息，例如 nonce=27119 -> "shiguang27119"
    function messageOf(uint256 nonce) public pure returns (string memory) {
        return string(abi.encodePacked(NICKNAME, uintToDecimalString(nonce)));
    }

    /// 核心校验：sha256("shiguang"+nonce) 的前 zeros 个十六进制字符是否全为 0
    function verifyPoW(uint256 nonce, uint256 zeros)
        public
        pure
        returns (bool ok, bytes32 digest)
    {
        require(zeros <= 64, "zeros must be between 0 and 64");
        digest = sha256(bytes(messageOf(nonce)));
        ok = hasLeadingZeroHex(digest, zeros);
    }

    /// 判断 bytes32 的十六进制表示是否以 zeros 个 0 开头
    /// 一个字节 = 2 个十六进制字符，所以：
    ///   zeros 为偶数时，直接检查前 zeros/2 个字节是否为 0；
    ///   zeros 为奇数时，还要检查下一个字节的“高 4 位”（即下一个十六进制字符）是否为 0。
    function hasLeadingZeroHex(bytes32 h, uint256 zeros)
        public
        pure
        returns (bool)
    {
        require(zeros <= 64, "zeros must be between 0 and 64");

        uint256 fullBytes = zeros / 2;
        for (uint256 i = 0; i < fullBytes; i++) {
            if (h[i] != 0) {
                return false;
            }
        }

        if (zeros % 2 == 1) {
            // 例如 zeros=5：前 2 个字节已检查，再检查第 3 个字节的高 4 bit
            uint8 highNibble = uint8(h[fullBytes]) >> 4;
            if (highNibble != 0) {
                return false;
            }
        }
        return true;
    }

    /// 内置 Python 练习中实际找到的两个 nonce，方便在 Remix 里一键验证
    /// 预期返回：ok4 = true（4 个 0），ok5 = true（5 个 0）
    function demo() public pure returns (bool ok4, bool ok5) {
        (ok4, ) = verifyPoW(27119, 4);
        (ok5, ) = verifyPoW(921766, 5);
    }

    /// 把 uint 转成十进制字符串，保证和 Python 的 str(nonce) 拼接方式一致
    function uintToDecimalString(uint256 value)
        public
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0";
        }

        // 先数出有多少位数字，确定字符串长度
        uint256 temp = value;
        uint256 length;
        while (temp != 0) {
            length++;
            temp /= 10;
        }

        // 从低位往高位填，最后反转就是正常的十进制数字
        bytes memory buffer = new bytes(length);
        while (value != 0) {
            length--;
            buffer[length] = bytes1(uint8(48 + (value % 10))); // 48 是字符 '0'
            value /= 10;
        }
        return string(buffer);
    }
}
