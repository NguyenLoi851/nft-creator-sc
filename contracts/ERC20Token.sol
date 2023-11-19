// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Token is ERC20Upgradeable {
    uint8 _decimals = 18;

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) public initializer {
        __ERC20_init(name, symbol);
        // ERC20Upgradeable._mint(msg.sender, (10**9)*(10**18));
        setDecimals(decimals_);
    }

    function mint(address _to, uint _amount) public {
        ERC20Upgradeable._mint(_to, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setDecimals(uint8 decimals_) public {
        _decimals = decimals_;
    }

    function burn(address _from, uint _amount) public {
        ERC20Upgradeable._burn(_from, _amount);
    }
}
