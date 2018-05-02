const MaestroToken = artifacts.require("MaestroToken");

module.exports = function(deployer, network, accounts) {
    const initialSupplyWithoutDecimals = 9999;

    deployer.deploy(MaestroToken, initialSupplyWithoutDecimals);
};
