const MaestroToken = artifacts.require("MaestroToken");

module.exports = function(deployer, network, accounts) {
    const initialSupplyWithoutDecimals = 1000000000;
    const lockupDurationS1 = 365;
    const lockupDurationS2 = 365;
    const lockupDurationTeam = 365;

    deployer.deploy(MaestroToken, initialSupplyWithoutDecimals, lockupDurationS1, lockupDurationS2, lockupDurationTeam);
};
