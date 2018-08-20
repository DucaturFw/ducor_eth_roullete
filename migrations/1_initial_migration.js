let Migrations = artifacts.require("./Migrations.sol");
let DucorRoulette = artifacts.require("./DucorRoulette.sol");

module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(DucorRoulette);
};