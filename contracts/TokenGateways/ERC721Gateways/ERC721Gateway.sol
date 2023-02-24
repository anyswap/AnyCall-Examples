// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../AnyCallAppBase/AnyCallApp.sol";

interface IERC721Gateway {
    function token() external view returns (address);

    function Swapout(
        uint256 tokenId,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC721Gateway is IERC721Gateway, AnyCallApp {
    address private _initiator;
    bool public initialized = false;

    constructor() {
        _initiator = msg.sender;
    }

    address public token;
    uint256 public swapoutSeq;

    function initERC20Gateway(
        address anyCallProxy,
        address token_,
        address admin
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        token = token_;
        initAnyCallApp(anyCallProxy, admin);
    }

    function _swapout(uint256 tokenId)
        internal
        virtual
        returns (bool, bytes memory);

    function _swapin(
        uint256 tokenId,
        address receiver,
        bytes memory extraMsg
    ) internal virtual returns (bool);

    event LogAnySwapOut(
        uint256 tokenId,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapoutSeq
    );

    function Swapout(
        uint256 tokenId,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(tokenId);
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(
            tokenId,
            msg.sender,
            receiver,
            swapoutSeq,
            extraMsg
        );
        _anyCall(clientPeers[destChainID], data, destChainID);
        emit LogAnySwapOut(
            tokenId,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    /// @dev the name makes no sence, just to be compatible with nft gateway v6
    function Swapout_no_fallback(
        uint256 tokenId,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256) {
        return this.Swapout(tokenId, receiver, toChainID);
    }

    function _anyExecute(uint256 fromChainID, bytes memory data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (uint256 tokenId, , address receiver, , bytes memory extraMsg) = abi
            .decode(data, (uint256, address, address, uint256, bytes));
        success = _swapin(tokenId, receiver, extraMsg);
    }

    function _anyFallback(uint256 fromChainID, bytes memory data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (uint256 tokenId, address originSender, , , bytes memory extraMsg) = abi
            .decode(data, (uint256, address, address, uint256, bytes));
        success = _swapin(tokenId, originSender, extraMsg);
    }
}
