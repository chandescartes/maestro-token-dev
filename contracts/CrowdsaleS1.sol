pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

import "./MaestroToken.sol";


/**
 * Maestro Crowdsale Season #1
 */
contract CrowdsaleS1 is CappedCrowdsale, TimedCrowdsale {

    uint8 constant public decimals = 18;

    // Address of wallet to which tokens for company will be transfered
    // TODO: Initialize with constructor?
    address constant public COMPANY_RESERVE_ADDRESS = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;

    // Number of tokens for company-reserve
    // TODO: Initialize with constructor?
    uint constant public numCompanyReserveTokens = 1000000 * (10 ** uint256(decimals));

    /**
     * Constructor
     * Variables from inherited contracts
     * {rate, wallet, token} from Crowdsale.sol
     * {cap} from CappedCrowdsale.sol
     * {openingTime, closingTime} from TimedCrowdsale.sol
     */
    function CrowdsaleS1(
        uint256 _openingTime,   // Opening time in timestamp
        uint256 _closingTime,   // Closing time in timestamp
        uint256 _rate,          // How many token units a buyer gets per wei
        address _wallet,        // Address where funds are collected
        uint256 _cap,           // Max amount of wei to be contributed
        ERC20 _token            // The token being sold
        // uint256 _goal
    )
        public
        Crowdsale(_rate, _wallet, MaestroToken(_token))
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        // The goal needs to less than or equal to the cap
        // require(_goal <= _cap);

        reserveInitialCompanyTokens();
    }

    /**
     * Calculates bonus (30%)
     */
    function getBonus(uint256 _amount) internal pure returns (uint256) {
        return _amount.div(10).mul(3);
    }

    /**
     * Overrides parent contracts
     * Extend parent behavior to add and lock up bonus
     * {_tokenAmount} does not include bonus
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        // TODO: lockup MaestroToken(token)
        uint256 bonusAmount = getBonus(_tokenAmount);
        uint256 tokenAmountWithBonus = _tokenAmount.add(bonusAmount);

        _deliverTokens(_beneficiary, tokenAmountWithBonus);
        MaestroToken(token).lockTokens(_beneficiary, _tokenAmount);
    }

    /**
     * Grant initial tokens to company members
     */
    function reserveInitialCompanyTokens() internal {
        // Company-reserve tokens
        MaestroToken(token).transfer(COMPANY_RESERVE_ADDRESS, numCompanyReserveTokens);

        //
        // TODO: Distribute initial tokens to partners and creators
        // TODO: Use {memory} instead of {storage}?
        //
        address[] storage recipients;
        recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
        recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
        recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);
        recipients.push(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);

        uint[] storage tokens;
        tokens.push(100000 * (10 ** uint256(decimals)));
        tokens.push(100000 * (10 ** uint256(decimals)));
        tokens.push(100000 * (10 ** uint256(decimals)));
        tokens.push(100000 * (10 ** uint256(decimals)));

        MaestroToken(token).adminBatchTransferWithLockup(recipients, tokens);
    }
}
