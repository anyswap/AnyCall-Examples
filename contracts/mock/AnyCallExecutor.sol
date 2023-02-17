pragma solidity ^0.8.10;

import "../interfaces/IAnycallExecutor.sol";

interface IApp {
    function anyExecute(bytes calldata _data)
        external
        returns (bool success, bytes memory result);

    function anyFallback(bytes calldata _data)
        external
        returns (bool success, bytes memory result);
}

contract AnycallExecutorMock is IAnycallExecutor {
    struct Context {
        address from;
        uint256 fromChainID;
        uint256 nonce;
    }

    Context public context;

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce,
        uint256 _flags,
        bytes calldata _extdata
    ) external returns (bool success, bytes memory result) {
        return (false, "");
    }

    function executeMock(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce
    ) external returns (bool success, bytes memory result) {
        context = Context({
            from: _from,
            fromChainID: _fromChainID,
            nonce: _nonce
        });
        (success, result) = IApp(_to).anyExecute(_data);
        context = Context({from: address(0), fromChainID: 0, nonce: 0});
    }

    function executeFallbackMock(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce
    ) external returns (bool success, bytes memory result) {
        context = Context({
            from: _from,
            fromChainID: _fromChainID,
            nonce: _nonce
        });
        (success, result) = IApp(_to).anyExecute(_data);
        context = Context({from: address(0), fromChainID: 0, nonce: 0});
    }
}
