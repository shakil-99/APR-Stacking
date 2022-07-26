// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./narutoCoin.sol";


contract Staking is ERC20{
    narutoCoin _narutoCoin;

    struct staker{
        uint256 tokens;
        uint256 staketime;
        uint256 rewardtime;
        uint256 rewardRate;
        uint256 penaltyRate;
    }

    address public owner;
    uint256 public prices;
    uint256 public lockTime;
    uint256 public RewardEnable;
    uint256 private _rewardRate;
    uint256 private _penaltyRate;

    mapping(address => staker)internal staking;

    modifier onlyOwner{
        require(msg.sender == owner,"It seems only owner of this contract can call");
        _;
    }


    constructor(address _rewardCoin,uint256 _lockTime)ERC20("NarutoToken","NTn"){
        owner = msg.sender;
        prices = 10000;
        _rewardRate = 1025;
        _penaltyRate = 1025;
        lockTime = _lockTime;
        _narutoCoin = narutoCoin(_rewardCoin);
    }

    function setPrice(uint256 _price)public onlyOwner{
        prices = _price;
    }


    function stake(uint256 _amount)public {
        require(_amount != 0,"You can put 0 token on stake");
        uint256 amount = _amount *1e18;
        require(amount<=balanceOf(msg.sender),"insufficient Token in account");
        _transfer(msg.sender,address(this),amount);
        if(staking[msg.sender].tokens != 0){

            staking[msg.sender].tokens += amount;
            staking[msg.sender].staketime = block.timestamp;
            staking[msg.sender].rewardtime = block.timestamp;
            staking[msg.sender].penaltyRate = _penaltyRate;
        }
    }

    function unstake()public{
        if(block.timestamp - staking[msg.sender].staketime >= lockTime){
            _transfer(address(this),msg.sender,staking[msg.sender].tokens);
        }
        else if(staking[msg.sender].rewardRate !=0 ){
            _narutoCoin.mint(msg.sender,_CalculateRewards(msg.sender));
        }
        else{
            transferFrom(address(this),owner,_penalty(msg.sender));

            _transfer(address(this),owner,staking[msg.sender].tokens - staking[msg.sender].penaltyRate);
        }
        delete staking[msg.sender];
    }


    function setRate(uint256 reward,uint256 penalty)public onlyOwner{
        require(reward <= 10000,"Reward rate should not more tha 100%");
        require(penalty <= 10000,"Penalty should not be 100%");
        _rewardRate = reward;
        _penaltyRate = penalty;
    }

    function claimRewards()public{
        require(staking[msg.sender].rewardRate != 0,"Rewards cannot be available while staking");
        require(block.timestamp - staking[msg.sender].staketime >= lockTime,"Reward time period is not over" );
        _narutoCoin.mint(msg.sender,_CalculateRewards(msg.sender));
        staking[msg.sender].rewardtime =block.timestamp;
    }

    

    function _CalculateRewards(address _staker)internal view returns(uint256){
        uint256 time = block.timestamp - staking[msg.sender].rewardtime;

        return(staking[msg.sender].tokens * staking[msg.sender].rewardRate * time) / (1000 * 365 days);
    }

    function _penalty(address _staker)internal view returns(uint256){
        return (staking[msg.sender].tokens * staking[msg.sender].penaltyRate) / 10000;
    }

    function mint(uint256 amount)public{
        _mint(msg.sender,amount*1e18);
    }


}