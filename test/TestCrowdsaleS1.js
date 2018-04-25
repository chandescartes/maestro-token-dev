const MaestroToken = artifacts.require("MaestroToken");
const CrowdsaleS1 = artifacts.require("CrowdsaleS1");

contract("CrowdsaleS1 Test", async (accounts) => {

	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

	const INITIAL_SUPPLY_IN_TOKENS = 999;
    const LOCKUP_DURATION_IN_SECONDS = 60;

	const RATE = 1000;
	const WALLET = accounts[2];
	const CAP = 4 * 10**18;

	it("should call constructor correctly", async () => {
		let instance = await CrowdsaleS1.deployed();

		let openingTime = await instance.openingTime.call();
        console.log("OPENING_TIME: " + openingTime);

        let closingTime = await instance.closingTime.call();
        console.log("CLOSING_TIME: " + closingTime);

        let rate = (await instance.rate.call()).toNumber();
        console.log("RATE: " + rate);
        assert.equal(rate, RATE);

        let wallet = await instance.wallet.call();
        console.log("WALLET: " + wallet);
        assert.equal(wallet, WALLET);

        let cap = await instance.cap.call();
        console.log("CAP: " + cap);
        assert.equal(cap, CAP);

        let token = await instance.token.call();
        console.log("TOKEN: " + token);
	});

	it("should buy tokens", async () => {
		let maestroToken = await MaestroToken.deployed();
		let crowdsaleS1 = await CrowdsaleS1.deployed();
		let owner = accounts[0];
		let buyer = accounts[1];
		let initialAmount = INITIAL_SUPPLY_IN_TOKENS * (10 ** 18);
		let buyAmountInWei = 1 * 10**17;
		let buyerBonus = buyAmountInWei * RATE * 3 / 10;
		let buyerBalanceWithBonus = buyAmountInWei * RATE + buyerBonus;

		// Owner of deployed MaestroToken should be accounts[0]
		assert.equal(await maestroToken.owner.call(), owner);

		// Deployed MaestroToken and Crowdsale's token should be the same
		assert.equal(await crowdsaleS1.token.call(), maestroToken.address);

		// MaestroToken's crowdsaleS1Address should be zero address initially
		assert.equal(await maestroToken.crowdsaleS1Address.call(), ZERO_ADDRESS);

		// Set crowdsaleS1Address and check
		await maestroToken.setCrowdsaleS1Address(crowdsaleS1.address);
		assert.equal(await maestroToken.crowdsaleS1Address.call(), crowdsaleS1.address);

		// Transfer entire balance of owner to Crowdsale address
		await maestroToken.transfer(crowdsaleS1.address, initialAmount, {from: owner});
		assert.equal((await maestroToken.balanceOf.call(owner)).toNumber(), 0);
		assert.equal((await maestroToken.balanceOf.call(crowdsaleS1.address)).toNumber(), initialAmount);

		/**
		 * Now set up is complete to test buying tokens
		 */

		// Buy Tokens with accounts[1]
		await crowdsaleS1.buyTokens(buyer, {value: buyAmountInWei, from: buyer});

		// Check weiRaised
		assert.equal((await crowdsaleS1.weiRaised.call()).toNumber(), buyAmountInWei);

		// Check balances and lockup
		assert.equal((await maestroToken.balanceOf(crowdsaleS1.address)).toNumber(), initialAmount - buyerBalanceWithBonus);
		assert.equal((await maestroToken.balanceOf(buyer)).toNumber(), buyerBalanceWithBonus);
		assert.equal((await maestroToken.getLockup(buyer)).toNumber(), buyerBonus);
	});
	
});
