const MaestroCrowdsale = artifacts.require("MaestroCrowdsale");

module.exports = function(deployer, network, accounts) {
    const rate = 10000;
    const wallet = "0x5048CBB64E5A75d560F9CD6F5D901111d57aCB17";
    const cap = 6200000000000000000000;
    const token = "0xf2ed54531a1e1f9d325ed4bf898bab8cf619295b";

    const openingTime = ;
    const closingTime = 1530284399;

    deployer.deploy(MaestroCrowdsale, openingTime, closingTime, rate, wallet, cap, token);
};
