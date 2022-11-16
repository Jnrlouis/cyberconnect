// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const TreasuryAddress = "0x07865c6e87b9f70255377e024ace6630c1eaa37f"

  const SubscribePaidMonthlyMw = await hre.ethers.getContractFactory("SubscribePaidMonthlyMw");
  const subscribepaidmonthlymw = await SubscribePaidMonthlyMw.deploy(TreasuryAddress);

  await subscribepaidmonthlymw.deployed();

  console.log(
    `subscribepaidmonthlymw deployed to ${subscribepaidmonthlymw.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
