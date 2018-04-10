pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./MaestroToken.sol";

/**
 * Maestro crowdsale season #1
 */
contract CrowdsaleS1 is CappedCrowdsale, TimedCrowdsale {

  uint constant public decimals = 18;
	// address of wallet to which tokens for company will be transfered
	address constant public addressCompanyReserveTokenWallet = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;
	// number of tokens for company-reserve
	uint constant public numCompanyReserveTokens = 1000000 * 10**decimals;

	address public tokenAddress;

  function CrowdsaleS1(
    uint256 _openingTime, // opening time in timestamp
    uint256 _closingTime,	// closing time in timestamp
    uint256 _rate,				// How many token units a buyer gets per wei
    address _wallet,		// Address where funds are collected
    uint256 _cap,			// Max amount of wei to be contributed
    address _tokenAddress	// The token being sold
    //uint256 _goal
  )
    public
    Crowdsale(_rate, _wallet, MaestroToken(_tokenAddress))
    CappedCrowdsale(_cap)
    TimedCrowdsale(_openingTime, _closingTime)
  {
		tokenAddress = _tokenAddress;
    //the value needs to less or equal than a cap which is limit for accepted funds
    //require(_goal <= _cap);

		// Distribute initial tokens to company and parteners
		reserveInitialCompanyTokens();
  }

	/**
	 * Grant initial tokens to company members
	 */
	//function reserveInitialCompanyTokens() public {

	function reserveInitialCompanyTokens() internal {
		// Company-reserve tokens
		MaestroToken(tokenAddress).transfer(addressCompanyReserveTokenWallet, numCompanyReserveTokens);

		//
		// TODO:
		// 
		// Distribute initial tokens to partners and creators
		//
		address[] storage recipients;
		recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
		recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
		recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
		recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);

		uint[] storage tokens;
		tokens.push(100000*10**decimals);
		tokens.push(100000*10**decimals);
		tokens.push(100000*10**decimals);
		tokens.push(100000*10**decimals);

		MaestroToken(tokenAddress).adminBatchTransferWithLockup(recipients, tokens);
	}
}

