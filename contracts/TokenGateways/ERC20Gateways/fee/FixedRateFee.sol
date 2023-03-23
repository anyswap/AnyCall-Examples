// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeScheme.sol";

contract FixedRateFee is IFeeScheme {
    uint256 public defaultRate;
    uint256 public constant denominator = 1e18;
    mapping(uint256 => bool) public isRateSet;
    mapping(uint256 => uint256) public rate;
    mapping(uint256 => bool) public isMaxSet;
    mapping(uint256 => uint256) public max;
    mapping(uint256 => bool) public isMinSet;
    mapping(uint256 => uint256) public min;

    struct SimpleRate {
        uint256 toChainID;
        uint256 rate;
        uint256 max;
        uint256 min;
    }

    constructor(uint256 _defaultRate, SimpleRate[] memory rates) public {
        defaultRate = _defaultRate;
        for (uint i = 0; i < rates.length; i++) {
            isRateSet[rates[i].toChainID] = true;
            rate[rates[i].toChainID] = rates[i].rate;
            isMaxSet[rates[i].toChainID] = true;
            max[rates[i].toChainID] = rates[i].max;
            isMinSet[rates[i].toChainID] = true;
            min[rates[i].toChainID] = rates[i].min;
        }
    }

    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) public view virtual returns (uint256) {
        if (isRateSet[toChainID]) {
            uint256 fee = (amount * rate[toChainID]) / denominator;
            if (isMaxSet[toChainID] && fee > max[toChainID]) {
                return max[toChainID];
            }
            if (isMinSet[toChainID] && fee < min[toChainID]) {
                return min[toChainID];
            }
            return fee;
        }
        return (amount * defaultRate) / denominator;
    }
}
