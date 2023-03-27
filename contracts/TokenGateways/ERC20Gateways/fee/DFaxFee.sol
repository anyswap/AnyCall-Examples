// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeScheme.sol";

contract DFaxFee {
    address public dfaxFeeAdmin;

    address[] public feeOwners;
    uint256[] public feeOwnerAccrued;
    uint256[] public feeOwnerWeights;

    IFeeScheme public feeScheme;

    uint256 internal dFeeCharged;

    modifier onlyDFaxFeeAdmin() {
        require(msg.sender == dfaxFeeAdmin);
        _;
    }

    constructor() {}

    function initDFaxFee(
        address _dFaxFeeAdmin,
        address defaultFeeScheme
    ) internal {
        _setDFaxFeeAdmin(_dFaxFeeAdmin);
        _setFeeScheme(defaultFeeScheme);
    }

    function setDFaxFeeAdmin(address dfaxFeeAdmin) public onlyDFaxFeeAdmin {
        _setDFaxFeeAdmin(dfaxFeeAdmin);
    }

    function _setDFaxFeeAdmin(address _dfaxFeeAdmin) internal {
        dfaxFeeAdmin = _dfaxFeeAdmin;
    }

    function addFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        for (uint i = 0; i < feeOwners.length; i++) {
            require(feeOwners[i] != feeOwner, "duplicated fee owner address");
        }
        feeOwners.push(feeOwner);
        feeOwnerWeights.push(weight);
    }

    function getFeeOwnerWeight(address feeOwner) public view returns (uint256) {
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == feeOwner) {
                return feeOwnerWeights[i];
            }
        }
        return 0;
    }

    function getTotalWeight() public view returns (uint256) {
        uint256 totalWeight;
        for (uint i = 0; i < feeOwners.length; i++) {
            totalWeight += feeOwnerWeights[i];
        }
        return totalWeight;
    }

    function updateFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        _updateFeeOwner(feeOwner, weight);
    }

    function _updateFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == feeOwner) {
                feeOwnerWeights[i] = weight;
            }
        }
    }

    function removeFeeOwner(address feeOwner) public onlyDFaxFeeAdmin {
        _updateFeeOwner(feeOwner, 0);
    }

    function setFeeScheme(address feeScheme) public onlyDFaxFeeAdmin {
        _setFeeScheme(feeScheme);
    }

    function _setFeeScheme(address _feeScheme) internal {
        feeScheme = IFeeScheme(_feeScheme);
    }

    function chargeFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fee = calcFee(sender, toChainID, amount);
        (bool succ, ) = address(this).call{value: fee}("");
        require(succ, "charge fee failed");

        uint256 totalWeight;
        for (uint i = 0; i < feeOwners.length; i++) {
            totalWeight += feeOwnerWeights[i];
        }
        for (uint i = 0; i < feeOwners.length; i++) {
            feeOwnerAccrued[i] += (fee * feeOwnerWeights[i]) / totalWeight;
        }

        return fee;
    }

    function withdrawDFaxFee(address to, uint256 amount) public {
        uint index = 0;
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == msg.sender) {
                index = i;
            }
        }
        require(feeOwnerAccrued[index] >= amount, "amount exceeds fee accrued");
        (bool succ, ) = to.call{value: amount}("");
        require(succ);
        feeOwnerAccrued[index] -= amount;
    }

    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) public view returns (uint256) {
        if (address(feeScheme) == address(0)) {
            return 0;
        }
        return feeScheme.calcFee(sender, toChainID, amount);
    }
}
