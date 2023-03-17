// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./BridgeERC20.sol";
import "./ERC20Gateway_MintBurn.sol";
import "./ERC20Gateway_Pool.sol";

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

contract BridgeFactory {
    address anyCallProxy;
    ICodeShop[3] codeShops;
    address dFaxFeeAdmin;
    address defaultFeeScheme;

    /// @param _codeShops is sort list of CodeShop addresses : `[CS_BridgeToken, CS_MintBurnGateway, CS_PoolGateway]`
    constructor(address _anyCallProxy, address[] memory _codeShops) {
        anyCallProxy = _anyCallProxy;
        for (uint256 i = 0; i < _codeShops.length; i++) {
            codeShops[i] = ICodeShop(_codeShops[i]);
        }
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
    ) public returns (address) {
        address payable addr;
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 pool gateway", addr);
        ERC20Gateway(addr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            dFaxFeeAdmin,
            defaultFeeScheme
        );
        return addr;
    }

    function createMintBurnGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address) {
        address payable addr;
        bytes memory bytecode = codeShops[1].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 mint-burn gateway", addr);
        ERC20Gateway(addr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            dFaxFeeAdmin,
            defaultFeeScheme
        );
        return addr;
    }

    function createTokenAndMintBurnGateway(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address token = _createBridgeToken(
            name_,
            symbol_,
            decimals_,
            owner,
            salt,
            address(this)
        );
        address gateway = createMintBurnGateway(token, owner, salt);
        BridgeERC20(token).setGateway(gateway);
        BridgeERC20(token).transferAdmin(owner);
        return (token, gateway);
    }
}
