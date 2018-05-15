const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const rate = 10000;
    const wallet = "0x0CD5d8747da0790c9a29E4F34bcf46cc3Bdf8976";
    const cap = 100000000000000000000;
    const token = "0x45c1f4b458af1ee1f736d5423a147c9bb89702b8";

    // const latest = res.timestamp;
    // const openingTime = latest + 60; // One minute
    // const closingTime = openingTime + 600; // Ten minutes

    const openingTime = 1526367600;
    const closingTime = 1526454000; // Ten minutes
    
    // Ropsten: 0x210f043c348ea032b12114001f194c90490f978f
    deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, token);
};
