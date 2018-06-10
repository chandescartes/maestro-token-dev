const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const rate = 10000;
    const wallet = "0x0CD5d8747da0790c9a29E4F34bcf46cc3Bdf8976";
    const cap = 100000000000000000000;
    // const token = "0x45c1f4b458af1ee1f736d5423a147c9bb89702b8";
    // const token = "0xa8c6612a86773e650fadf35a28aae0e2ea225d53"; // Ganache
    const token = "0x987d1c9451f316db63340979a11a558472c88ec0"; // new

    // const latest = res.timestamp;
    // const openingTime = latest + 60; // One minute
    // const closingTime = openingTime + 600; // Ten minutes

    const openingTime = 1528669800;
    const closingTime = openingTime + 36000; // Ten hours

    // Ropsten: 0x210f043c348ea032b12114001f194c90490f978f
    deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, token);
};
