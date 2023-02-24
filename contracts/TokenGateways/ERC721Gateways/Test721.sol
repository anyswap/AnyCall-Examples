pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC721_MintBurn {
    function mint(address account, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract Test721_NFT is ERC721, IERC721_MintBurn, AccessControl {
    string private _name;
    string private _symbol;

    address private _initiator;
    bool public initialized = false;

    constructor() ERC721("", "") {
        _initiator = msg.sender;
    }

    function initERC721(
        string memory name_,
        string memory symbol_,
        address admin
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        _name = name_;
        _symbol = symbol_;
        _setRoleAdmin(ROLE_MINTER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROLE_BURNER, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

    function mint(address account, uint256 tokenId)
        public
        onlyRole(ROLE_MINTER)
    {
        _mint(account, tokenId);
    }

    function burn(uint256 tokenId) public onlyRole(ROLE_BURNER) {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721_MintBurn).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
