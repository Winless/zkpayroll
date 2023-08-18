// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZKPayRollL2 is ReentrancyGuard, Ownable {
    bytes32 public root;
    bool public enable = false;

    using SafeERC20 for IERC20;

    event UpdateRoot(bytes32 oldRoot, bytes32 newRoot);
    event Withdraw(address user, address token, uint amount);

    function updateRoot(bytes32 _newRoot) external onlyOwner {
        emit UpdateRoot(root, _newRoot);
        root = _newRoot;
        enable = true;
    }   


    function withdraw(bytes memory data, bytes32[] memory proof) external nonReentrant {
        require(enable, "Not enable now");
        enable = false;
        (uint totalAmt, uint withdrawAmt, address token) = abi.decode(data, (uint, uint, address));
        require(totalAmt >= withdrawAmt, "Invalid amount");
        _verify(proof, token, msg.sender, totalAmt);
        IERC20(token).safeTransfer(msg.sender, withdrawAmt);
        emit Withdraw(msg.sender, token, withdrawAmt);
    }

    function _verify(
        bytes32[] memory proof,
        address token,
        address addr,
        uint256 amount
    ) internal view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, token, amount))));
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
    }
}
