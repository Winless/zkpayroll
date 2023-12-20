// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

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

interface IBSCBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage // slippage * 1M, eg. 0.5% -> 5000
    ) external;
}

interface IZKSync {
    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);
}

// linea bridge 0x504A330327A089d8364C4ab3811Ee26976d388ce

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

contract ZKPayRollL1 is Ownable, Pausable {
    event TransferCommited(address sender, uint totalAmount, address token, uint index, uint chainId);

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint constant public ZKSYNC = 1;
    uint constant public SCROLL = 2;
    uint constant public LINEA = 3;

    uint constant public gasPerPubdataByte = 800;
    address public zksync_bridge = 0x57891966931Eb4Bb6FB81430E6cE0A03AAbDe063;
    address public scroll_gateway = 0xD8A791fE2bE73eb6E6cF1eb0cb3F36adC9B3F8f9;
    address public bsc_bridge = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;

    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    mapping (uint => uint) public txFees;
    mapping (address => uint) public tokenFees;
    mapping (uint => mapping (address => address)) public bridges;

    constructor(address owner) Ownable(owner){
        IERC20(USDC).safeIncreaseAllowance(zksync_bridge, 1000000000 * 1e6);
        IERC20(USDT).safeIncreaseAllowance(zksync_bridge, 1000000000 * 1e6);
        IERC20(USDT).safeIncreaseAllowance(bsc_bridge, 1000000000 * 1e6);
        IERC20(USDC).safeIncreaseAllowance(bsc_bridge, 1000000000 * 1e6);
        IERC20(USDC).safeIncreaseAllowance(scroll_gateway, 1000000000 * 1e6);
        IERC20(USDT).safeIncreaseAllowance(scroll_gateway, 1000000000 * 1e6);
    }

    receive() external payable {

    }


    function setFees(uint chainId, uint fee) external onlyOwner {
        txFees[chainId] = fee;
    }

     function setBridges(uint chainId, address token, address bridge) external onlyOwner {
        bridges[chainId][token] = bridge;
    }

    function claimFailedToken(address token, uint amount, address to) external  onlyOwner {
        if(token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function withdrawFee(address token, address to) external onlyOwner {
        if(token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            uint totalFee = tokenFees[token];
            IERC20(token).safeTransfer(to, totalFee);
            tokenFees[token] = 0;
        }
    }

    function checkApprove(address token, address bridge, uint amount) internal {
        uint approveAmount = IERC20(token).allowance(address(this), bridge);
        if(approveAmount < amount) {
            IERC20(token).approve(address(bridge), amount);
        }
    }

    function commitTransferBSC(address l2Contract, address token, uint64 nonce, uint amount, uint fee) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount + fee);
        checkApprove(token, bsc_bridge, amount);
        IBSCBridge(bsc_bridge).send(l2Contract, token, amount + fee, 56, nonce, 20000);
        emit TransferCommited(msg.sender, amount, token, nonce, 4);
    }

    function commitTransfer(address l2Contract, address token, uint nonce, uint chainId, uint amount, uint gasUsage) external payable {
        (, bytes memory data) = token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
        uint8 decimals = abi.decode(data, (uint8));
        require(decimals >= 6, "only support decimal greater than 4");
        require(nonce < 10000, "Invalid nonce");
        require(amount % (10 ** (decimals - 2)) == 0, "Only supports 2 decimals");
        uint actualAmount = amount + nonce * (10 ** (decimals - 6));
        
        uint fee = txFees[chainId].div(1e18).mul(10**decimals);
        uint payAmount = actualAmount;
        if(fee > 0) {
            payAmount = payAmount.add(fee);
            tokenFees[token] = tokenFees[token].add(fee);
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), payAmount);

        if(token != address(0)) {
            if(chainId == ZKSYNC) {
                checkApprove(token, zksync_bridge, actualAmount);
                IZKSyncL1bridge(zksync_bridge).deposit{value: msg.value}(l2Contract, token, actualAmount, gasUsage, gasPerPubdataByte, msg.sender);
            } else if(chainId == SCROLL) {
                checkApprove(token, scroll_gateway, actualAmount);
                IScrollGateway(scroll_gateway).depositERC20{value: msg.value}(token, l2Contract, actualAmount, gasUsage);
            } else if(chainId == LINEA) {
                require(bridges[chainId][token] != address(0), "not support now");
                address linea_bridge = bridges[chainId][token];
                IERC20(token).approve(address(linea_bridge), actualAmount); 
                ILineaGateway(linea_bridge).depositTo(actualAmount, l2Contract);
            } else {
                require(false, "Invalid chain id");
            }
            emit TransferCommited(msg.sender, amount, token, nonce, chainId);
        }
    }
}