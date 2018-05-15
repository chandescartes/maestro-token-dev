pragma solidity ^0.4.21;

import "./MaestroToken.sol";


/**
 * Maestro Crowdsale
 */
contract MaestroCrowdsale {
    using SafeMath for uint256;

    /*************************/
    /*                       */
    /*        Ownable        */
    /*                       */
    /*************************/

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /*************************/
    /*                       */
    /*       Crowdsale       */
    /*                       */
    /*************************/

    address public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /*************************/
    /*                       */
    /*     TimedCrowdsale    */
    /*                       */
    /*************************/

    uint256 public openingTime;
    uint256 public closingTime;

    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    /**************************/
    /*                        */
    /*  FinalizableCrowdsale  */
    /*                        */
    /**************************/

    bool public isFinalized = false;

    event Finalized();

    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasClosed());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /*************************/
    /*                       */
    /*    CappedCrowdsale    */
    /*                       */
    /*************************/

    uint256 public cap;

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    /**
     * Constructor
     * Variables from inherited contracts
     * {rate, wallet, token} from Crowdsale.sol
     * {cap} from CappedCrowdsale.sol
     * {openingTime, closingTime} from TimedCrowdsale.sol
     */
    function MaestroCrowdsale(
        uint256 _openingTime,           // Opening time in timestamp
        uint256 _closingTime,           // Closing time in timestamp
        uint256 _rate,                  // How many token units a buyer gets per wei
        address _wallet,                // Address where funds are collected
        uint256 _cap,                   // Max amount of wei to be contributed
        address _token                    // The token being sold
    )
        public
    {
        /* Ownable */
        owner = msg.sender;

        /* Crowdsale */
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;

        /* TimedCrowdsale */
        require(_openingTime >= now);
        require(_closingTime >= _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;

        /* CappedCrowdsale */
        require(_cap > 0);

        cap = _cap;
    }

    /**
     * Override parent contracts to combine implementation of CappedCrowdsale and TimedCrowdsale
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= cap);
    }

    /**
     * Override parent contracts
     * Unlike parent contracts, it does NOT call internal {_deliverTokens} function
     * {_tokenAmount} does not include bonus
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(MaestroToken(token).buyTokensFromCrowdsale(_beneficiary, _tokenAmount));
    }

    /**
     * Override from FinalizableCrowdsale to include burning of remaining tokens
     */
    function finalization() internal {
        require(MaestroToken(token).burnRemainingTokensFromCrowdsale());
    }

    /**
     * Called by token contract for validation
     */
    function returnTrue() public pure returns (bool) {
        return true;
    }
}
