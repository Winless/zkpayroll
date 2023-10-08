// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this is a MOCK
contract ERC20Mock is ERC20 {
    uint constant InitSupply = 1000000000 * 1e18;
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, InitSupply);
    }
}
