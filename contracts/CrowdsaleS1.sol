pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./MaestroToken.sol";


/**
 * Maestro Crowdsale Season #1
 * For this contract to work, balance of its address in MaestroToken must be set
 */
contract CrowdsaleS1 is Crowdsale, CappedCrowdsale, TimedCrowdsale {

    uint8 constant public decimals = 18;

    /**
     * Constructor
     * Variables from inherited contracts
     * {rate, wallet, token} from Crowdsale.sol
     * {cap} from CappedCrowdsale.sol
     * {openingTime, closingTime} from TimedCrowdsale.sol
     */
    function CrowdsaleS1(
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
     * Calculates bonus (30%)
     */
    function getBonus(uint256 _amount) internal pure returns (uint256) {
        return _amount.div(10).mul(3);
    }  

    /**
     * Overrides parent contracts to combine implementation of CappedCrowdsale and TimedCrowdsale
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        Crowdsale._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

    /**
     * Overrides parent contracts
     * Unlike parent contracts, it does NOT call internal {_deliverTokens} method
     * {_tokenAmount} does not include bonus
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        // TODO: lockup MaestroToken(token)
        uint256 bonusAmount = getBonus(_tokenAmount);
        uint256 tokenAmountWithBonus = _tokenAmount.add(bonusAmount);

        require(MaestroToken(token).processPurchaseWithBonus(_beneficiary, tokenAmountWithBonus, bonusAmount));
    }

    /**
     * Grant initial tokens to company members
     * TODO: Move this to MaestroToken as it does not pertain to CrowdsaleS1 !!!
     */
    // function reserveInitialCompanyTokens() internal {
    //     // Company-reserve tokens
    //     MaestroToken(token).transfer(companyAddress, numCompanyReserveTokens);

    //     //
    //     // TODO: Distribute initial tokens to partners and creators
    //     //
    //     address[] storage recipients;
    //     recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
    //     recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
    //     recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
    //     recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);

    //     uint[] storage tokens;
    //     tokens.push(100000 * (10 ** uint256(decimals)));
    //     tokens.push(100000 * (10 ** uint256(decimals)));
    //     tokens.push(100000 * (10 ** uint256(decimals)));
    //     tokens.push(100000 * (10 ** uint256(decimals)));

    //     require(MaestroToken(token).adminBatchTransferWithLockup(recipients, tokens));
    // }
}
