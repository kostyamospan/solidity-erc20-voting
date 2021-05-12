const Voter = artifacts.require("VoterERC20");

module.exports = function (deployer) {
  deployer.deploy(Voter, "ABOBA", "abb", 1000);
};
