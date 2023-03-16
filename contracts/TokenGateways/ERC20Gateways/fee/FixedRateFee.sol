// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeHandler.sol";

contract FixedRateFee is IFeeHandler {
    uint256 public defaultRate;
    uint256 public constant denominator = 1e18;
    mapping(uint256 => bool) public isRateSet;
    mapping(uint256 => uint256) public rate;

    struct SimpleRate {
        uint256 toChainID;
        uint256 rate;
    }

    constructor(uint256 _defaultRate, SimpleRate[] memory rates) public {
        defaultRate = _defaultRate;
        for (uint i = 0; i < rates.length; i++) {
            isRateSet[rates[i].toChainID] = true;
            rate[rates[i].toChainID] = rates[i].rate;
        }
    }

    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) public view virtual returns (uint256) {
        if (isRateSet[toChainID]) {
            return (amount * rate[toChainID]) / denominator;
        }
        return (amount * defaultRate) / denominator;
    }
}
