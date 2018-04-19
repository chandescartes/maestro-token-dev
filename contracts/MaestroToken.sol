pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


/**
 * The main contract for Maestro token
 */
contract MaestroToken is BurnableToken, MintableToken {

    string public constant standard = "ERC20"; // Not required, but recommended
    string public constant name     = "Maestro Token";
    string public constant symbol   = "MAE";
    uint8 public constant decimals  = 18;      // {10 ** decimals} will be applied for minimum divisible unit of token

    uint256 public initialSupplyInTokens;   // Do not use this variable, use {initialSupply}
    uint256 public initialSupply;           // {initialSupply = initialSupplyInTokens * 10 ** decimals}
    uint public lockupDuration;             // Duration for company lock-up
    uint public companyLockReleaseDate;

    mapping(address => uint256) public lockedTokens;   // Keeps number of locked-up tokens of each address

    address private crowdsaleS1Address;     // Address of S1 Crowdsale contract;

    event Lock(address _tokenHolder, uint256 _value);

    /**
     * Disallows transferring locked tokens
     */
    modifier checkLockup(address _from, uint256 _value) {
        if (companyLockReleaseDate > now)
            require(balances[_from].sub(_value) >= lockedTokens[_from]);
        _;
    }

    /**
     * For calling methods only from the CrowdsaleS1 contract
     */
    modifier onlyCrowdsaleS1() {
        require(msg.sender == crowdsaleS1Address);
        _;
    }

    /**
     * Constructor
     * Second parameter's unit is in seconds for testing convenience
     * TODO: Change this parameter to a more appropriate one (months or years)
     * TODO: Does this initialize its parent's contructors,
     *       or should we call it explicitly like in CrowdsaleS1?
     */
    function MaestroToken(uint256 _initialSupplyInTokens, uint _lockupDurationInSeconds) public {
        initialSupplyInTokens = _initialSupplyInTokens;
        initialSupply = initialSupplyInTokens.mul(10 ** uint256(decimals));

        balances[msg.sender] = initialSupply;  // Give the creator all initial tokens

        // In BasicToken.sol
        // Current total supply of tokens, can be increased by mint() or decreased by burn()
        totalSupply_ = initialSupply;

        emit Transfer(address(0), msg.sender, initialSupply);

        // specify release date of lock-up
        companyLockReleaseDate = now + _lockupDurationInSeconds; // NOTE: unit of {now} is seconds
    }

    /**
     * Overrides BasicToken.transfer()
     */
    function transfer(address _to, uint256 _value) public checkLockup(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Overrides StandardToken.transferFrom()
     */
    function transferFrom(address _from, address _to, uint256 _value) public checkLockup(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * Set address of CrowdsaleS1
     */
    function setCrowdsaleS1Address(address _crowdsaleS1Address) public onlyOwner {
        crowdsaleS1Address = _crowdsaleS1Address;
    }

    /**
     * Increase amount of locked tokens of {_tokenHolder} by {_value}
     */
    function lockTokens(address _tokenHolder, uint256 _value) internal {
        require(lockedTokens[_tokenHolder].add(_value) <= balances[_tokenHolder]);

        lockedTokens[_tokenHolder] = lockedTokens[_tokenHolder].add(_value);
        emit Lock(_tokenHolder, _value);
    }

    /**
     * Transfers an amount with bonus and locks up the bonus
     * Called only from the CrowdsaleS1 contract
     */
    function processPurchaseWithBonus(
        address _beneficiary, 
        uint256 _amountWithBonus, 
        uint256 _bonusAmount
    ) 
        public 
        onlyCrowdsaleS1
        returns (bool) 
    {
        require(_amountWithBonus >= _bonusAmount); // Bonus cannot be more than the amount with bonus included

        transfer(_beneficiary, _amountWithBonus);
        lockTokens(_beneficiary, _bonusAmount);

        return true;
    }

    /**
     * Enables admin to transfer for batch
     * Used by contract creator to distribute initial tokens to holders with lockup
     * TODO: Check whether any address is not equal to {address(0)}
     * TODO: Change parameters to {mapping(address => uint256)}
     */
    function adminBatchTransferWithLockup(address[] _recipients, uint[] _values) public onlyCrowdsaleS1 returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        // Check balance of sender is less than sum of values
        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        // Transfer to each {_recipient}
        for (uint j = 0; j < _recipients.length; j++) {
            transfer(_recipients[j], _values[j]);
            lockTokens(_recipients[j], _values[j]);
        }

        return true;
    }
}
