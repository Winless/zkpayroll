// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IZKSyncL1bridge {
    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        uint256 _l2TxGasLimit,
        uint256 _l2TxGasPerPubdataByte,
        address _refundRecipient
    ) external payable returns (bytes32 txHash);
}

interface IZKSync {
    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);
}
//ERC20 0xF29678EA751F0EadCee11cE3627469CB0F9B42F5
//0x927ddfcc55164a59e0f33918d13a2d559bc10ce7
//0x4122342048f9dfc0e44E01d4EC61067B9e39e581

interface IScrollGateway {
    function depositERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable;
}

interface ILineaGateway {
    function depositTo(uint256 amount,address to) external;
}

contract ZKPayRollL1 is Ownable {
    event TransferCommited(address sender, uint totalAmount, address token, uint index, uint chainId);

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint constant public ZKSYNC = 1;
    uint constant public SCROLL = 2;
    uint constant public LINEA = 3;

    uint constant public gasPerPubdataByte = 800;
    address public zksync_bridge = 0x927DdFcc55164a59E0F33918D13a2D559bC10ce7;
    address public zkSync_api = 0x1908e2BF4a88F91E4eF0DC72f02b8Ea36BEa2319;

    address public scroll_gateway = 0x65D123d6389b900d954677c26327bfc1C3e88A13;

    mapping (uint => uint) public txFees;
    mapping (address => uint) public tokenFees;

    receive() external payable {

    }

    function estimateGas(uint gasPrice, uint gasUsage) external view returns(uint fee) {
        fee = IZKSync(zkSync_api).l2TransactionBaseCost(gasPrice, gasUsage, gasPerPubdataByte);
    }

    function setFees(uint chainId, uint fee) external onlyOwner {
        txFees[chainId] = fee;
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

    function commitTransfer(address l2Contract, address token, uint nonce, uint chainId, uint amount, uint gasUsage) external payable {
        (, bytes memory data) = token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
        uint fee = txFees[chainId];
        if(fee > 0) {
            amount = amount.sub(fee);
            tokenFees[token] = tokenFees[token].add(fee);
        }
        uint8 decimals = abi.decode(data, (uint8));
        require(decimals >= 6, "only support decimal greater than 4");
        require(nonce < 10000, "Invalid nonce");
        require(amount % (10 ** (decimals - 2)) == 0, "Only supports 2 decimals");
        uint actualAmount = amount + nonce * (10 ** (decimals - 6));
        if(token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), actualAmount);
            if(chainId == ZKSYNC) {
                IERC20(token).approve(address(zksync_bridge), actualAmount);
                IZKSyncL1bridge(zksync_bridge).deposit{value: msg.value}(l2Contract, token, actualAmount, gasUsage, gasPerPubdataByte, msg.sender);
            } else if(chainId == SCROLL) {
                IERC20(token).approve(address(scroll_gateway), actualAmount);
                IScrollGateway(scroll_gateway).depositERC20{value: msg.value}(token, l2Contract, actualAmount, gasUsage);
            } else if(chainId == LINEA) {
                // require(bridges[chainId][token] != address(0), "not support now");
                // address linea_bridge = bridges[chainId][token];
                // IERC20(token).approve(address(linea_bridge), actualAmount); 
                // ILineaGateway(linea_bridge).depositTo(actualAmount, l2Contract);
            } else {
                require(false, "Invalid chain id");
            }
            emit TransferCommited(msg.sender, amount, token, nonce, chainId);
        }
    }
}