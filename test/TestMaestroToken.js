const MaestroToken = artifacts.require("MaestroToken");

contract("MaestroToken Test", async (accounts) => {

    const INITIAL_SUPPLY_IN_TOKENS = 999;
    const LOCKUP_DURATION_IN_SECONDS = 60;

    it("should call constructor correctly", async () => {
        let instance = await MaestroToken.deployed();

        let owner = await instance.owner.call();
        console.log("OWNER: " + owner);
        assert.equal(owner, accounts[0]);

        let ownerBalance = await instance.balanceOf.call(owner);
        console.log("BALANCE:       " + ownerBalance);
        assert.equal(ownerBalance, INITIAL_SUPPLY_IN_TOKENS * (10 ** 18));

        let totalSupply = await instance.totalSupply.call();
        console.log("TOTAL_SUPPLY:  " + totalSupply);
        assert.equal(totalSupply, INITIAL_SUPPLY_IN_TOKENS * (10 ** 18));

        // TODO: Add tests for new parameters
    });

    // it("should not allow non-owners access to methods", async () => {
    //     let instance = await MaestroToken.deployed();

    //     let res1 = instance.processPurchaseWithBonus.call(accounts[0], 100, 50, {from: accounts[1]});
    //     assert.equal(res1, false);

    //     let res2 = instance.adminBatchTransferWithLockup.call([], [], {from: accounts[1]});
    //     assert.equal(res1, false);
    // });

    it("should transfer values properly", async () => {
        let instance = await MaestroToken.deployed();

        let value = 9 * (10 ** 18);
        let balance0 = (await instance.balanceOf.call(accounts[1])).toNumber();
        console.log(balance0);
        assert.equal(balance0, 0);

        await instance.transfer(accounts[1], value, {from: accounts[0]});

        let balance1 = (await instance.balanceOf.call(accounts[1])).toNumber();
        console.log(balance1);
        assert.equal(balance1, value);

        let balance2 = (await instance.balanceOf.call(accounts[0])).toNumber();
        console.log(balance2);
    });

    // TODO: Test time-dependent functions
    // TODO: Test allowance
    // TODO: Test requires

});
