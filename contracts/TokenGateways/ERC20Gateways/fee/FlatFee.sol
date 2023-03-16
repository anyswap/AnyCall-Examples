// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeHandler.sol";

contract FlatFee is IFeeHandler {
    uint256 public defaultPrice;
    mapping(uint256 => bool) public isPriceSet;
    mapping(uint256 => uint256) public price;

    struct SimplePrice {
        uint256 toChainID;
        uint256 price;
    }

    constructor(uint256 _defaultPrice, SimplePrice[] memory prices) public {
        defaultPrice = _defaultPrice;
        for (uint i = 0; i < prices.length; i++) {
            isPriceSet[prices[i].toChainID] = true;
            price[prices[i].toChainID] = prices[i].price;
        }
    }

    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) public view virtual returns (uint256) {
        if (isPriceSet[toChainID]) {
            return price[toChainID];
        }
        return defaultPrice;
    }
}
