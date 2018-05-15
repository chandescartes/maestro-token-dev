const MaestroToken = artifacts.require("MaestroToken");
const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

contract("MaestroCrowdsale Test", async (accounts) => {

    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    const INITIAL_SUPPLY_WITHOUT_DECIMALS = 9999;
    const INITIAL_SUPPLY = INITIAL_SUPPLY_WITHOUT_DECIMALS * (10 ** 18);
    const LOCKUP_DURATION_S1 = 180;
    const LOCKUP_DURATION_S2 = 180;
    const LOCKUP_DURATION_TEAM = 365;

    let LATEST;
    let OPENING_TIME;
    let CLOSING_TIME;
    const RATE = 1000;
    const WALLET = accounts[2];
    const CAP = 3 * (10 ** 18);

    let maestroToken;
    let maestroCrowdsale;

    beforeEach(async () => {
        LATEST = await web3.eth.getBlock('latest').timestamp;
        OPENING_TIME = await LATEST + 5;
        CLOSING_TIME = await OPENING_TIME + 60; // One minute

        maestroToken = await MaestroToken.new(INITIAL_SUPPLY_WITHOUT_DECIMALS, LOCKUP_DURATION_S1, LOCKUP_DURATION_S2, LOCKUP_DURATION_TEAM);
        maestroCrowdsale = await MaestroCrowdsale.new(OPENING_TIME, CLOSING_TIME, RATE, WALLET, CAP, maestroToken.address);
    });

    it("should call constructor correctly", async () => {
        let openingTime = (await maestroCrowdsale.openingTime.call()).toNumber();
        assert.equal(openingTime, OPENING_TIME);

        let closingTime = (await maestroCrowdsale.closingTime.call()).toNumber();
        assert.equal(closingTime, CLOSING_TIME);

        let rate = (await maestroCrowdsale.rate.call()).toNumber();
        assert.equal(rate, RATE);

        let wallet = await maestroCrowdsale.wallet.call();
        assert.equal(wallet, WALLET);

        let cap = (await maestroCrowdsale.cap.call()).toNumber();
        assert.equal(cap, CAP);

        let token = await maestroCrowdsale.token.call();
        assert.equal(token, maestroToken.address);
    });

    it("should buy tokens from crowdsale S1", async () => {
        const OWNER = accounts[0];
        const BUYER = accounts[1];
        const OTHER = accounts[3];
        const CROWDSALE = await maestroCrowdsale.address;

        const RELEASE_DATE = CLOSING_TIME + (60 * 60 * 24 * LOCKUP_DURATION_S1);

        const CROWDSALE_AMOUNT = CAP * RATE * 13 / 10;

        const BUY_AMOUNT_IN_WEI = 1 * (10 ** 18);
        const TOKEN_AMOUNT_WITHOUT_BONUS = BUY_AMOUNT_IN_WEI * RATE;
        const BONUS_AMOUNT = TOKEN_AMOUNT_WITHOUT_BONUS * 3 / 10;
        const TOKEN_AMOUNT = TOKEN_AMOUNT_WITHOUT_BONUS + BONUS_AMOUNT;

        const OWNER_BALANCE_BEFORE = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_BEFORE = 0;
        const CROWDSALE_BALANCE_BEFORE = CROWDSALE_AMOUNT;
        const WALLET_BALANCE_BEFORE = (await web3.eth.getBalance(WALLET)).toNumber();
        const BUYER_LOCKUP_BEFORE = 0;
        const WEI_RAISED_BEFORE = 0;

        const OWNER_BALANCE_AFTER = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_AFTER = TOKEN_AMOUNT;
        const CROWDSALE_BALANCE_AFTER = CROWDSALE_AMOUNT - TOKEN_AMOUNT;
        const WALLET_BALANCE_AFTER = WALLET_BALANCE_BEFORE + BUY_AMOUNT_IN_WEI;
        const BUYER_LOCKUP_AFTER = BONUS_AMOUNT;
        const WEI_RAISED_AFTER = BUY_AMOUNT_IN_WEI;

        const CROWDSALE_BALANCE_FINAL = 0;
        const TOTAL_SUPPLY_FINAL = INITIAL_SUPPLY - (CROWDSALE_AMOUNT - TOKEN_AMOUNT);

        // Set crowdsale
        await maestroToken.setCrowdsaleS1(CROWDSALE);
        let releaseDate = (await maestroToken.releaseDateS1.call()).toNumber();
        assert.equal(releaseDate, RELEASE_DATE);

        let ownerBalanceBefore = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceBefore, OWNER_BALANCE_BEFORE);

        let buyerBalanceBefore = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceBefore, BUYER_BALANCE_BEFORE);

        let crowdsaleBalanceBefore = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceBefore, CROWDSALE_BALANCE_BEFORE);

        let walletBalanceBefore = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceBefore, WALLET_BALANCE_BEFORE);

        let buyerLockupBefore = (await maestroToken.getLockupS1.call(BUYER)).toNumber();
        assert.equal(buyerLockupBefore, BUYER_LOCKUP_BEFORE);

        let weiRaisedBefore = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedBefore, WEI_RAISED_BEFORE);

        // Increase time to begin crowdsale and buy tokens
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [5], id: 123})
        await maestroCrowdsale.buyTokens(BUYER, {value: BUY_AMOUNT_IN_WEI, from: BUYER});

        let ownerBalanceAfter = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfter, OWNER_BALANCE_AFTER);

        let buyerBalanceAfter = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceAfter, BUYER_BALANCE_AFTER);

        let crowdsaleBalanceAfter = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceAfter, CROWDSALE_BALANCE_AFTER);

        let walletBalanceAfter = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceAfter, WALLET_BALANCE_AFTER);

        let buyerLockupAfter = (await maestroToken.getLockupS1.call(BUYER)).toNumber();
        assert.equal(buyerLockupAfter, BUYER_LOCKUP_AFTER);

        let weiRaisedAfter = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedAfter, WEI_RAISED_AFTER);

        // Increase time to end crowdsale and finalize
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [60], id: 123})
        await maestroCrowdsale.finalize();

        let crowdsaleBalanceFinal = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceFinal, CROWDSALE_BALANCE_FINAL);

        let totalSupplyFinal = (await maestroToken.totalSupply.call()).toNumber();
        assert.equal(totalSupplyFinal, TOTAL_SUPPLY_FINAL);

        let isFinalized = await maestroCrowdsale.isFinalized.call();
        assert.equal(isFinalized, true);

        // Increase time to pass release date and attempt transfer lockup
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [(60 * 60 * 24 * 365)], id: 123})
        await maestroToken.transfer(OTHER, BUYER_BALANCE_AFTER, {from: BUYER});
    });

    it("should buy tokens from crowdsale S2", async () => {
        const OWNER = accounts[0];
        const BUYER = accounts[1];
        const OTHER = accounts[3];
        const CROWDSALE = await maestroCrowdsale.address;

        const RELEASE_DATE = CLOSING_TIME + (60 * 60 * 24 * LOCKUP_DURATION_S2);

        const CROWDSALE_AMOUNT = CAP * RATE * 11 / 10;

        const BUY_AMOUNT_IN_WEI = 1 * (10 ** 18);
        const TOKEN_AMOUNT_WITHOUT_BONUS = BUY_AMOUNT_IN_WEI * RATE;
        const BONUS_AMOUNT = TOKEN_AMOUNT_WITHOUT_BONUS * 1 / 10;
        const TOKEN_AMOUNT = TOKEN_AMOUNT_WITHOUT_BONUS + BONUS_AMOUNT;

        const OWNER_BALANCE_BEFORE = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_BEFORE = 0;
        const CROWDSALE_BALANCE_BEFORE = CROWDSALE_AMOUNT;
        const WALLET_BALANCE_BEFORE = (await web3.eth.getBalance(WALLET)).toNumber();
        const BUYER_LOCKUP_BEFORE = 0;
        const WEI_RAISED_BEFORE = 0;

        const OWNER_BALANCE_AFTER = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_AFTER = TOKEN_AMOUNT;
        const CROWDSALE_BALANCE_AFTER = CROWDSALE_AMOUNT - TOKEN_AMOUNT;
        const WALLET_BALANCE_AFTER = WALLET_BALANCE_BEFORE + BUY_AMOUNT_IN_WEI;
        const BUYER_LOCKUP_AFTER = BONUS_AMOUNT;
        const WEI_RAISED_AFTER = BUY_AMOUNT_IN_WEI;

        const CROWDSALE_BALANCE_FINAL = 0;
        const TOTAL_SUPPLY_FINAL = INITIAL_SUPPLY - (CROWDSALE_AMOUNT - TOKEN_AMOUNT);

        // Set crowdsale
        await maestroToken.setCrowdsaleS2(CROWDSALE);
        let releaseDate = (await maestroToken.releaseDateS2.call()).toNumber();
        assert.equal(releaseDate, RELEASE_DATE);

        let ownerBalanceBefore = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceBefore, OWNER_BALANCE_BEFORE);

        let buyerBalanceBefore = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceBefore, BUYER_BALANCE_BEFORE);

        let crowdsaleBalanceBefore = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceBefore, CROWDSALE_BALANCE_BEFORE);

        let walletBalanceBefore = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceBefore, WALLET_BALANCE_BEFORE);

        let buyerLockupBefore = (await maestroToken.getLockupS2.call(BUYER)).toNumber();
        assert.equal(buyerLockupBefore, BUYER_LOCKUP_BEFORE);

        let weiRaisedBefore = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedBefore, WEI_RAISED_BEFORE);

        // Increase time to begin crowdsale and buy tokens
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [5], id: 123})
        await maestroCrowdsale.buyTokens(BUYER, {value: BUY_AMOUNT_IN_WEI, from: BUYER});

        let ownerBalanceAfter = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfter, OWNER_BALANCE_AFTER);

        let buyerBalanceAfter = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceAfter, BUYER_BALANCE_AFTER);

        let crowdsaleBalanceAfter = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceAfter, CROWDSALE_BALANCE_AFTER);

        let walletBalanceAfter = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceAfter, WALLET_BALANCE_AFTER);

        let buyerLockupAfter = (await maestroToken.getLockupS2.call(BUYER)).toNumber();
        assert.equal(buyerLockupAfter, BUYER_LOCKUP_AFTER);

        let weiRaisedAfter = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedAfter, WEI_RAISED_AFTER);

        // Increase time to end crowdsale and finalize
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [60], id: 123})
        await maestroCrowdsale.finalize();

        let crowdsaleBalanceFinal = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceFinal, CROWDSALE_BALANCE_FINAL);

        let totalSupplyFinal = (await maestroToken.totalSupply.call()).toNumber();
        assert.equal(totalSupplyFinal, TOTAL_SUPPLY_FINAL);

        let isFinalized = await maestroCrowdsale.isFinalized.call();
        assert.equal(isFinalized, true);

        // Increase time to pass release date and attempt transfer lockup
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [(60 * 60 * 24 * 365)], id: 123})
        await maestroToken.transfer(OTHER, BUYER_BALANCE_AFTER, {from: BUYER});
    });

    it("should buy tokens from crowdsale S3", async () => {
        const OWNER = accounts[0];
        const BUYER = accounts[1];
        const OTHER = accounts[3];
        const CROWDSALE = await maestroCrowdsale.address;

        const CROWDSALE_AMOUNT = CAP * RATE;

        const BUY_AMOUNT_IN_WEI = 1 * (10 ** 18);
        const TOKEN_AMOUNT_WITHOUT_BONUS = BUY_AMOUNT_IN_WEI * RATE;
        const BONUS_AMOUNT = 0;
        const TOKEN_AMOUNT = TOKEN_AMOUNT_WITHOUT_BONUS + BONUS_AMOUNT;

        const OWNER_BALANCE_BEFORE = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_BEFORE = 0;
        const CROWDSALE_BALANCE_BEFORE = CROWDSALE_AMOUNT;
        const WALLET_BALANCE_BEFORE = (await web3.eth.getBalance(WALLET)).toNumber();
        const BUYER_LOCKUP_BEFORE = 0;
        const WEI_RAISED_BEFORE = 0;

        const OWNER_BALANCE_AFTER = INITIAL_SUPPLY - CROWDSALE_AMOUNT;
        const BUYER_BALANCE_AFTER = TOKEN_AMOUNT;
        const CROWDSALE_BALANCE_AFTER = CROWDSALE_AMOUNT - TOKEN_AMOUNT;
        const WALLET_BALANCE_AFTER = WALLET_BALANCE_BEFORE + BUY_AMOUNT_IN_WEI;
        const BUYER_LOCKUP_AFTER = BONUS_AMOUNT;
        const WEI_RAISED_AFTER = BUY_AMOUNT_IN_WEI;

        const CROWDSALE_BALANCE_FINAL = 0;
        const TOTAL_SUPPLY_FINAL = INITIAL_SUPPLY - (CROWDSALE_AMOUNT - TOKEN_AMOUNT);

        // Set crowdsale
        await maestroToken.setCrowdsaleS3(CROWDSALE);

        let ownerBalanceBefore = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceBefore, OWNER_BALANCE_BEFORE);

        let buyerBalanceBefore = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceBefore, BUYER_BALANCE_BEFORE);

        let crowdsaleBalanceBefore = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceBefore, CROWDSALE_BALANCE_BEFORE);

        let walletBalanceBefore = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceBefore, WALLET_BALANCE_BEFORE);

        let weiRaisedBefore = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedBefore, WEI_RAISED_BEFORE);

        // Increase time to begin crowdsale and buy tokens
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [5], id: 123})
        await maestroCrowdsale.buyTokens(BUYER, {value: BUY_AMOUNT_IN_WEI, from: BUYER});

        let ownerBalanceAfter = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfter, OWNER_BALANCE_AFTER);

        let buyerBalanceAfter = (await maestroToken.balanceOf.call(BUYER)).toNumber();
        assert.equal(buyerBalanceAfter, BUYER_BALANCE_AFTER);

        let crowdsaleBalanceAfter = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceAfter, CROWDSALE_BALANCE_AFTER);

        let walletBalanceAfter = (await web3.eth.getBalance(WALLET)).toNumber();
        assert.equal(walletBalanceAfter, WALLET_BALANCE_AFTER);

        let weiRaisedAfter = (await maestroCrowdsale.weiRaised.call()).toNumber();
        assert.equal(weiRaisedAfter, WEI_RAISED_AFTER);

        // Increase time to end crowdsale and finalize
        await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [60], id: 123})
        await maestroCrowdsale.finalize();

        let crowdsaleBalanceFinal = (await maestroToken.balanceOf.call(CROWDSALE)).toNumber();
        assert.equal(crowdsaleBalanceFinal, CROWDSALE_BALANCE_FINAL);

        let totalSupplyFinal = (await maestroToken.totalSupply.call()).toNumber();
        assert.equal(totalSupplyFinal, TOTAL_SUPPLY_FINAL);

        let isFinalized = await maestroCrowdsale.isFinalized.call();
        assert.equal(isFinalized, true);

        // Do NOT increase time and attempt transfer lockup
        await maestroToken.transfer(OTHER, BUYER_BALANCE_AFTER, {from: BUYER});
    });

});
