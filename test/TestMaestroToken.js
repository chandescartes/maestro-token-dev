const MaestroToken = artifacts.require("MaestroToken");

contract("MaestroToken Test", async (accounts) => {

    const INITIAL_SUPPLY_WITHOUT_DECIMALS = 9999;
    const INITIAL_SUPPLY = INITIAL_SUPPLY_WITHOUT_DECIMALS * (10 ** 18);

    let maestroToken;

    beforeEach(async () => {
        maestroToken = await MaestroToken.new(INITIAL_SUPPLY_WITHOUT_DECIMALS);
    });

    it("should call constructor correctly", async () => {
        const OWNER = accounts[0]
        let owner = await maestroToken.owner.call();
        assert.equal(owner, OWNER);

        let initialSupply = (await maestroToken.initialSupply.call()).toNumber();
        assert.equal(initialSupply, INITIAL_SUPPLY);

        let ownerBalance = (await maestroToken.balanceOf.call(owner)).toNumber();
        assert.equal(ownerBalance, INITIAL_SUPPLY);

        let totalSupply = (await maestroToken.totalSupply.call()).toNumber();
        assert.equal(totalSupply, INITIAL_SUPPLY);
    });

    it("should transfer values properly", async () => {
        const SENDER = accounts[0];
        const RECEIVER = accounts[1];

        const VALUE = 9 * (10 ** 18);

        const FROM_BALANCE_BEFORE = INITIAL_SUPPLY;
        const TO_BALANCE_BEFORE = 0;

        const FROM_BALANCE_AFTER = INITIAL_SUPPLY - VALUE;
        const TO_BALANCE_AFTER = VALUE;

        let fromBalanceBefore = (await maestroToken.balanceOf.call(SENDER)).toNumber();
        assert.equal(fromBalanceBefore, FROM_BALANCE_BEFORE);
        
        let toBalanceBefore = (await maestroToken.balanceOf.call(RECEIVER)).toNumber();
        assert.equal(toBalanceBefore, TO_BALANCE_BEFORE);

        await maestroToken.transfer(RECEIVER, VALUE, {from: SENDER});

        let fromBalanceAfter = (await maestroToken.balanceOf.call(SENDER)).toNumber();
        assert.equal(fromBalanceAfter, FROM_BALANCE_AFTER);

        let toBalanceAfter = (await maestroToken.balanceOf.call(RECEIVER)).toNumber();
        assert.equal(toBalanceAfter, TO_BALANCE_AFTER);
    });

    it("should approve and transfer values properly", async () => {
        const OWNER = accounts[0];
        const SPENDER = accounts[1];
        const RECEIVER = accounts[2];

        const APPROVE_VALUE = 99 * (10 ** 18);
        const TRANSFER_VALUE = 9 * (10 ** 18);

        const OWNER_BALANCE_BEFORE = INITIAL_SUPPLY;
        const SPENDER_ALLOWANCE_BEFORE = 0;
        const RECEIVER_BALANCE_BEFORE = 0;

        const OWNER_BALANCE_AFTER_APPROVAL = INITIAL_SUPPLY;
        const SPENDER_ALLOWANCE_AFTER_APPROVAL = APPROVE_VALUE;
        const RECEIVER_BALANCE_AFTER_APPROVAL = 0;

        const OWNER_BALANCE_AFTER_TRANSFER = INITIAL_SUPPLY - TRANSFER_VALUE;
        const SPENDER_ALLOWANCE_AFTER_TRANSFER = APPROVE_VALUE - TRANSFER_VALUE;
        const RECEIVER_BALANCE_AFTER_TRANSFER = TRANSFER_VALUE;

        let ownerBalanceBefore = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceBefore, OWNER_BALANCE_BEFORE);
        
        let spenderAllowanceBefore = (await maestroToken.allowance.call(OWNER, SPENDER)).toNumber();
        assert.equal(spenderAllowanceBefore, SPENDER_ALLOWANCE_BEFORE);

        let receiverBalanceBefore = (await maestroToken.balanceOf.call(RECEIVER)).toNumber();
        assert.equal(receiverBalanceBefore, RECEIVER_BALANCE_BEFORE);

        await maestroToken.approve(SPENDER, APPROVE_VALUE);

        let ownerBalanceAfterApproval = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfterApproval, OWNER_BALANCE_AFTER_APPROVAL);
        
        let spenderAllowanceAfterApproval = (await maestroToken.allowance.call(OWNER, SPENDER)).toNumber();
        assert.equal(spenderAllowanceAfterApproval, SPENDER_ALLOWANCE_AFTER_APPROVAL);

        let receiverBalanceAfterApproval = (await maestroToken.balanceOf.call(RECEIVER)).toNumber();
        assert.equal(receiverBalanceAfterApproval, RECEIVER_BALANCE_AFTER_APPROVAL);

        await maestroToken.transferFrom(OWNER, RECEIVER, TRANSFER_VALUE, {from: SPENDER});

        let ownerBalanceAfterTransfer = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfterTransfer, OWNER_BALANCE_AFTER_TRANSFER);
        
        let spenderAllowanceAfterTransfer = (await maestroToken.allowance.call(OWNER, SPENDER)).toNumber();
        assert.equal(spenderAllowanceAfterTransfer, SPENDER_ALLOWANCE_AFTER_TRANSFER);

        let receiverBalanceAfterTransfer = (await maestroToken.balanceOf.call(RECEIVER)).toNumber();
        assert.equal(receiverBalanceAfterTransfer, RECEIVER_BALANCE_AFTER_TRANSFER);
    });

    // TODO: Test time-dependent functions
    // TODO: Test requires

});
