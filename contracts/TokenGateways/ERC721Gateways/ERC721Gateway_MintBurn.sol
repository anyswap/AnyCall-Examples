// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Gateway.sol";

interface IERC721_MintBurn {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address account, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract ERC721Gateway_MintBurn is ERC721Gateway {
    function _swapout(uint256 tokenId)
        internal
        virtual
        override
        returns (bool, bytes memory)
    {
        /// @dev Add custom logic for composing the data attached to the token ID
        bytes memory extraData = "";
        require(
            IERC721_MintBurn(token).ownerOf(tokenId) == msg.sender,
            "not allowed"
        );
        try IERC721_MintBurn(token).burn(tokenId) {
            return (true, extraData);
        } catch {
            return (false, "");
        }
    }

    function _swapin(
        uint256 tokenId,
        address receiver,
        bytes memory extraData
    ) internal override returns (bool) {
        /// @dev Add custom logic to consume the extraData
        try IERC721_MintBurn(token).mint(receiver, tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}
