// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../AnyCallAppBase/AnyCallApp.sol";
import "./ISwapInSafetyControl.sol";
import "./fee/DFaxFee.sol";

interface IDecimal {
    function decimals() external view returns (uint8);
}

interface IERC20Gateway {
    function token() external view returns (address);

    function Swapout(
        uint256 amount,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC20Gateway is IERC20Gateway, AnyCallApp, DFaxFee {
    address public token;
    mapping(uint256 => uint8) public decimals;
    uint256 public swapoutSeq;

    address private _initiator;
    bool public initialized = false;

    ISwapInSafetyControl public safetyControl;

    constructor() DFaxFee() {
        _initiator = msg.sender;
    }

    function initERC20Gateway(
        address anyCallProxy,
        address token_,
        address admin,
        address _safetyControl,
        address dFaxFeeAdmin,
        address defaultFeeScheme
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        token = token_;
        initAnyCallApp(anyCallProxy, admin);
        safetyControl = ISwapInSafetyControl(_safetyControl);
        initDFaxFee(dFaxFeeAdmin, defaultFeeScheme);
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal virtual returns (bool);

    function _swapin(
        uint256 amount,
        address receiver
    ) internal virtual returns (bool);

    event LogAnySwapOut(
        uint256 amount,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapoutSeq
    );

    function setDecimals(
        uint256[] memory chainIDs,
        uint8[] memory decimals_
    ) external onlyAdmin {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            decimals[chainIDs[i]] = decimals_[i];
        }
    }

    function decimal(uint256 chainID) external view returns (uint8) {
        return (
            decimals[chainID] > 0
                ? decimals[chainID]
                : IDecimal(token).decimals()
        );
    }

    function convertDecimal(
        uint256 amount,
        uint8 d_0
    ) public view returns (uint256) {
        uint8 d_1 = IDecimal(token).decimals();
        if (d_0 > d_1) {
            for (uint8 i = 0; i < (d_0 - d_1); i++) {
                amount = amount / 10;
            }
        } else {
            for (uint8 i = 0; i < (d_1 - d_0); i++) {
                amount = amount * 10;
            }
        }
        return amount;
    }

    function Swapout(
        uint256 amount,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        require(_swapout(amount, msg.sender));
        swapoutSeq++;
        bytes memory data = abi.encode(
            amount,
            IDecimal(token).decimals(),
            receiver,
            swapoutSeq
        );
        uint256 dFeeCharged = chargeFee(msg.sender, destChainID, amount);
        uint256 anyCallFee = msg.value - dFeeCharged;
        _anyCall(clientPeers[destChainID], data, destChainID, anyCallFee);
        emit LogAnySwapOut(
            amount,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 amount, uint8 _decimals, address receiver, ) = abi.decode(
            data,
            (uint256, uint8, address, uint256)
        );
        amount = convertDecimal(amount, _decimals);
        if (address(safetyControl) != address(0)) {
            require(
                // TODO: pass fromChainID to checkSwapIn
                safetyControl.checkSwapIn(amount, receiver),
                "swapin restricted"
            );
        }
        success = _swapin(amount, receiver);
        safetyControl.update(amount, receiver);
    }

    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 amount, , address originSender, , ) = abi.decode(
            data,
            (uint256, uint8, address, address, uint256)
        );
        success = (_swapin(amount, originSender));
    }
}
