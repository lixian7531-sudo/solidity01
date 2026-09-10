// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ABIEncoder {
    // 编码单个 uint256
    function encodeUint(uint256 _num) public pure returns (bytes memory) {
        return abi.encode(_num);
    }

    // 编码多个不同类型的参数
    function encodeMultiple(uint256 _num, string memory _str)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_num, _str);
    }
}

contract ABIDecoder {
    // 把 bytes 解码成一个 uint256
    function decodeUint(bytes memory _data) public pure returns (uint256) {
        return abi.decode(_data, (uint256));
    }

    // 把 bytes 解码成 (uint256, string)，类型顺序必须和编码时一致
    function decodeMultiple(bytes memory _data)
        public
        pure
        returns (uint256, string memory)
    {
        return abi.decode(_data, (uint256, string));
    }
}
