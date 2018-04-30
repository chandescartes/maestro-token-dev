pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./MaestroCrowdsale.sol";

/**
 * The main contract for Maestro token
 */
contract MaestroToken is BurnableToken, MintableToken {

    string public constant standard = "ERC20";
    string public constant name     = "Maestro Token";
    string public constant symbol   = "MAE";
    uint8 public constant decimals  = 18;

    uint256 public initialSupply;
    // {uint256 totalSupply_} is also a global variable

    /* Bonus rates */
    uint public constant BONUS_S1 = 30;
    uint public constant BONUS_S2 = 10;
    uint public constant BONUS_S3 = 0;

    /* Crowdsale addresses */
    address internal crowdsaleS1Address;
    address internal crowdsaleS2Address;
    address internal crowdsaleS3Address;

    /* Lockup durations and release dates */
    uint public constant LOCKUP_DURATION_S1 = 1 years;
    uint public constant LOCKUP_DURATION_S2 = 1 years;
    uint public releaseDateS1;
    uint public releaseDateS2;

    mapping(address => uint256) internal lockupS1;
    mapping(address => uint256) internal lockupS2;

    /* Events */
    event Lock(address indexed _tokenHolder, uint256 _value, uint _crowdsaleNumber);

    /**
     * Disallows transferring locked tokens
     * TODO: add S2 logic
     */
    modifier checkLockup(address _from, uint256 _value) {
        if (now < releaseDateS1)
            require(_value.add(lockupS1[_from]).add(lockupS2[_from]) <= balances[_from]);

        else if (now < releaseDateS2)
            require(_value.add(lockupS2[_from]) <= balances[_from]);

        _;
    }

    /**
     * Constructor
     * Note that {_initialSupplyWithoutDecimals} is amount before multiplying by {10 ** decimals}
     * For example, if {_initialSupplyWithoutDecimals == 999} then {initialSupply == 999 * (10 ** decimals)}
     * This is so that we make sure the initial supply is divisible by {10 ** decimals}
     */
    function MaestroToken(uint256 _initialSupplyWithoutDecimals) public {
        initialSupply = _initialSupplyWithoutDecimals.mul(10 ** uint256(decimals));

        // In BasicToken.sol
        // Current total supply of tokens, can be increased by mint() or decreased by burn()
        totalSupply_ = initialSupply;

        balances[msg.sender] = initialSupply;  // Give the creator all initial tokens
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    /*************************/
    /*                       */
    /*  Overriden Functions  */
    /*                       */
    /*************************/

    /**
     * Override BasicToken.transfer()
     */
    function transfer(address _to, uint256 _value) public checkLockup(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Override StandardToken.transferFrom()
     */
    function transferFrom(address _from, address _to, uint256 _value) public checkLockup(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /*************************/
    /*                       */
    /*    Other Functions    */
    /*                       */
    /*************************/

    /**
     * Return S1 lockup of sender
     */
    function getLockupS1() public view returns (uint256) {
        return lockupS1[msg.sender];
    }

    /**
     * Return S1 lockup of {_owner} - can only be called by owner
     */
    function getLockupS1OnlyOwner(address _owner) public view onlyOwner returns (uint256) {
        return lockupS1[_owner];
    }

    /**
     * Return S2 lockup of sender
     */
    function getLockupS2() public view returns (uint256) {
        return lockupS2[msg.sender];
    }

    /**
     * Return S2 lockup of {_owner} - can only be called by owner
     */
    function getLockupS2OnlyOwner(address _owner) public view onlyOwner returns (uint256) {
        return lockupS2[_owner];
    }

    /**
     * Return address of CrowdsaleS1 - can only be called by owner
     */
    function getCrowdsaleS1Address() public view onlyOwner returns (address) {
        return crowdsaleS1Address;
    }

    /**
     * Return address of CrowdsaleS2 - can only be called by owner
     */
    function getCrowdsaleS2Address() public view onlyOwner returns (address) {
        return crowdsaleS2Address;
    }

    /**
     * Return address of CrowdsaleS3 - can only be called by owner
     */
    function getCrowdsaleS3Address() public view onlyOwner returns (address) {
        return crowdsaleS3Address;
    }

    // TODO: What happens when we input wrong address and need to revert?
    /**
     * Set address of CrowdsaleS1
     */
    function setCrowdsaleS1(address _address, uint256 _amount) public onlyOwner {
        require(_address != address(0));

        crowdsaleS1Address = _address;
        releaseDateS1 = MaestroCrowdsale(_address).openingTime() + LOCKUP_DURATION_S1;
        transfer(crowdsaleS1Address, _amount);
    }

    /**
     * Set address of CrowdsaleS2
     */
    function setCrowdsaleS2(address _address, uint256 _amount) public onlyOwner {
        require(_address != address(0));

        crowdsaleS2Address = _address;
        releaseDateS2 = MaestroCrowdsale(_address).openingTime() + LOCKUP_DURATION_S2;
        transfer(crowdsaleS2Address, _amount);
    }

    /**
     * Set address of CrowdsaleS3
     */
    function setCrowdsaleS3(address _address, uint256 _amount) public onlyOwner {
        require(_address != address(0));

        crowdsaleS3Address = _address;
        transfer(crowdsaleS3Address, _amount);
    }

    /**
     * Get crowdsale number, return 0 otherwise
     */
    function getCrowdsaleNumber(address _sender) internal view returns (uint) {
        if (_sender == crowdsaleS1Address)
            return 1;

        if (_sender == crowdsaleS2Address)
            return 2;

        if (_sender == crowdsaleS3Address)
            return 3;

        return 0;
    }

    /**
     * Calculates bonus according to season
     * Crowdsale number must be 1, 2, or 3
     */
    function calculateBonus(uint256 _amount, uint _crowdsaleNumber) internal pure returns (uint256) {
        if (_crowdsaleNumber == 1)
            return _amount.div(100).mul(BONUS_S1);

        if (_crowdsaleNumber == 2)
            return _amount.div(100).mul(BONUS_S2);

        if (_crowdsaleNumber == 3)
            return 0;

        assert(false);
    }

    /**
     * Increase amount of locked tokens of {_tokenHolder} by {_value}
     * Crowdsale number must be 1, 2, or 3
     */
    function lockTokens(address _tokenHolder, uint256 _value, uint _crowdsaleNumber) internal {
        if (_crowdsaleNumber == 1) {
            // Lockup amount cannot be more than balance (lockupS2 doesn't necessarily have to be checked)
            require(lockupS1[_tokenHolder].add(lockupS2[_tokenHolder]).add(_value) <= balances[_tokenHolder]);

            // Add lock up and emit event
            lockupS1[_tokenHolder] = lockupS1[_tokenHolder].add(_value);
            emit Lock(_tokenHolder, _value, _crowdsaleNumber);
        }

        else if (_crowdsaleNumber == 2) {
            // Lockup amount cannot be more than balance
            require(lockupS1[_tokenHolder].add(lockupS2[_tokenHolder]).add(_value) <= balances[_tokenHolder]);

            // Add lockup and emit event
            lockupS2[_tokenHolder] = lockupS2[_tokenHolder].add(_value);
            emit Lock(_tokenHolder, _value, _crowdsaleNumber);
        }

        else if (_crowdsaleNumber == 3) {
            return;
        }
        else {
            assert(false);
        }
    }

    /**
     * Transfers an amount with bonus and locks up the bonus
     * Called only from the CrowdsaleS1 contract
     */
    function buyTokensFromCrowdsale(address _beneficiary, uint256 _amount) public returns (bool) {
        uint crowdsaleNumber = getCrowdsaleNumber(msg.sender);
        require(crowdsaleNumber != 0);

        uint256 bonus = calculateBonus(_amount, crowdsaleNumber);
        uint256 amountWithBonus = _amount.add(bonus);

        transfer(_beneficiary, amountWithBonus);
        lockTokens(_beneficiary, bonus, crowdsaleNumber);

        return true;
    }

    /**
     * Burns remaining balance that crowdsale has
     * Called when crowdsale ends
     */
    function burnRemainingTokensFromCrowdsale() public returns (bool) {
        uint crowdsaleNumber = getCrowdsaleNumber(msg.sender);
        require(crowdsaleNumber != 0);

        uint256 balance = balances[msg.sender];
        burn(balance);

        return true;
    }
}
