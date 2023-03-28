// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract ISwapInSafetyControl {
    address safetyAdmin;
    address gateway;

    function initSafetyControl(
        address _safetyAdmin,
        address _gateway
    ) internal {
        setSafetyAdmin(_safetyAdmin);
        gateway = _gateway;
    }

    // TODO: add param fromChainID
    function checkSwapIn(
        uint256 amount,
        address receiver
    ) public view virtual returns (bool);

    function update(uint256 amount, address receiver) public {
        require(msg.sender == gateway);
        _update(amount, receiver);
    }

    function _update(uint256 amount, address receiver) internal virtual;

    function setSafetyAdmin(address _admin) internal virtual {
        safetyAdmin = _admin;
    }

    function changeAdmin(address to) public {
        require(msg.sender == safetyAdmin);
        safetyAdmin = to;
    }
}
