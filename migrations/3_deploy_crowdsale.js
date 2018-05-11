const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const rate = 1000;
    const wallet = "0x62e850DC2bCa2A66a6392c3c1310e79bd68cCB01";
    const cap = 10 * (10 ** 18); // Ten ether

    // const latest = res.timestamp;
    // const openingTime = latest + 60; // One minute
    // const closingTime = openingTime + 600; // Ten minutes

    const openingTime = 1526149864;
    const closingTime = openingTime + 600; // Ten minutes
    
    // Ropsten: 0x210f043c348ea032b12114001f194c90490f978f
    deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, "0x210f043c348ea032b12114001f194c90490f978f");
};
