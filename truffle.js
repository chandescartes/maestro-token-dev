var HDWalletProvider = require("truffle-hdwallet-provider");
var fs = require("fs");

/* 
 * Mnemonic will be saved in external file, which will be securely kept in each developer's local storage
 * A developer is responsible for creating "mnemonic.txt" accordingly since it won't be managed under git.
 */

var index = 0;
var mnemonic;

fs.readFile('./mnemonic.txt', 'utf8', function (err,data) {
	if (err) {
		return console.log(err);
	}
	mnemonic = data;
});

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 7545,
            network_id: "*",
			gas: 6720000
        },

		ropsten: {
			provider: function() {
				return new HDWalletProvider(mnemonic, 
					"https://mainnet.infura.io/m4ZCKrKf5i0cHjFjwP06", index)
			},
			network_id: "*",
			gas: 4700000
		}
    }
};
