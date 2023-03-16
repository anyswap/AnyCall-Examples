// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeHandler.sol";

contract DFaxFee {
    address public dfaxFeeAdmin;
    address public bridgeOwner;

    address[] public feeOwners;
    uint256[] public feeOwnerAccrued;
    uint256[] public feeOwnerWeights;

    IFeeHandler public feeHandler;

    uint256 internal dFexCharged;

    constructor() {}

    function setDFaxFeeAdmin(address _dfaxFeeAdmin) public {
        require(msg.sender == dfaxFeeAdmin);
        _setDFaxFeeAdmin(_dfaxFeeAdmin);
    }

    function _setDFaxFeeAdmin(address _dfaxFeeAdmin) internal {
        dfaxFeeAdmin = _dfaxFeeAdmin;
    }

    function setBridgeOwner(address _bridgeOwner) public {
        require(msg.sender == bridgeOwner);
        _setBridgeOwner(_bridgeOwner);
    }

    function _setBridgeOwner(address _bridgeOwner) internal {
        bridgeOwner = _bridgeOwner;
    }

    struct Permit {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function verifyPermits(bytes32 hash, Permit[] memory permits) public view {
        require(permits.length == 2, "wrong permit length");
        require(
            permits[0].deadline >= block.timestamp,
            "bridgeOwner permit expired"
        );
        require(
            permits[1].deadline >= block.timestamp,
            "dfaxFeeAdmin permit expired"
        );
        require(
            ecrecover(hash, permits[0].v, permits[0].r, permits[0].s) ==
                bridgeOwner,
            "verify bridgeOwner signature failed"
        );
        require(
            ecrecover(hash, permits[1].v, permits[1].r, permits[1].s) ==
                dfaxFeeAdmin,
            "verify dfaxFeeAdmin signature failed"
        );
    }

    bytes4 public constant SELECTOR_ADDFEEOWNER =
        bytes4(keccak256("addFeeOwner(address,uint256)"));
    bytes4 public constant SELECTOR_UPDATEFEEOWNER =
        bytes4(keccak256("updateFeeOwnerF(address,uint256)"));
    bytes4 public constant SELECTOR_REMOVEFEEOWNER =
        bytes4(keccak256("removeFeeOwner(address)"));
    bytes4 public constant SELECTOR_SETFEEHANDLER =
        bytes4(keccak256("someFunc(address,uint256)"));

    function addFeeOwnerWithPermit(
        address feeOwner,
        uint256 weight,
        Permit[] memory permits
    ) public {
        bytes32 hash = keccak256(
            abi.encodeWithSelector(SELECTOR_ADDFEEOWNER, feeOwner, weight)
        );
        verifyPermits(hash, permits);
        _addFeeOwner(feeOwner, weight);
    }

    function _addFeeOwner(address feeOwner, uint256 weight) internal {
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

    function updateFeeOwnerWithPermit(
        address feeOwner,
        uint256 weight,
        Permit[] memory permits
    ) public {
        bytes32 hash = keccak256(
            abi.encodeWithSelector(SELECTOR_UPDATEFEEOWNER, feeOwner, weight)
        );
        verifyPermits(hash, permits);
        _updateFeeOwner(feeOwner, weight);
    }

    function _updateFeeOwner(address feeOwner, uint256 weight) internal {
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == feeOwner) {
                feeOwnerWeights[i] = weight;
            }
        }
    }

    function removeFeeOwnerWithPermit(
        address feeOwner,
        Permit[] memory permits
    ) public {
        bytes32 hash = keccak256(
            abi.encodeWithSelector(SELECTOR_REMOVEFEEOWNER, feeOwner)
        );
        verifyPermits(hash, permits);
        _removeFeeOwner(feeOwner);
    }

    function _removeFeeOwner(address feeOwner) internal {
        _updateFeeOwner(feeOwner, 0);
    }

    function setFeeHandlerWithPermit(
        address feeHandler,
        Permit[] memory permits
    ) public {
        bytes32 hash = keccak256(
            abi.encodeWithSelector(SELECTOR_SETFEEHANDLER, feeHandler)
        );
        verifyPermits(hash, permits);
        _setFeeHandler(feeHandler);
    }

    function _setFeeHandler(address _feeHandler) internal {
        feeHandler = IFeeHandler(_feeHandler);
    }

    modifier chargeFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) {
        uint256 fee = calcFee(sender, toChainID, amount);
        (bool succ, ) = address(this).call{value: fee}("");
        require(succ, "charge fee failed");

        uint256 totalWeight;
        for (uint i = 0; i < feeOwners.length; i++) {
            totalWeight += feeOwnerWeights[i];
        }
        for (uint i = 0; i < feeOwners.length; i++) {
            feeOwnerAccrued[i] +=
                (msg.value * feeOwnerWeights[i]) /
                totalWeight;
        }

        dFexCharged = fee;
        _;
        dFexCharged = 0;
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
        return feeHandler.calcFee(sender, toChainID, amount);
    }
}
