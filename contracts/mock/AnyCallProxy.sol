pragma solidity ^0.8.10;

import "../interfaces/IAnycallProxy.sol";
import "../interfaces/IFeePool.sol";

/// @dev mock contract of AnyCallProxy and AnyCallConfig
contract AnyCallProxyMock is IAnycallProxy, IFeePool {
    address _executor;

    constructor(address executor_) {
        _executor = executor_;
    }

    function executor() external view returns (address) {
        return _executor;
    }

    function config() external view returns (address) {
        return address(this);
    }

    event LogAnyCall(
        address to,
        bytes data,
        uint256 toChainID,
        uint256 flags,
        bytes extdata
    );

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable {
        emit LogAnyCall(_to, _data, _toChainID, _flags, _extdata);
        return;
    }

    function deposit(address _account) external payable {
        return;
    }

    function withdraw(uint256 _amount) external {
        return;
    }

    function executionBudget(address _account) external view returns (uint256) {
        return 100 ether;
    }
}
