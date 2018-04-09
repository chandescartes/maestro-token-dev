var SafeMath = artifacts.require("SafeMath");
var AdminOwnable = artifacts.require("AdminOwnable");
var ERC20Standard = artifacts.require("ERC20Standard");
var PoSTokenCustomStandard = artifacts.require("PoSTokenCustomStandard");
var MaestroToken = artifacts.require("MaestroToken");

module.exports = function(deployer) {
  deployer.deploy(
		SafeMath,
		AdminOwnable,
  	ERC20Standard,
  	PoSTokenCustomStandard
	);
	deployer.link(SafeMath, MaestroToken);
  deployer.deploy(MaestroToken);
};
