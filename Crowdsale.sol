pragma solidity ^0.4.11;

import './QuasacoinToken.sol';

/**
 * @title QuasocoinCrowdsale
 * based upon OpenZeppelin CrowdSale smartcontract
 */
contract QuasacoinTokenCrowdsale {
  using SafeMath for uint256;

  // The token being sold
  QuasacoinToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startPreICOTime;
  // переход из preICO в ICO
  uint256 public startICOTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // кому вернуть ownership после завершения ICO
  address public tokenOwner;

  // how many token units a buyer gets per wei
  uint256 public ratePreICO;
  uint256 public rateICO;

  // amount of raised money in wei
  uint256 public weiRaisedPreICO;
  uint256 public weiRaisedICO;

  uint256 public capPreICO;
  uint256 public capICO;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);






  function QuasacoinTokenCrowdsale(address _wallet, address _tokenOwner, address _quasacoinTokenAddress) {
    require(_tokenOwner != 0x0);
    require(_wallet != 0x0);

    token = QuasacoinToken(_quasacoinTokenAddress);
    tokenOwner = _tokenOwner;
    wallet = _wallet;

    // 15.01.18 00:00:00 (1515974400) 
    startPreICOTime = 1515974400;
    // 15.02.18 00:00:00 (1518652800)
    startICOTime = 1518652800;
    // 26.03.18 00:00:00 (1522022400)
    endTime = 1522022400;
    
    
    // Pre-ICO, 1 ETH = 6000 QUA
    ratePreICO = 6000;

    // ICO, 1 ETH = 3000 QUA
    rateICO = 3000;

    capPreICO = 1850 ether;
    capICO = 58892 ether;

  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens;
    if(now < startICOTime) {  
      weiRaisedPreICO = weiRaisedPreICO.add(weiAmount);
      tokens = weiAmount * ratePreICO;
    } 
    else {
      weiRaisedICO = weiRaisedICO.add(weiAmount);
      tokens = weiAmount * rateICO;
    }



    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
   
    if(now >= startPreICOTime && now < startICOTime) {
      return weiRaisedPreICO.add(msg.value) <= capPreICO;
    } else if(now >= startICOTime && now < endTime) {
      return weiRaisedICO.add(msg.value) <= capICO;
    } else
    return false;


  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    if(now < startPreICOTime)
      return false;
    else if(now >= startPreICOTime && now < startICOTime) {
      return weiRaisedPreICO >= capPreICO;
    } else if(now >= startICOTime && now < endTime) {
      return weiRaisedICO >= capICO;
    } else
      return true;
  }

  function returnTokenOwnership() public {
    require(now < startPreICOTime || now > endTime  || (now >= startICOTime && hasEnded()));
    token.transferOwnership(tokenOwner);
  }


}
