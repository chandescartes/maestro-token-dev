const MaestroToken = artifacts.require("MaestroToken");

module.exports = function(deployer, network, accounts) {
    const initialSupplyWithoutDecimals = 9999;
    const lockupDurationS1 = 180;
    const lockupDurationS2 = 180;
    const lockupDurationTeam = 365;

    deployer.deploy(MaestroToken, initialSupplyWithoutDecimals, lockupDurationS1, lockupDurationS2, lockupDurationTeam);
};
