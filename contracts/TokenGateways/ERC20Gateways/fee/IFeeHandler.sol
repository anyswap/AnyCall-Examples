// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFeeHandler {
    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) external view virtual returns (uint256);
}
