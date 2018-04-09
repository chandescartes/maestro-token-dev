pragma solidity ^0.4.16;

/**
 * SafeMath
 *
 * Safe math operations in lieu of +,-,*,/  that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * AdminOwnable
 *
 * The AdminOwnable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract AdminOwnable {
    address public admin;

		//
		// Constructor
		// Sets the original `owner` of the contract to the sender account
		//
    function AdminOwnable() public {
        admin = msg.sender;
    }

		//
		// Modifier
    // Throws if called by any account other than the owner.
		//
    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }


		//
		// Allows the current admin to transfer control of the contract to a newOwner.
    // @param newOwner The address to transfer ownership to.
    // 
    function transferAdmin(address newAdmin) adminOnly public {
        require(newAdmin != address(0));
        admin = newAdmin;
    }
}

/**
 * ERC Token Standard #20 Interface
 * Exerpted from https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 * See more at https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Standard {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
 * PoSTokenCustomStandard
 *
 * The interface of PoSTokenCustomStandard
 */
contract PoSTokenCustomStandard {
	uint256 public posStartTime;
	uint256 public posMinAge;
	uint256 public posMaxAge;
	function mint() public returns (bool);
	function getPoSWeight() constant public returns (uint256);

	event Mint(address indexed _address, uint _reward);
}

/**
 * Interface for approveAndCall()
 */
interface tokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


/**
 * The main contract for Maestro token
 */
contract MaestroToken is ERC20Standard, PoSTokenCustomStandard, AdminOwnable {
	using SafeMath for uint256;

	//////////////////////////////////
	// Inputs to decide
	// TODO: Specify with correct values
	string constant public tokenName = "Maestro Coin";		// e.g. "Maestro Token"
	string constant public tokenSymbol = "MAT";	// e.g. "MST"
	uint public lockupDuration = 1 years; // e.g. 1 years
	uint256 public initialSupplyDividedByMil = 100;	// e.g. 100 = 100,000,000 tokens
	/////////////////////////////////////

	string constant public standard = "ERC20"; // not required, but recommended
	string public name;				// e.g. "Maestro Token"
  string public symbol;			// e.g. "MST"
  uint8 public decimals;		// 10**decimals will be applied for minimum divisible unit of token
  uint public tokensSupplied;		// Total tokens supplied so far
  uint public maxTokensToSupply;	// Max number of tokens in lifetime

  uint public startBlockTime; 		// Saves creation time of the first block
  uint public startBlockNumber; 	// Saves the number ofr the first block 
  uint public maxMintProofOfStake;

  uint public companyLockReleaseDate; // Lockup dudration for creators

	struct transferInStruct{
		uint128 amount;		// amount of tokens
		uint64 time;			// time stamp
	}

	mapping(address => uint256) balances;		// keeps balance of each address
	mapping(address => mapping (address => uint256)) allowed;	// keeps allowance of each address
	mapping(address => uint256) lockedTokens;		// keeps number of locked-up tokens of each address
	mapping(address => transferInStruct[]) transferInHistory;	// Keeps track of transfer-ins for PoS calculation

	// Triggered upon burning existing tokens
	event Burn(address indexed burner, uint256 value);

    /**
     * Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canMint() {
        require(tokensSupplied < maxTokensToSupply);
        _;
    }

		/**
		 * Constructor
		 */
    function MaestroToken(
			/* Contructor inputs now go static
			string tokenName,		// e.g. "Maestro Token"
			string tokenSymbol,	// e.g. "MST"
			uint lockupDuration, 		// e.g. 1 years
			uint256 initialSupplyDividedByMil,	// e.g. 100 = 100,000,000 tokens
			*/
		) public {


    	decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    	name = tokenName; 
			symbol = tokenSymbol; 
			tokensSupplied = (initialSupplyDividedByMil * 10**6) * 10 ** uint256(decimals);  // Update total supply with the decimal amount
			balances[msg.sender] = tokensSupplied;  // Give the creator all initial tokens

			maxTokensToSupply = tokensSupplied*10**5; // TODO?

  		companyLockReleaseDate = now + lockupDuration;
			startBlockTime = now;
			startBlockNumber = block.number;

			posStartTime = 0;	// initialize
			posMinAge = 3 days; // minimum age for coin age
			posMaxAge = 90 days; // stake age of full weight
  		maxMintProofOfStake = (10**decimals) / 10; // default 10% annual interest
		}

    /**
     * Transfer tokens (ERC20-compliant)
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
			return _transfer(msg.sender, _to, _value);
    }

    /**
		 * ERC20-compliant
		 */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
			// Check allowances
			require(_value <= allowed[_from][msg.sender]);
			allowed[_from][msg.sender] -= _value;

			return _transfer(_from, _to, _value);
		}

    /**
     * Internal transfer that only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) onlyPayloadSize(2*32) internal returns (bool){
			// Prevent transfer to 0x0 address. Use burn() instead
			require(_to != 0x0);

			if (msg.sender == _to) {
				// If sender transfers to himself, try mint
				return mint();
			}

			// Check if locked up
			if (companyLockReleaseDate > now)
				require(balances[_from].sub(_value) >= lockedTokens[_from]);

			// Check if the sender has enough
			require(balances[_from] >= _value);
			// Check for overflows
			require(balances[_to] + _value > balances[_to]);
			// Save this for an assertion in the future
			uint previousBalances = balances[_from] + balances[_to];
			// Subtract from the sender
			balances[_from] -= _value;
			// Add the same to the recipient
			balances[_to] += _value;

			// ERC20-compliant
			emit Transfer(_from, _to, _value);

			// Asserts are used to use static analysis to find bugs in your code. They should never fail
			assert(balances[_from] + balances[_to] == previousBalances);

			//
			// Update transfer-in history
			//
			if(transferInHistory[_from].length > 0)
				delete transferInHistory[_from];
			uint64 _now = uint64(now);
			transferInHistory[_from].push(transferInStruct(uint128(balances[_from]),_now));
			transferInHistory[_to].push(transferInStruct(uint128(_value),_now));

			return true;
    }


    /**
		 * ERC20-compliant
		 */
    function balanceOf(address _owner) constant public returns (uint256 balance) {
			return balances[_owner];
    }

    /**
		 * ERC20-compliant
		 */
		function totalSupply() public constant returns (uint) {
			return tokensSupplied;
    }

		/**
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
			require(_to != address(0));

			// Check if locked up
			if (companyLockReleaseDate > now)
				require(balances[_from].sub(_value) >= lockedTokens[_from]);

			// Get allowance
			var _allowance = allowed[_from][msg.sender];

			// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
			// require (_value <= _allowance);

			balances[_from] = balances[_from].sub(_value);
			balances[_to] = balances[_to].add(_value);
			allowed[_from][msg.sender] = _allowance.sub(_value);

			emit Transfer(_from, _to, _value);

			//
			// Update transfer-in history
			//
			if(transferInHistory[_from].length > 0)
				delete transferInHistory[_from];
			uint64 _now = uint64(now);
			transferInHistory[_from].push(transferInStruct(uint128(balances[_from]),_now));
			transferInHistory[_to].push(transferInStruct(uint128(_value),_now));
			return true;
    }
		*/

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
			require((_value == 0) || (allowed[msg.sender][_spender] == 0));

			// Check if locked up
			if (companyLockReleaseDate > now)
				require(balances[_spender].sub(_value) >= lockedTokens[_spender]);

			allowed[msg.sender][_spender] = _value;
			emit Approval(msg.sender, _spender, _value);
			return true;
    }

    /**
		 * ERC20-compliant
		 */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
			return allowed[_owner][_spender];
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


		/**
		 * PoSTokenCustomStandard
		 */
    function mint() canMint public returns (bool) {
			// Allow minting only when the sender has balance and transfer-in record
			if (balances[msg.sender] <= 0) 
				return false;
			if(transferInHistory[msg.sender].length <= 0)
				return false;

			uint reward = getProofOfStakeReward(msg.sender);
			if(reward <= 0)
				return false;

			// Increment # tokens supplied
			tokensSupplied = tokensSupplied.add(reward);
			// Add to the balance
			balances[msg.sender] = balances[msg.sender].add(reward);
			// Update transfer-in history
			delete transferInHistory[msg.sender];
			transferInHistory[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

			// Notify
			emit Mint(msg.sender, reward);

			return true;
    }

		/**
		 * Public function that returns number of blocks since the beginning
		 */
    function getBlockNumber() public view returns (uint blockNumber) {
			blockNumber = block.number.sub(startBlockNumber);
    }

		/**
		 * Public function that returns number of blocks since the beginning
		 */
    function getPoSWeight() constant public returns (uint age) {
			age = _getPoSWeight(msg.sender, now);
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
			require((now >= posStartTime) && (posStartTime > 0) );

			uint _now = now;
			uint weight = _getPoSWeight(_address, _now);
			if(weight <= 0) 
				return 0;

			//
			// Calculate interest
			//
			uint interest;
			// Due to the high interest rate for the first two years, compounding should be taken into account.
			// Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
			if((_now.sub(posStartTime)).div(1 years) == 0) {
				// 1st year effective annual interest rate is 100% when we select the posMaxAge (90 days) as the compounding period.
				interest = (770 * maxMintProofOfStake).div(100);
			} else if((_now.sub(posStartTime)).div(1 years) == 1){
				// 2nd year effective annual interest rate is 50%
				interest = (435 * maxMintProofOfStake).div(100);
			} else {
				interest = maxMintProofOfStake;
			}

			return (weight * interest).div(365 * (10**decimals));
    }


    function _getPoSWeight(address _address, uint _now) internal view returns (uint _weight) {
			if (transferInHistory[_address].length <= 0) 
				return 0;

			for (uint i = 0; i < transferInHistory[_address].length; i++){
				if (_now < uint(transferInHistory[_address][i].time).add(posMinAge)) 
					continue;

				uint coinSeconds = _now.sub(uint(transferInHistory[_address][i].time));
				if (coinSeconds > posMaxAge)
					coinSeconds = posMaxAge;
				_weight = _weight.add(uint(transferInHistory[_address][i].amount) * coinSeconds.div(1 days));
			}
		}

		/**
		 * Enables admin to set posStartTime
		 */
    function adminSetPosStartTime(uint timestamp) adminOnly public {
			require((posStartTime <= 0) && (timestamp >= startBlockTime));
			posStartTime = timestamp;
    }


		/**
		 * Enables admin to burn tokens
		 */
    function adminBurnToken(uint _value) adminOnly public {
			require(_value > 0);

			balances[msg.sender] = balances[msg.sender].sub(_value);
			delete transferInHistory[msg.sender];
			transferInHistory[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

			tokensSupplied = tokensSupplied.sub(_value);
			//totalInitialSupply = totalInitialSupply.sub(_value);
			//maxTokensToSupply = maxTokensToSupply.sub(_value*10);

			emit Burn(msg.sender, _value);
    }

		/**
		 * Enables admin to transfer for batch
     * Used by contract creator to distribute initial tokens to holders with lockup
		 */
    function adminBatchTransferWithLockup(address[] _recipients, uint[] _values) adminOnly public returns (bool) {
			require(_recipients.length > 0 && _recipients.length == _values.length);

			uint total = 0;
			for (uint i = 0; i < _values.length; i++) {
				total = total.add(_values[i]);
			}
			require(total <= balances[msg.sender]);

			uint64 _now = uint64(now);
			for(uint j = 0; j < _recipients.length; j++) {
				// Update balance
				balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
				transferInHistory[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
				emit Transfer(msg.sender, _recipients[j], _values[j]);

				// Do lockup for 1 year
				lockedTokens[_recipients[j]] = _values[j];
			}

			balances[msg.sender] = balances[msg.sender].sub(total);

			/*
			// Update transferInHistory ??
			if (transferInHistory[msg.sender].length > 0)
				delete transferInHistory[msg.sender];
			if (balances[msg.sender] > 0)
				transferInHistory[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
				*/

			return true;
    }

		/*
    function annualInterest() constant returns(uint interest) {
			uint _now = now;
			if (posStartTime == 0) {
				// Invalid - PoS is not running
				interest = 0;
			} else if((_now.sub(posStartTime)).div(1 years) == 0) {
				interest = (770 * maxMintProofOfStake).div(100);
			} else if((_now.sub(posStartTime)).div(1 years) == 1){
				interest = (435 * maxMintProofOfStake).div(100);
			} else {
				interest = maxMintProofOfStake;
			}
    }
		*/
}
