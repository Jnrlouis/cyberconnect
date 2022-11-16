# Cyberconnnect Subscribe Paid Monthly MiddleWare

## Project Description

Contract deployed on goerli: https://goerli.etherscan.io/address/0x33Db5f85012F72Bc4836E55148B5FBB4374B285A

The contract location in the repo: https://github.com/Jnrlouis/cyberconnect/blob/master/contracts/middlewares/subscribe/SubscribeMwPaidMonthly.sol

This MiddleWare can be used for Monthly Subscription.

Call the `checkMonthlySubscription` with the `profileID` and `collector` address as arguments to check for a valid monthly subscription.

This function keeps track of the last subscription date and only returns `true` if the last subscription is less than 30 days.

## Project Motivation

Instead of a One time subscription model, some profiles would prefer the option of a monthly subscription model.
This encourages content creators to continually put out topnotch content.