pragma solidity ^0.4.16;

/**
 * SafeMath
 *
 * Safe math operations in lieu of +,-,*,/  that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * Interface to MaestroToken
 */
interface token {
	function transfer(address receiver, uint amount) external;
	function adminBatchTransferWithLockup(address[] _recipients, uint[] _values) external returns (bool);
}

/**
 * Maestro Crowsale S1 - Presale
 */
contract CrowdsaleS1 {
	using SafeMath for uint;

	////////////////////////////////////////////////////////
	// Input parameters (Moved from the constructor inputs
	// TODO: Specify with correct values
	//
	address public etherWalletAddressToReceiveFunds = 0x8695d0f1bfd6eecc8dc23fd0654715c7a04f817f;
	address public companyReserveTokenWalletAddress = 0x8695d0f1bfd6eecc8dc23fd0654715c7a04f817f;
	address public tokenContractAddress = 0x8695d0f1bfd6eecc8dc23fd0654715c7a04f817f;
	uint public numberOfCompanyReserveTokens = 100000000 * 18 / 100;
	uint public fundingGoalInTokens = 100000000 * 30 / 100;
	uint public durationInMinutes = 30 * 24 * 60; // 30 days
	uint public tokensPerEther = 1000;
	////////////////////////////////////////////////////////

	// address of wallet to which fund will be transfered
	address public addressFundWallet;
	// address of wallet to which tokens for company will be transfered
	address public addressCompanyReserveTokenWallet;
	// number of tokens for company-reserve
	uint public numCompanyReserveTokens;
	// Funding goal in tokens
	uint public goalInEthers;
	// Funding goal in tokens
	uint public goalInTokens;
	// how much has been raised by crowdale (in ETH)
	uint public amountRaisedInEthers;
	// the end date of the crowdsale
	uint public endDate;
	// the number of tokens already sold
  uint public tokensSold = 0;
	// the price of token in ethers
	uint public ethersPerToken;
	// pointer to the token contract instance
	token public theToken;
	// the balances (in ETH) of all funders
	mapping(address => uint256) public ethBalanceOf;

	// flags
	bool fundingGoalReached = false;
	bool crowdsaleClosed = false;

  uint constant public decimals = 18;
	// events
	event GoalReached(address recipient, uint totalAmountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution, uint amountRaised);

	/**
	 * Constrctor function
	 *
	 * Setup the owner
	 */
	function CrowdsaleS1 (
		/* Constructor arguments will go static
			address etherWalletAddressToReceiveFunds,
			address companyReserveTokenWalletAddress,
			address tokenContractAddress,				// address to token contract
			uint numberOfCompanyReserveTokens,
			uint fundingGoalInTokens,
			uint durationInMinutes,
			uint tokensPerEther
			*/
		) public {


		addressFundWallet = etherWalletAddressToReceiveFunds;
		addressCompanyReserveTokenWallet = companyReserveTokenWalletAddress;
		numCompanyReserveTokens = numberOfCompanyReserveTokens * 10**decimals;
		endDate = now + durationInMinutes * 1 minutes;
		ethersPerToken = 1 ether / tokensPerEther; 		// price
		goalInTokens = fundingGoalInTokens * 10**decimals;
		goalInEthers = goalInTokens * ethersPerToken;

		amountRaisedInEthers = 0;
		theToken = token(tokenContractAddress);

		// Distribute initial tokens to company and parteners
		reserveInitialCompanyTokens();

	}

	/**
	 * Grant initial tokens to company members
	 */
	function reserveInitialCompanyTokens() internal {
		// Company-reserve tokens
		theToken.transfer(addressCompanyReserveTokenWallet, numCompanyReserveTokens);

		//
		// TODO:
		// 
		// Distribute to partners by setting up the list and call:
		// theToken.adminBatchTransferWithLockup()
		//
	}

	/**
	 * modifier
	 */
	modifier afterDeadline() { 
		if (now >= endDate) 
			_; 
	}

	/**
	 * Fallback function
	 *
	 * The function without name is the default function that is called whenever anyone sends funds to a contract.
	 * Investment captured here.
	 */
	function () payable public {
		require(!crowdsaleClosed);
    require(msg.sender != addressFundWallet); //do not trigger investment if the wallet is returning the funds

    uint amount = msg.value;
		uint numTokens = amount / ethersPerToken;

    require(numTokens > 0);
    require(!crowdsaleClosed && now <= endDate && tokensSold.add(numTokens) <= goalInTokens);

		// transfer ethers to wallet
    addressFundWallet.transfer(amount);

		// update balance
    ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(amount);

		// update total amounts
    amountRaisedInEthers = amountRaisedInEthers.add(amount);
    tokensSold += numTokens;

		// transfer tokens to the sender (funder)
    theToken.transfer(msg.sender, numTokens);
    emit FundTransfer(msg.sender, amount, true, amountRaisedInEthers);
  }

	/**
	 * Check if goal was reached
	 *
	 * Checks if the goal or time limit has been reached and ends the campaign
	 */
	function checkGoalReached() afterDeadline public {
		if (amountRaisedInEthers >= goalInEthers){
			fundingGoalReached = true;
			emit GoalReached(addressFundWallet, amountRaisedInEthers);
		}
		crowdsaleClosed = true;
	}

	/** Not using
	function safeRefund() afterDeadline public {
		if (!fundingGoalReached) {
			uint amount = ethBalanceOf[msg.sender];
			ethBalanceOf[msg.sender] = 0;
			if (amount > 0) {
				if (msg.sender.send(amount)) {
					emit FundTransfer(msg.sender, amount, false);
				} else {
					ethBalanceOf[msg.sender] = amount;
				}
			}
		}

		if (fundingGoalReached && addressTokenOwner == msg.sender) {
			if (addressTokenOwner.send(amountRaisedInEthers)) {
				emit FundTransfer(addressTokenOwner, amountRaisedInEthers, false);
			} else {
				//If we fail to send the funds to addressTokenOwner, unlock funders balance
				fundingGoalReached = false;
			}
		}
	}
	*/
}
