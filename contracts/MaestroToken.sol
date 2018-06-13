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
    uint256 public totalTeamSupply;
    uint256 public cumulativeTeamSupply = 0;
    // {uint256 totalSupply_} is also a global variable called by totalSupply()

    /* Bonus rates */
    uint public constant BONUS_S1 = 30;
    uint public constant BONUS_S2 = 10;
    uint public constant BONUS_S3 = 0;
    uint public constant TEAM_PERCENT = 22;

    /* Crowdsale addresses and flags */
    address public crowdsaleS1Address;
    address public crowdsaleS2Address;
    address public crowdsaleS3Address;
    bool public crowdsaleS1Flag = false;
    bool public crowdsaleS2Flag = false;
    bool public crowdsaleS3Flag = false;

    /* Lockup durations and release dates */
    uint public lockupDurationS1;   // Unit is days
    uint public lockupDurationS2;   // Unit is days
    uint public lockupDurationTeam; // Unit is days
    uint public releaseDateS1 = 0;
    uint public releaseDateS2 = 0;
    uint public releaseDateTeam = 0;

    /* Mapping to keep track of lockup of each address */
    mapping(address => uint256) internal lockupS1;
    mapping(address => uint256) internal lockupS2;
    mapping(address => uint256) internal lockupTeam;

    /* Events */
    event Lock(address indexed _tokenHolder, uint256 _value);

    /**
     * Disallows transferring locked tokens
     */
    modifier checkLockup(address _from, uint256 _value) {
        uint256 totalLockup = 0;

        if (now < releaseDateS1) {
            totalLockup = totalLockup.add(lockupS1[_from]);
        } 
        if (now < releaseDateS2) {
            totalLockup = totalLockup.add(lockupS2[_from]);
        } 
        if (now < releaseDateTeam) {
            totalLockup = totalLockup.add(lockupTeam[_from]);
        }

        require(_value.add(totalLockup) <= balances[_from]);
        _;
    }

    /**
     * Constructor
     * Note that {_initialSupplyWithoutDecimals} is amount before multiplying by {10 ** decimals}
     * For example, if {_initialSupplyWithoutDecimals == 999} then {initialSupply == 999 * (10 ** decimals)}
     * This is so that we make sure the initial supply is divisible by {10 ** decimals}
     * Unit of lockup duration variables is days
     */
    function MaestroToken(
        uint256 _initialSupplyWithoutDecimals,
        uint _lockupDurationS1,
        uint _lockupDurationS2,
        uint _lockupDurationTeam
    ) 
        public 
    {
        initialSupply = _initialSupplyWithoutDecimals.mul(10 ** uint256(decimals));
        totalTeamSupply = initialSupply.div(100).mul(TEAM_PERCENT);

        lockupDurationS1 = (_lockupDurationS1 * 1 days);
        lockupDurationS2 = (_lockupDurationS2 * 1 days);
        lockupDurationTeam = (_lockupDurationTeam * 1 days);

        releaseDateTeam = now + lockupDurationTeam;

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
     * Return S1 lockup of {_owner} - can only be called by owner
     */
    function getLockupS1(address _owner) public view returns (uint256) {
        return lockupS1[_owner];
    }

    /**
     * Return S2 lockup of {_owner} - can only be called by owner
     */
    function getLockupS2(address _owner) public view returns (uint256) {
        return lockupS2[_owner];
    }

    /**
     * Return S2 lockup of {_owner} - can only be called by owner
     */
    function getLockupTeam(address _owner) public view returns (uint256) {
        return lockupTeam[_owner];
    }

    /**
     * Set address of CrowdsaleS1
     */
    function setCrowdsaleS1(address _address) public onlyOwner {
        require(_address != address(0));
        require(!crowdsaleS1Flag);

        crowdsaleS1Address = _address;
        releaseDateS1 = MaestroCrowdsale(_address).closingTime() + lockupDurationS1;

        uint256 cap = MaestroCrowdsale(_address).cap();
        uint256 rate = MaestroCrowdsale(_address).rate();
        uint256 tokenAmount = cap.mul(rate).div(100).mul(BONUS_S1 + 100);
        transfer(crowdsaleS1Address, tokenAmount);

        require(MaestroCrowdsale(_address).returnTrue());
        crowdsaleS1Flag = true;
    }

    /**
     * Set address of CrowdsaleS2
     */
    function setCrowdsaleS2(address _address) public onlyOwner {
        require(_address != address(0));
        require(!crowdsaleS2Flag);

        crowdsaleS2Address = _address;
        releaseDateS2 = MaestroCrowdsale(_address).closingTime() + lockupDurationS2;

        uint256 cap = MaestroCrowdsale(_address).cap();
        uint256 rate = MaestroCrowdsale(_address).rate();
        uint256 tokenAmount = cap.mul(rate).div(100).mul(BONUS_S2 + 100);
        transfer(crowdsaleS2Address, tokenAmount);

        require(MaestroCrowdsale(_address).returnTrue());
        crowdsaleS2Flag = true;
    }

    /**
     * Set address of CrowdsaleS3
     */
    function setCrowdsaleS3(address _address) public onlyOwner {
        require(_address != address(0));
        require(!crowdsaleS3Flag);

        crowdsaleS3Address = _address;

        uint256 cap = MaestroCrowdsale(_address).cap();
        uint256 rate = MaestroCrowdsale(_address).rate();
        uint256 tokenAmount = cap.mul(rate);
        transfer(crowdsaleS3Address, tokenAmount);

        require(MaestroCrowdsale(_address).returnTrue());
        crowdsaleS3Flag = true;
    }

    /**
     * Get crowdsale number, return 0 otherwise
     */
    function getCrowdsaleNumber(address _sender) internal view returns (uint) {
        if (_sender == address(0))
            return 0;

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
     * Total lockup cannot be more than balance
     */
    function lockTokens(address _tokenHolder, uint256 _value, uint _crowdsaleNumber) internal checkLockup(_tokenHolder, _value) {
        if (_crowdsaleNumber == 1) {
            lockupS1[_tokenHolder] = lockupS1[_tokenHolder].add(_value);
            emit Lock(_tokenHolder, _value);
        } else if (_crowdsaleNumber == 2) {
            lockupS2[_tokenHolder] = lockupS2[_tokenHolder].add(_value);
            emit Lock(_tokenHolder, _value);
        } else if (_crowdsaleNumber == 3) {
            return;
        } else {
            assert(false);
        }
    }


    /** 
     * Transfers and locks up an amount
     * Used to lockup team reserve by owner
     */
    function transferToTeam(address _beneficiary, uint256 _amount) public onlyOwner returns (bool) {
        require(cumulativeTeamSupply.add(_amount) <= totalTeamSupply);
        cumulativeTeamSupply = cumulativeTeamSupply.add(_amount);

        transfer(_beneficiary, _amount);

        // From Solhint: Possible reentrancy vulnerabilities. Avoid state changes after transfer
        lockupTeam[_beneficiary] = lockupTeam[_beneficiary].add(_amount);
        emit Lock(_beneficiary, _amount);

        return true;
    }

    /**
     * Transfers an amount with bonus and locks up the bonus
     * Called only from the CrowdsaleS1 contract
     */
    function buyTokensFromCrowdsale(address _beneficiary, uint256 _amount) public returns (bool) {
        uint crowdsaleNumber = getCrowdsaleNumber(msg.sender);
        require(crowdsaleNumber != 0 && crowdsaleNumber < 4);

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
        require(crowdsaleNumber != 0 && crowdsaleNumber < 4);

        uint256 balance = balances[msg.sender];
        burn(balance);

        return true;
    }
}
