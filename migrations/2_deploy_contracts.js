var MaestroToken = artifacts.require("MaestroToken");
const CrowdsaleS1 = artifacts.require("CrowdsaleS1");

module.exports = function(deployer, network, accounts) {
    const latest = web3.eth.getBlock('latest').timestamp;
    // const cap = web3.toWei(4000, 'ether');

    deployer.deploy(MaestroToken, 999, 60, 1).then(function() {
        return deployer.deploy(CrowdsaleS1, latest + 1, latest + (6000000 * 60), 1000, accounts[2], 4 * 10**18, MaestroToken.address);
    });
};
