pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
// import "zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
// import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
// import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./MaestroToken.sol";


/**
 * Maestro Crowdsale Season #1
 * For this contract to work, balance of its address in MaestroToken must be set
 */
contract MaestroCrowdsale is Crowdsale, CappedCrowdsale, FinalizableCrowdsale {

    uint8 constant public decimals = 18;

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
        ERC20 _token                    // The token being sold
    )
        public
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        // TODO: Should there really be nothing here
    }

    /**
     * Override parent contracts to combine implementation of CappedCrowdsale and TimedCrowdsale
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        Crowdsale._preValidatePurchase(_beneficiary, _weiAmount);
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
        // TODO
    }
}
