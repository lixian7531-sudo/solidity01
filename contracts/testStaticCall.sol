// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Callee {
    function getData() public pure returns (uint256) {
        return 42;
    }
}

contract Caller {
    function callGetData(address callee) public view returns (uint256 data) {
        // call by staticcall
        // abi.encodeCall 用函数指针编码：签名与参数类型由编译器检查，
        // 拼写错误会在编译期报错（abi.encodeWithSignature 只能等到运行期才发现）
        (bool success, bytes memory result) = callee.staticcall(
            abi.encodeCall(Callee.getData, ())
        );

        // 调用失败时抛出异常
        require(success, "staticcall function failed");

        // 解码返回值
        data = abi.decode(result, (uint256));

        return data;
    }
}
