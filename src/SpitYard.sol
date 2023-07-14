// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@fxportal/contracts/tunnel/FxBaseRootTunnel.sol";

///@title SpitYard - A collaboration between Llamaverse and PG
///@author WhiteOakKong
///@notice Spityard handles staking and unstaking of SpitBuddies, and communicates with JIRACentral/SpitDispenser
/// contracts.

interface IJiraCentral {
    function _increaseGeneration(address _address, uint256 dailyAmount) external;

    function _decreaseGeneration(address _address, uint256 dailyAmount) external;
}

contract SpitYard is FxBaseRootTunnel, Ownable {
    /*///////////////////////////////////////////////////////////////
    //                      STORAGE                               //
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256[]) public userStake;

    IERC721A public spitBuddies;
    IJiraCentral public jiraCentral;

    bool public stakingPaused;

    uint256 public constant JIRA_REWARD = 6 ether;

    /*///////////////////////////////////////////////////////////////
    //                       EVENTS                               //
    //////////////////////////////////////////////////////////////*/

    event JiraCentralChanged(address indexed _newJiraCentral);
    event SpitBuddiesChanged(address indexed _newSpitBuddies);
    event SpitBuddiesStaked(address indexed _user, uint256[] _tokenIds);
    event SpitBuddiesUnstaked(address indexed _user, uint256[] _tokenIds);
    event StakingPaused(bool status);

    /*///////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                           //
    //////////////////////////////////////////////////////////////*/
    constructor(
        address checkpointManager,
        address fxRoot,
        address _spitBuddiesContract
    )
        FxBaseRootTunnel(checkpointManager, fxRoot)
    {
        spitBuddies = IERC721A(_spitBuddiesContract);
    }

    /*///////////////////////////////////////////////////////////////
                        STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to stake an array of SpitBuddies NFTs.
    /// @param tokenIds An array of SpitBuddies to stake.
    function stake(uint256[] memory tokenIds) external {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 value = tokenIds.length;
        for (uint256 i; i < value; i++) {
            spitBuddies.transferFrom(msg.sender, address(this), tokenIds[i]);
            userStake[msg.sender].push(tokenIds[i]);
        }
        _sendMessageToChild(abi.encode(msg.sender, value, true));
        jiraCentral._increaseGeneration(msg.sender, value * JIRA_REWARD);
    }

    /// @notice Function to unstake an array of SpitBuddies NFTs.
    /// @param tokenIds An array of SpitBuddies to unstake.
    function unstake(uint256[] memory tokenIds) external {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 value = tokenIds.length;
        for (uint256 i; i < value; i++) {
            removeToken(msg.sender, tokenIds[i]);
            spitBuddies.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        _sendMessageToChild(abi.encode(msg.sender, value, false));
        jiraCentral._decreaseGeneration(msg.sender, value * JIRA_REWARD);
    }

    /// @notice Function to get the staked tokens for a given address.
    /// @param _address The address to check.
    /// @return An array of staked token IDs.
    function getUserStake(address _address) external view returns (uint256[] memory) {
        return userStake[_address];
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the contract address for the SpitBuddies contract.
    /// @param _spitBuddiesContract The contract address of SpitBuddies.
    function setSpitBuddies(address _spitBuddiesContract) external onlyOwner {
        spitBuddies = IERC721A(_spitBuddiesContract);
        emit SpitBuddiesChanged(_spitBuddiesContract);
    }

    /// @notice Set the contract address for the JiraCentral contract.
    /// @dev Only callable by the contract owner.
    /// @param _jiraCentral The contract address of JiraCentral.
    function setJiraCentral(address _jiraCentral) external onlyOwner {
        jiraCentral = IJiraCentral(_jiraCentral);
        emit JiraCentralChanged(_jiraCentral);
    }

    /// @notice Pauses staking and unstaking, for emergency purposes
    function setStakingPaused(bool paused) external onlyOwner {
        stakingPaused = paused;
        emit StakingPaused(stakingPaused);
    }

    /*///////////////////////////////////////////////////////////////
                         UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns staked token count for a given address.
    function balanceOf(address owner) external view returns (uint256) {
        return userStake[owner].length;
    }

    function removeToken(address _user, uint256 tokenId) internal {
        if (userStake[_user].length == 0) revert("Caller Not Owner Of Token");
        uint256 len = userStake[_user].length;
        for (uint256 i; i < len; i++) {
            if (userStake[_user][i] == tokenId) {
                userStake[_user][i] = userStake[_user][len - 1];
                userStake[_user].pop();
                break;
            }
            if (i == len - 1 && userStake[_user][i] != tokenId) revert("Caller Not Owner Of Token");
        }
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // 🐲🦙
    }
}
