// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC20Gateway.sol";

interface ITransfer {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract ERC20Gateway_Pool is ERC20Gateway {
    function description() external pure returns (string memory) {
        return "ERC20Gateway_Pool";
    }

    function _swapout(uint256 amount, address sender)
        internal
        override
        returns (bool)
    {
        return ITransfer(token).transferFrom(sender, address(this), amount);
    }

    function _swapin(uint256 amount, address receiver)
        internal
        override
        returns (bool)
    {
        ITransfer(token).approve(address(this), amount);
        return ITransfer(token).transferFrom(address(this), receiver, amount);
    }
}
