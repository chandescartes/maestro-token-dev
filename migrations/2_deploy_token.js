const MaestroToken = artifacts.require("MaestroToken");

module.exports = function(deployer, network, accounts) {
    const initialSupplyWithoutDecimals = 3000000;
    const lockupDurationS1 = 1;
    const lockupDurationS2 = 1;
    const lockupDurationTeam = 3;

    deployer.deploy(MaestroToken, initialSupplyWithoutDecimals, lockupDurationS1, lockupDurationS2, lockupDurationTeam);
};
