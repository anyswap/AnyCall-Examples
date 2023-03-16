// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./AdminControl.sol";
import "../interfaces/IAnycallProxy.sol";
import "../interfaces/IAnycallExecutor.sol";
import "../interfaces/IFeePool.sol";

abstract contract AnyCallApp is AdminControl {
    address public callProxy;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(
            msg.sender == IAnycallProxy(callProxy).executor(),
            "AppBase: onlyExecutor"
        );
        _;
    }

    function initAnyCallApp(address _callProxy, address _admin) public {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        initAdminControl(_admin);
    }

    receive() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdraw(address _to, uint256 _amount) external onlyAdmin {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function depositFee() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdrawFee(address _to, uint256 _amount) external onlyAdmin {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function withdrawAllFee(address _pool, address _to) external onlyAdmin {
        uint256 _amount = IFeePool(_pool).executionBudget(address(this));
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function executionBudget() external view returns (uint256) {
        address _pool = IAnycallProxy(callProxy).config();
        return IFeePool(_pool).executionBudget(address(this));
    }

    /// @dev Customized logic for processing incoming messages
    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Customized logic for processing fallback messages
    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Send anyCall
    function _anyCall(
        address _to,
        bytes memory _data,
        uint256 _toChainID,
        uint256 fee
    ) internal {
        // reserve 10 percent for fallback
        uint256 fee1 = fee / 10;
        uint256 fee2 = fee - fee1;
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: fee1}(address(this));
        IAnycallProxy(callProxy).anyCall{value: fee2}(
            _to,
            _data,
            _toChainID,
            4,
            ""
        );
    }

    function anyExecute(
        bytes memory data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyExecute(fromChainID, data);
    }

    function anyFallback(
        bytes calldata data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyFallback(fromChainID, data);
    }
}
