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
     * Constructor
     * Second parameter's unit is in seconds for testing convenience
     * TODO: change this parameter to a more appropriate one (months or years)
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
     * Increase amount of locked tokens of {_tokenHolder} by {_value}
     * TODO: How do we restrict this function properly? Is {onlyOwner} correct?
     */
    function lockTokens(address _tokenHolder, uint256 _value) public onlyOwner {
        require(lockedTokens[_tokenHolder].add(_value) <= balances[_tokenHolder]);

        lockedTokens[_tokenHolder] = lockedTokens[_tokenHolder].add(_value);
        emit Lock(_tokenHolder, _value);
    }

    /**
     * Enables admin to transfer for batch
     * Used by contract creator to distribute initial tokens to holders with lockup
     * TODO: Check whether any address is not equal to {address(0)}
     * TODO: Change parameters to {mapping(address => uint256)}
     */
    function adminBatchTransferWithLockup(address[] _recipients, uint[] _values) public onlyOwner returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        // Check balance of sender is less than sum of values
        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        // Subtract first? (reentrancy attack)
        balances[msg.sender] = balances[msg.sender].sub(total);

        // Transfer to each {_recipient}
        for (uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            emit Transfer(msg.sender, _recipients[j], _values[j]);

            lockTokens(_recipients[j], _values[j]);
        }

        return true;
    }
}
