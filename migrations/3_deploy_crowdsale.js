const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const rate = 10000;
    const wallet = "0x4f8b41416f28E686A6eAF5B25b90F9197DF47b77";
    const cap = 100000000000000000000;
    const token = "0xb0bd6577acc126c6f5e5cb853283e9dae7b41104";

    // const latest = res.timestamp;
    // const openingTime = latest + 60; // One minute
    // const closingTime = openingTime + 600; // Ten minutes

    const openingTime = 1526280000;
    const closingTime = 1526452800; // Ten minutes
    
    // Ropsten: 0x210f043c348ea032b12114001f194c90490f978f
    deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, token);
};
