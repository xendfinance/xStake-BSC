// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IXend.sol";

/**
 * @title Staking
 * @dev   Staking Contract
 */
contract XendStaking {
    
  using SafeMath for uint256;
  address private _owner;                                           // variable for Owner of the Contract.
  uint256 private _withdrawTime;                                    // variable to manage withdraw time for Token
  uint256 constant public PERIOD_SILVER            = 30;            // variable constant for time period managemnt
  uint256 constant public PERIOD_GOLD              = 60;            // variable constant for time period managemnt
  uint256 constant public PERIOD_PLATINUM          = 90;            // variable constant for time period managemnt
  uint256 constant public WITHDRAW_TIME_SILVER     = 15 * 1 days;   // variable constant to manage withdraw time lock up 
  uint256 constant public WITHDRAW_TIME_GOLD       = 30 * 1 days;   // variable constant to manage withdraw time lock up
  uint256 constant public WITHDRAW_TIME_PLATINUM   = 60 * 1 days;   // variable constant to manage withdraw time lock up
  uint256 constant public TOKEN_REWARD_PERCENT_SILVER    = 565;      // variable constant to manage token reward percentage for silver
  uint256 constant public TOKEN_REWARD_PERCENT_GOLD      = 1754;      // variable constant to manage token reward percentage for gold
  uint256 constant public TOKEN_REWARD_PERCENT_PLATINUM  = 3555;      // variable constant to manage token reward percentage for platinum
  uint256 constant public TOKEN_PENALTY_PERCENT_SILVER   = 142;       // variable constant to manage token penalty percentage for silver
  uint256 constant public TOKEN_PENALTY_PERCENT_GOLD     = 504;       // variable constant to manage token penalty percentage for silver
  uint256 constant public TOKEN_PENALTY_PERCENT_PLATINUM = 1767;       // variable constant to manage token penalty percentage for silver
  
  // events to handle staking pause or unpause for token
  event Paused();
  event Unpaused();
  
  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functions for owner.
  * ---------------------------------------------------------------------------------------------------------------------------
  */

   /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
   function getowner() external view returns (address) {
     return _owner;
   }

   /**
   * @dev modifier to check if the message sender is owner
   */
   modifier onlyOwner() {
     require(isOwner(),"You are not authenticate to make this transfer");
     _;
   }

   /**
   * @dev Internal function for modifier
   */
   function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
   }

   /**
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
   function transferOwnership(address newOwner) external onlyOwner returns (bool){
      _owner = newOwner;
      return true;
   }
   
  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Constructor and Interface  
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // constructor to declare owner of the contract during time of deploy  
  constructor() public {
     _owner = msg.sender;
  }
  
  // Interface declaration for contract
  IXend ixend;
    
  // function to set Contract Address for Token Transfer Functions
  function setContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    ixend = IXend(tokenContractAddress);
    return true;
  }
  
   /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and other Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // function to add token reward in contract
  function addTokenReward(uint256 token) external onlyOwner returns(bool){
    _ownerTokenAllowance = _ownerTokenAllowance.add(token);
    ixend.transferFrom(msg.sender, address(this), token);
    return true;
  }
  
  // function to withdraw added token reward in contract
  function withdrawAddedTokenReward(uint256 token) external onlyOwner returns(bool){
    require(token < _ownerTokenAllowance,"Value is not feasible, Please Try Again!!!");
    _ownerTokenAllowance = _ownerTokenAllowance.sub(token);
    ixend.transferFrom(address(this), msg.sender, token);
    return true;
  }
  
  // function to get token reward in contract
  function getTokenReward() external view returns(uint256){
    return _ownerTokenAllowance;
  }
  
  // function to pause Token Staking
  function pauseTokenStaking() external onlyOwner {
    tokenPaused = true;
    emit Paused();
  }

  // function to unpause Token Staking
  function unpauseTokenStaking() external onlyOwner {
    tokenPaused = false;
    emit Unpaused();
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Token Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _tokenStakingAddress;
  
  // mapping for users with address => id staking id
  mapping (address => uint256[]) private _tokenStakingId;

  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _tokenStakingStartTime;
  
  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _tokenStakingEndTime;

  // mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionStatus;    
  
  // mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalTokenStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _tokenTotalDays;
  
  // variable to keep count of Token Staking
  uint256 private _tokenStakingCount = 0;
  
  // variable to keep track on reward added by owner
  uint256 private _ownerTokenAllowance = 0;

  // variable for token time management
  uint256 private _tokentime;
  
  // variable for token staking pause and unpause mechanism
  bool public tokenPaused = false;
  
  // variable for total Token staked by user
  uint256 public totalStakedToken = 0;
  
  // variable for total stake token in contract
  uint256 public totalTokenStakesInContract = 0;
  
  // modifier to check the user for staking || Re-enterance Guard
  modifier tokenStakeCheck(uint256 tokens, uint256 timePeriod){
    require(tokens > 0, "Invalid Token Amount, Please Try Again!!! ");
    require(timePeriod == PERIOD_SILVER || timePeriod == PERIOD_GOLD || timePeriod == PERIOD_PLATINUM, "Enter the Valid Time Period and Try Again !!!");
    _;
  }
    
  /*
  * ------------------------------------------------------------------------------------------------------------------------------
  * Functions for Token Staking Functionality
  * ------------------------------------------------------------------------------------------------------------------------------
  */

  // function to performs staking for user tokens for a specific period of time
  function stakeToken(uint256 tokens, uint256 time) external tokenStakeCheck(tokens, time) returns(bool){
    require(tokenPaused == false, "Staking is Paused, Please try after staking get unpaused!!!");
    _tokentime = now + (time * 1 days);
    _tokenStakingCount = _tokenStakingCount + 1;
    _tokenTotalDays[_tokenStakingCount] = time;
    _tokenStakingAddress[_tokenStakingCount] = msg.sender;
    _tokenStakingId[msg.sender].push(_tokenStakingCount);
    _tokenStakingEndTime[_tokenStakingCount] = _tokentime;
    _tokenStakingStartTime[_tokenStakingCount] = now;
    _usersTokens[_tokenStakingCount] = tokens;
    _TokenTransactionStatus[_tokenStakingCount] = false;
    _tokenStakingCount = _tokenStakingCount +1;
    totalStakedToken = totalStakedToken.add(tokens);
    totalTokenStakesInContract = totalTokenStakesInContract.add(tokens);
    ixend.transferFrom(msg.sender, address(this), tokens);
    return true;
  }

  // function to get staking count for token
  function getTokenStakingCount() external view returns(uint256){
    return _tokenStakingCount;
  }
  
  // function to get total Staked tokens
  function getTotalStakedToken() external view returns(uint256){
    return totalStakedToken;
  }
  
  // function to calculate reward for the message sender for token
  function getTokenRewardDetailsByStakingId(uint256 id) public view returns(uint256){
    if(_tokenTotalDays[id] == PERIOD_SILVER) {
        return (_usersTokens[id]*TOKEN_REWARD_PERCENT_SILVER/100000);
    } else if(_tokenTotalDays[id] == PERIOD_GOLD) {
               return (_usersTokens[id]*TOKEN_REWARD_PERCENT_GOLD/100000);
      } else if(_tokenTotalDays[id] == PERIOD_PLATINUM) { 
                 return (_usersTokens[id]*TOKEN_REWARD_PERCENT_PLATINUM/100000);
        } else{
              return 0;
          }
  }

  // function to calculate penalty for the message sender for token
  function getTokenPenaltyDetailByStakingId(uint256 id) public view returns(uint256){
    if(_tokenStakingEndTime[id] > now){
        if(_tokenTotalDays[id]==PERIOD_SILVER){
            return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_SILVER/100000);
        } else if(_tokenTotalDays[id] == PERIOD_GOLD) {
              return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_GOLD/100000);
          } else if(_tokenTotalDays[id] == PERIOD_PLATINUM) { 
                return (_usersTokens[id]*TOKEN_PENALTY_PERCENT_PLATINUM/100000);
            } else {
                return 0;
              }
    } else{
       return 0;
     }
  }
 
  // function for withdrawing staked tokens
  function withdrawStakedTokens(uint256 stakingId) external returns(bool) {
    require(_tokenStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionStatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    if(_tokenTotalDays[stakingId] == PERIOD_SILVER){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_SILVER, "Unable to Withdraw Staked token before 15 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionStatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_usersTokens[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else if(_tokenTotalDays[stakingId] == PERIOD_GOLD){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_GOLD, "Unable to Withdraw Staked token before 30 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionStatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else if(_tokenTotalDays[stakingId] == PERIOD_PLATINUM){
          require(now >= _tokenStakingStartTime[stakingId] + WITHDRAW_TIME_PLATINUM, "Unable to Withdraw Staked token before 45 days of staking start time, Please Try Again Later!!!");
          _TokenTransactionStatus[stakingId] = true;
          if(now >= _tokenStakingEndTime[stakingId]){
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
          } else {
              _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
              ixend.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
              totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
            }
    } else {
        return false;
      }
    return true;
  }
  
  // function to get Final Withdraw Staked value for token
  function getFinalTokenStakeWithdraw(uint256 id) external view returns(uint256){
    return _finalTokenStakeWithdraw[id];
  }
  
  // function to get total token stake in contract
  function getTotalTokenStakesInContract() external view returns(uint256){
      return totalTokenStakesInContract;
  }
  
  /*
  * -------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Stake Token Functionality
  * -------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get Token Staking address by id
  function getTokenStakingAddressById(uint256 id) external view returns (address){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingAddress[id];
  }
  
  // function to get Token staking id by address
  function getTokenStakingIdByAddress(address add) external view returns(uint256[] memory){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _tokenStakingId[add];
  }
  
  // function to get Token Staking Starting time by id
  function getTokenStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingStartTime[id];
  }
  
  // function to get Token Staking Ending time by id
  function getTokenStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingEndTime[id];
  }
  
  // function to get Token Staking Total Days by Id
  function getTokenStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenTotalDays[id];
  }

  // function to get Staking tokens by id
  function getStakingTokenById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }

  // function to get Token lockstatus by id
  function getTokenLockStatus(uint256 id) external view returns(bool){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _TokenTransactionStatus[id];
  }
  
}