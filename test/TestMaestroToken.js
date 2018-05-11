const MaestroToken = artifacts.require("MaestroToken");

contract("MaestroToken Test", async (accounts) => {

    const INITIAL_SUPPLY_WITHOUT_DECIMALS = 9999;
    const INITIAL_SUPPLY = INITIAL_SUPPLY_WITHOUT_DECIMALS * (10 ** 18);
    const LOCKUP_DURATION_S1 = 180;
    const LOCKUP_DURATION_S2 = 180;
    const LOCKUP_DURATION_TEAM = 365;

    let maestroToken;

    beforeEach(async () => {
        maestroToken = await MaestroToken.new(INITIAL_SUPPLY_WITHOUT_DECIMALS, LOCKUP_DURATION_S1, LOCKUP_DURATION_S2, LOCKUP_DURATION_TEAM);
    });

    it("should call constructor correctly", async () => {
        const OWNER = accounts[0];

        let owner = await maestroToken.owner.call();
        assert.equal(owner, OWNER);

        let initialSupply = (await maestroToken.initialSupply.call()).toNumber();
        assert.equal(initialSupply, INITIAL_SUPPLY);

        let ownerBalance = (await maestroToken.balanceOf.call(owner)).toNumber();
        assert.equal(ownerBalance, INITIAL_SUPPLY);

        let totalSupply = (await maestroToken.totalSupply.call()).toNumber();
        assert.equal(totalSupply, INITIAL_SUPPLY);

        let lockupDurationS1 = (await maestroToken.lockupDurationS1.call()).toNumber();
        assert.equal(lockupDurationS1, LOCKUP_DURATION_S1 * 60 * 60 * 24);

        let lockupDurationS2 = (await maestroToken.lockupDurationS2.call()).toNumber();
        assert.equal(lockupDurationS2, LOCKUP_DURATION_S2 * 60 * 60 * 24);

        let lockupDurationTeam = (await maestroToken.lockupDurationTeam.call()).toNumber();
        assert.equal(lockupDurationTeam, LOCKUP_DURATION_TEAM * 60 * 60 * 24);

        let releaseDateTeam = (await maestroToken.releaseDateTeam.call()).toNumber();
        console.log(releaseDateTeam);
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

    it("should transfer and lock values properly", async () => {
        const OWNER = accounts[0];
        const MEMBER = accounts[1];

        const VALUE = 9 * (10 ** 18);

        const OWNER_BALANCE_BEFORE = INITIAL_SUPPLY;
        const MEMBER_BALANCE_BEFORE = 0;
        const MEMBER_LOCKUP_BEFORE = 0;

        const OWNER_BALANCE_AFTER_1 = INITIAL_SUPPLY - VALUE;
        const MEMBER_BALANCE_AFTER_1 = VALUE;
        const MEMBER_LOCKUP_AFTER_1 = VALUE;

        const OWNER_BALANCE_AFTER_2 = INITIAL_SUPPLY - (VALUE * 2);
        const MEMBER_BALANCE_AFTER_2 = VALUE * 2;
        const MEMBER_LOCKUP_AFTER_2 = VALUE * 2;

        let ownerBalanceBefore = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceBefore, OWNER_BALANCE_BEFORE);
        
        let memberBalanceBefore = (await maestroToken.balanceOf.call(MEMBER)).toNumber();
        assert.equal(memberBalanceBefore, MEMBER_BALANCE_BEFORE);

        let memberLockupBefore = (await maestroToken.getLockupTeam.call({from: MEMBER})).toNumber();
        assert.equal(memberLockupBefore, MEMBER_LOCKUP_BEFORE);

        await maestroToken.transferAndLock(MEMBER, VALUE);

        let ownerBalanceAfter1 = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfter1, OWNER_BALANCE_AFTER_1);
        
        let memberBalanceAfter1 = (await maestroToken.balanceOf.call(MEMBER)).toNumber();
        assert.equal(memberBalanceAfter1, MEMBER_BALANCE_AFTER_1);

        let memberLockupAfter1 = (await maestroToken.getLockupTeam.call({from: MEMBER})).toNumber();
        assert.equal(memberLockupAfter1, MEMBER_LOCKUP_AFTER_1);

        await maestroToken.transferAndLock(MEMBER, VALUE);

        let ownerBalanceAfter2 = (await maestroToken.balanceOf.call(OWNER)).toNumber();
        assert.equal(ownerBalanceAfter2, OWNER_BALANCE_AFTER_2);
        
        let memberBalanceAfter2 = (await maestroToken.balanceOf.call(MEMBER)).toNumber();
        assert.equal(memberBalanceAfter2, MEMBER_BALANCE_AFTER_2);

        let memberLockupAfter2 = (await maestroToken.getLockupTeam.call({from: MEMBER})).toNumber();
        assert.equal(memberLockupAfter2, MEMBER_LOCKUP_AFTER_2);
    });

    // TODO: Test time-dependent functions
    // TODO: Test requires

});
