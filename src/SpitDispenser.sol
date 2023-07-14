// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@fxportal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@title SpitDispenser - A collaboration between Llamaverse and PG
///@author WhiteOakKong
///@notice SpitDispenser handles the distribution of spit tokens to users who stake spitBuddies on mainnet.

contract SpitDispenser is FxBaseChildTunnel, Ownable {
    uint256 public spitRate = 15 ether;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public spitAccumulated;

    mapping(address => uint256) public lastUpdated;

    ///@dev verify address before deployment
    IERC20 public spit;

    event SpitRateChanged(uint256 newRate);
    event SpitWithdrawn(address indexed recipient, uint256 amount);
    event SpitAddressChanged(address indexed newAddress);
    event SpitClaimed(address indexed user, uint256 amount);

    /*///////////////////////////////////////////////////////////////
    //                        CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////*/

    ///@dev verify address before deployment
    constructor(address _fxChild, address _fxRootTunnel) FxBaseChildTunnel(_fxChild) {
        fxRootTunnel = _fxRootTunnel;
    }

    /*///////////////////////////////////////////////////////////////
    //                        User FUNCTIONS                      //
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows user to withdraw spit tokens
    ///@dev SpitDispenser must contain adequate spit tokens, or call will fail.
    function collectSpit() external updateReward(msg.sender) {
        uint256 amount = spitAccumulated[msg.sender];
        spitAccumulated[msg.sender] = 0;
        spit.transfer(msg.sender, amount);
        emit SpitClaimed(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
    //                 ACCESS CONTROLLED FUNCTIONS                //
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows owner to remove spit from the contract
    ///@param recipient Address to send spit to
    ///@param amount Amount of spit to send
    function withdrawSpit(address recipient, uint256 amount) external onlyOwner {
        spit.transfer(recipient, amount);
        emit SpitWithdrawn(recipient, amount);
    }

    ///@notice Allows owner to update the spit rate
    ///@param reward updated daily spitRate
    function setSpitRate(uint256 reward) external onlyOwner {
        spitRate = reward;
        emit SpitRateChanged(reward);
    }

    ///@notice Allows owner to update the FxRoot Tunnel address
    ///@dev FxRootTunnel is the contract address of SpitYard (mainnet)
    function updateFxRootTunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }

    ///@notice Allows owner to update spit token address
    ///@param _spit new spit token address
    function updateSpitAddress(address _spit) external onlyOwner {
        spit = IERC20(_spit);
        emit SpitAddressChanged(_spit);
    }

    /*///////////////////////////////////////////////////////////////
    //                  INTERNAL STAKING LOGIC                    //
    //////////////////////////////////////////////////////////////*/

    ///@notice Updates the user balance and last updated time
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        lastUpdated[account] = block.timestamp;
        spitAccumulated[account] += amount;
        _;
    }

    ///@notice Updates the staked balance when a spitBuddy is staked on mainnet
    ///@param account target address
    ///@param amount amount of spitBuddies to credit stake
    function processStake(address account, uint256 amount) internal updateReward(account) {
        stakedBalance[account] += amount;
    }

    ///@notice Updates the staked balance when a spitBuddy is unstaked on mainnet
    ///@param account target address
    ///@param amount amount of spitBuddies to credit unstake
    function processUnstake(address account, uint256 amount) internal updateReward(account) {
        stakedBalance[account] -= amount;
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    )
        internal
        override
        validateSender(sender)
    {
        (address from, uint256 count, bool action) = abi.decode(message, (address, uint256, bool));
        action ? processStake(from, count) : processUnstake(from, count);
    }

    /*///////////////////////////////////////////////////////////////
    //                         UTILITIES                          //
    //////////////////////////////////////////////////////////////*/

    function earned(address account) internal view returns (uint256) {
        return rewardsPerSecond(account) * (block.timestamp - lastUpdated[account]);
    }

    ///@notice Returns the amount of spit tokens a user can collect
    ///@param account User address
    ///@return Amount of spit tokens a user can collect
    function getUserAccruedRewards(address account) external view returns (uint256) {
        return spitAccumulated[account] + earned(account);
    }

    function rewardsPerSecond(address account) internal view returns (uint256) {
        return (stakedBalance[account] * spitRate) / 1 days;
    }
}
