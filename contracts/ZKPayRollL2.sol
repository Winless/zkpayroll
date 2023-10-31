// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ZKPayRollL2 is ReentrancyGuard, Ownable {
    bytes32 public root;
    bool public enable = false;
    string public greeting;

    uint public txFee = 5e18;
    mapping (address => uint) public tokenFees;

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event TransferScroll(address user, uint amount, address tokenL1, address sender);
    event UpdateRoot(bytes32 oldRoot, bytes32 newRoot);
    event Withdraw(address user, address token, uint amount, uint fee);

    function updateRoot(bytes32 _newRoot) external onlyOwner {
        emit UpdateRoot(root, _newRoot);
        root = _newRoot;
        enable = true;
    }   

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function setFees(uint fee) external onlyOwner {
        txFee = fee;
    }

    function receiveScrollMessage(address user, uint amount, address tokenL1) external {
        emit TransferScroll(user, amount, tokenL1, msg.sender);
    }

    function withdrawFee(address token) external {
        if(token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            uint totalFee = tokenFees[token];
            IERC20(token).safeTransfer(owner(), totalFee);
            tokenFees[token] = 0;
        }
    }

    function withdraw(bytes memory data, bytes32[] memory proof) external nonReentrant {
        require(enable, "Not enable now");
        enable = false;
        (uint totalAmt, uint withdrawAmt, address token) = abi.decode(data, (uint, uint, address));
        require(totalAmt >= withdrawAmt, "Invalid amount");
        _verify(proof, token, msg.sender, totalAmt);

        uint fee;
        if(txFee > 0) {
            (, bytes memory decimalData) = token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            uint8 decimals = abi.decode(decimalData, (uint8));
            fee = txFee.div(1e18).mul(10**decimals);
            require(withdrawAmt >= fee, "Insufficient fee");
            withdrawAmt = withdrawAmt.sub(fee);
            tokenFees[token] = tokenFees[token].add(fee);
        }
        
        IERC20(token).safeTransfer(msg.sender, withdrawAmt);
        emit Withdraw(msg.sender, token, withdrawAmt, fee);
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
