// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this is a MOCK
contract ERC20Mock is ERC20 {
    uint8 public customDecimals = 18;

    constructor(string memory name_, string memory symbol_, uint8 _decimals) ERC20(name_, symbol_) {
        customDecimals = _decimals;
    }

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

    function decimals() public view override returns (uint8) {
        return customDecimals;
    }
}
