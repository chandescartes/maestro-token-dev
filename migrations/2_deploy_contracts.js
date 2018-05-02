const MaestroToken = artifacts.require("MaestroToken");
const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const initialSupplyWithoutDecimals = 9999;

    const latest = web3.eth.getBlock('latest').timestamp;
    const openingTime = latest + 5;
    const closingTime = openingTime + 60; // One minute
    const rate = 1000;
    const wallet = accounts[2];
    const cap = 10 * (10 ** 18); // Ten ether

    deployer.deploy(MaestroToken, initialSupplyWithoutDecimals).then(function() {
        return deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, MaestroToken.address);
    });
};
