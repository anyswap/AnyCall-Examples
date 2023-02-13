// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BridgeERC20 is ERC20, AccessControl {
    uint8 _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _setRoleAdmin(ROLE_MINTER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROLE_BURNER, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    bytes32 ROLE_MINTER = keccak256("role_minter");
    bytes32 ROLE_BURNER = keccak256("role_burner");

    /// @dev only admin
    function setGateway(address _gateway) public {
        grantRole(ROLE_MINTER, _gateway);
        grantRole(ROLE_BURNER, _gateway);
    }

    /// @dev only admin
    function revokeGateway(address _gateway) public {
        revokeRole(ROLE_MINTER, _gateway);
        revokeRole(ROLE_BURNER, _gateway);
    }

    function isGateway(address account) public view returns (bool) {
        return (hasRole(ROLE_MINTER, account) && hasRole(ROLE_BURNER, account));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount)
        public
        onlyRole(ROLE_MINTER)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        public
        onlyRole(ROLE_BURNER)
    {
        _burn(account, amount);
    }
}
