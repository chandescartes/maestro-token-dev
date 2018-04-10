pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
//import 'zeppelin-solidity/contracts/token/ERC20/PausableToken.sol';

/**
 * The main contract for Maestro token
 */
contract MaestroToken is BurnableToken, MintableToken {

	string public constant standard = "ERC20"; // not required, but recommended
	string public constant name = "Maestro Token";
  string public constant symbol = "MAE";
  uint8 public constant decimals = 18;		// 10**decimals will be applied for minimum divisible unit of token
	uint256 public constant initialSupplyNumTokens = 1000000;

	uint256 public INITIAL_SUPPLY;
	uint public lockupDuration = 1 years; // duration for company lock-up
  uint public companyLockReleaseDate; 

	mapping(address => uint256) lockedTokens;		// keeps number of locked-up tokens of each address

	/**
	 * Constructor
	 */
	function MaestroToken() public {
		INITIAL_SUPPLY = initialSupplyNumTokens * (10 ** uint256(decimals));

		balances[msg.sender] = INITIAL_SUPPLY;  // Give the creator all initial tokens

		// Current total supply of tokens
		// Can be increased by mint() or decreased by burn()
		totalSupply_ = INITIAL_SUPPLY; // in BasicToken.sol

		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);

		// specify release date of lock-up
		companyLockReleaseDate = now + lockupDuration;
	}

	/**
	 * Overrides BasicToken.transfer()
	 */
	function transfer(address _to, uint256 _value) public returns (bool) {
		// Check if locked up
		if (companyLockReleaseDate > now)
			require(balances[msg.sender].sub(_value) >= lockedTokens[msg.sender]);

		return super.transfer(_to, _value);
	}

	/**
	 * Overrides StandardToken.transferFrom()
	 */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		// Check if locked up
		if (companyLockReleaseDate > now)
			require(balances[_from].sub(_value) >= lockedTokens[_from]);

		return super.transferFrom(_from, _to, _value);
	}


	/**
	 * Enables admin to transfer for batch
	 * Used by contract creator to distribute initial tokens to holders with lockup
	 */
	function adminBatchTransferWithLockup(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
		require(_recipients.length > 0 && _recipients.length == _values.length);

		uint total = 0;
		for (uint i = 0; i < _values.length; i++) {
			total = total.add(_values[i]);
		}
		require(total <= balances[msg.sender]);

		for(uint j = 0; j < _recipients.length; j++) {
			// Update balance
			balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
			// Notify
			emit Transfer(msg.sender, _recipients[j], _values[j]);

			// Save in locked tokens
			lockedTokens[_recipients[j]] = _values[j];
		}

		balances[msg.sender] = balances[msg.sender].sub(total);

		return true;
	}
}

