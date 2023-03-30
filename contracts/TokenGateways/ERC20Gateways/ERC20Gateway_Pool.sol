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

interface IWNative {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

contract ERC20Gateway_Pool is ERC20Gateway {
    bool public isWNative;

    function description() external pure returns (string memory) {
        return "ERC20Gateway_Pool";
    }

    function initIsWNative(bool _isWNative) public {
        require(!initialized);
        isWNative = _isWNative;
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal override returns (bool) {
        if (isWNative && msg.value > 0) {
            if (msg.value < amount) {
                return false;
            }
            IWNative(token).deposit{value: msg.value}();
            return true;
        } else {
            return ITransfer(token).transferFrom(sender, address(this), amount);
        }
    }

    function _swapin(
        uint256 amount,
        address receiver
    ) internal override returns (bool) {
        ITransfer(token).approve(address(this), amount);
        if (isWNative) {
            try IWNative(token).withdraw(amount) {} catch {
                return false;
            }
            (bool succ, ) = receiver.call{value: amount}("");
            return succ;
        } else {
            return
                ITransfer(token).transferFrom(address(this), receiver, amount);
        }
    }

    mapping(address => uint256) public balanceOf;

    event Deposit(address, uint256);
    event Withdraw(address, uint256);

    function deposit(uint256 amount) external {
        bool succ = ITransfer(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(succ);
        balanceOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        bool succ = ITransfer(token).transferFrom(
            address(this),
            msg.sender,
            amount
        );
        require(succ);
        emit Withdraw(msg.sender, amount);
    }
}
