// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./BridgeERC20.sol";
import "./ERC20Gateway_MintBurn.sol";
import "./ERC20Gateway_Pool.sol";
import "./DefaultSwapInSafetyControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ICodeShop {
    function getCode() external view virtual returns (bytes memory);
}

contract CodeShop_BridgeToken is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(BridgeERC20).creationCode;
    }
}

contract CodeShop_MintBurnGateway is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(ERC20Gateway_MintBurn).creationCode;
    }
}

contract CodeShop_PoolGateway is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(ERC20Gateway_Pool).creationCode;
    }
}

contract CodeShop_DefaultSafetyControl is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(DefaultSwapInSafetyControl).creationCode;
    }
}

contract BridgeFactory is AccessControl {
    address anyCallProxy;
    ICodeShop[4] codeShops;
    address public dfaxFeeAdmin;

    /// @param _codeShops is sort list of CodeShop addresses : `[CS_BridgeToken, CS_MintBurnGateway, CS_PoolGateway, CodeShop_DefaultSafetyControl]`
    constructor(
        address _anyCallProxy,
        address[] memory _codeShops,
        address _dfaxFeeAdmin
    ) {
        require(_codeShops.length == 4);
        anyCallProxy = _anyCallProxy;
        for (uint256 i = 0; i < _codeShops.length; i++) {
            codeShops[i] = ICodeShop(_codeShops[i]);
        }
        dfaxFeeAdmin = _dfaxFeeAdmin;
    }

    event Create(string contractType, address contractAddress);

    function getBridgeTokenAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[0].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getPoolGatewayAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getMintBurnGatewayAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[1].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function createBridgeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) public returns (address) {
        return
            _createBridgeToken(name_, symbol_, decimals_, owner, salt, owner);
    }

    function _createBridgeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt,
        address admin
    ) internal returns (address) {
        address payable addr;
        bytes memory bytecode = codeShops[0].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 bridge token", addr);
        BridgeERC20(addr).initERC20(name_, symbol_, decimals_, admin);
        return addr;
    }

    function createPoolGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address payable gatewayAddr;
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            gatewayAddr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(gatewayAddr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 pool gateway", gatewayAddr);
        address payable safetyControlAddr;
        bytes memory safetyControlBytecode = codeShops[3].getCode();
        salt = uint256(keccak256(abi.encodePacked(gatewayAddr, owner, salt)));
        assembly {
            safetyControlAddr := create2(
                0,
                add(safetyControlBytecode, 0x20),
                mload(safetyControlBytecode),
                salt
            )

            if iszero(extcodesize(safetyControlAddr)) {
                revert(0, 0)
            }
        }
        emit Create("Default safety control", safetyControlAddr);
        ERC20Gateway(gatewayAddr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            safetyControlAddr,
            dfaxFeeAdmin,
            address(0)
        );
        DefaultSwapInSafetyControl(safetyControlAddr).initDefaultSafetyControls(
            owner,
            gatewayAddr,
            (1 << 256) - 1,
            (1 << 256) - 1,
            (1 << 256) - 1
        );
        return (gatewayAddr, safetyControlAddr);
    }

    function createMintBurnGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address payable gatewayAddr;
        bytes memory bytecode = codeShops[1].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            gatewayAddr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(gatewayAddr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 mint-burn gateway", gatewayAddr);
        address payable safetyControlAddr;
        bytes memory safetyControlBytecode = codeShops[3].getCode();
        salt = uint256(keccak256(abi.encodePacked(gatewayAddr, owner, salt)));
        assembly {
            safetyControlAddr := create2(
                0,
                add(safetyControlBytecode, 0x20),
                mload(safetyControlBytecode),
                salt
            )

            if iszero(extcodesize(safetyControlAddr)) {
                revert(0, 0)
            }
        }
        emit Create("Default safety control", safetyControlAddr);
        ERC20Gateway(gatewayAddr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            safetyControlAddr,
            dfaxFeeAdmin,
            address(0)
        );
        DefaultSwapInSafetyControl(safetyControlAddr).initDefaultSafetyControls(
            owner,
            gatewayAddr,
            (1 << 256) - 1,
            (1 << 256) - 1,
            (1 << 256) - 1
        );
        return (gatewayAddr, safetyControlAddr);
    }

    function createTokenAndMintBurnGateway(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) public returns (address, address, address) {
        address token = _createBridgeToken(
            name_,
            symbol_,
            decimals_,
            owner,
            salt,
            address(this)
        );
        (address gateway, address safetyControl) = createMintBurnGateway(
            token,
            owner,
            salt
        );
        BridgeERC20(token).setGateway(gateway);
        BridgeERC20(token).transferAdmin(owner);
        return (token, gateway, safetyControl);
    }
}
