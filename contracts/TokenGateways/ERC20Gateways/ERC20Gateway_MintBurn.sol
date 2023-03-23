// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC20Gateway.sol";

interface IMintBurn {
    function balanceOf(address account) external returns (uint256);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract ERC20Gateway_MintBurn is ERC20Gateway {
    function description() external pure returns (string memory) {
        return "ERC20Gateway_MintBurn";
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal override returns (bool) {
        uint256 bal_0 = IMintBurn(token).balanceOf(sender);
        try IMintBurn(token).burn(sender, amount) {
            uint256 bal_1 = IMintBurn(token).balanceOf(sender);
            require(bal_0 - bal_1 >= amount);
            return true;
        } catch {
            return false;
        }
    }

    function _swapin(
        uint256 amount,
        address receiver
    ) internal override returns (bool) {
        try IMintBurn(token).mint(receiver, amount) {
            return true;
        } catch {
            return false;
        }
    }
}
