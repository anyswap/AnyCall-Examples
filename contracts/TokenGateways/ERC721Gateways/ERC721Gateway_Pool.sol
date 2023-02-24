// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Gateway.sol";

interface IERC721_SafeTransfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ERC721Gateway_Pool is ERC721Gateway {
    function _swapout(uint256 tokenId)
        internal
        virtual
        override
        returns (bool, bytes memory)
    {
        /// @dev Add custom logic for composing the data attached to the token ID
        bytes memory extraData = "";
        try
            IERC721_SafeTransfer(token).safeTransferFrom(msg.sender, address(this), tokenId)
        {
            return (true, extraData);
        } catch {
            return (false, "");
        }
    }

    function _swapin(
        uint256 tokenId,
        address receiver,
        bytes memory extraMsg
    ) internal override returns (bool) {
        /// @dev Add custom logic to consume the extraData
        try IERC721_SafeTransfer(token).safeTransferFrom(address(this), receiver, tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
