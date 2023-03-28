// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ISwapInSafetyControl.sol";

interface IToken {
    function totalSupply() external view virtual returns (uint256);
}

interface IGateway {
    function token() external view virtual returns (address);
}

contract DefaultSwapInSafetyControl is ISwapInSafetyControl {
    mapping(address => bool) public blacklist;
    uint256 public maxSupply;
    uint256 public maxAmountPerTx;
    uint256 public maxAmountPerDay;
    uint256 public lastSwapInDay;
    uint256 public accumulatedAmount;
    bool public initialized;

    constructor() {}

    function initDefaultSafetyControls(
        address safetyAdmin,
        address gateway,
        uint _maxSupply,
        uint _maxAmountPerTx,
        uint _maxAmountPerDay
    ) public {
        require(!initialized);
        initSafetyControl(safetyAdmin, gateway);
        maxSupply = _maxSupply;
        maxAmountPerTx = _maxAmountPerTx;
        maxAmountPerDay = _maxAmountPerDay;
        lastSwapInDay = block.timestamp / 1 days;
        initialized = true;
    }

    function checkSwapIn(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) public view virtual override returns (bool) {
        if (blacklist[receiver]) {
            return false;
        }
        if (
            IToken(IGateway(gateway).token()).totalSupply() + amount >=
            maxSupply
        ) {
            return false;
        }
        if (amount > maxAmountPerTx) {
            return false;
        }
        if (
            block.timestamp / 1 days == lastSwapInDay &&
            accumulatedAmount + amount > maxAmountPerDay
        ) {
            return false;
        }
        return true;
    }

    function _update(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) internal virtual override {
        if (block.timestamp / 1 days > lastSwapInDay) {
            accumulatedAmount = amount;
        } else {
            accumulatedAmount += amount;
        }
        lastSwapInDay = block.timestamp / 1 days;
    }

    function setBlacklist(address account, bool isBlack) public {
        require(msg.sender == safetyAdmin);
        blacklist[account] = isBlack;
    }

    function setMaxSupply(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxSupply = amount;
    }

    function setMaxAmountPerTx(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxAmountPerTx = amount;
    }

    function setMaxAmountPerDay(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxAmountPerDay = amount;
    }
}
