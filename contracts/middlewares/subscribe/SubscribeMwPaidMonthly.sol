// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "../../dependencies/solmate/ERC721.sol";
import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";
import { ICyberEngine } from "../../interfaces/ICyberEngine.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";

/**
 * @title  Subscribe Paid Monthly Middleware
 * @author jnrlouis
 * @notice This contract is a middleware to allow users to subscribe monthly and pay a certain fee to the profile owner.
 */
contract SubscribePaidMonthlyMw is ISubscribeMiddleware, FeeMw {
    using SafeERC20 for IERC20;
    uint24 internal immutable PERIOD = 30 days;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event SubscribePaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed amount,
        address recipient,
        address currency,
        uint256 subscribeTime
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct PaidSubscribeData {
        uint256 amount;
        address recipient;
        address currency;
        uint256 subscribeTime;
    }

    mapping(address => mapping(uint256 => PaidSubscribeData))
        internal _paidSubscribeData;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Stores the parameters for setting up the paid subscribe middleware, checks if the amount, recipient, and
     * currency is valid and approved and stores the time of the subscription.
     */
    function setSubscribeMwData(uint256 profileId, bytes calldata data)
        external
        override
        returns (bytes memory)
    {
        (
            uint256 amount,
            address recipient,
            address currency
        ) = abi.decode(data, (uint256, address, address));

        require(amount != 0, "INVALID_AMOUNT");
        require(recipient != address(0), "INVALID_ADDRESS");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        _paidSubscribeData[msg.sender][profileId].amount = amount;
        _paidSubscribeData[msg.sender][profileId].recipient = recipient;
        _paidSubscribeData[msg.sender][profileId].currency = currency;
        _paidSubscribeData[msg.sender][profileId].subscribeTime = block.timestamp;


        emit SubscribePaidMwSet(
            msg.sender,
            profileId,
            amount,
            recipient,
            currency,
            block.timestamp
        );
        return new bytes(0);
    }

    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Checks if the subscriber already has an existing subscription, if not, transfer the amount required from the subscriber to the treasury
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address,
        bytes calldata
    ) external override {
        require(!checkMonthlySubscription(profileId, subscriber), "SUBSCRIBED_FOR_MONTH");
        address currency = _paidSubscribeData[msg.sender][profileId].currency;
        uint256 amount = _paidSubscribeData[msg.sender][profileId].amount;
        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualPaid = amount - treasuryCollected;


        IERC20(currency).safeTransferFrom(
            subscriber,
            _paidSubscribeData[msg.sender][profileId].recipient,
            actualPaid
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                subscriber,
                _treasuryAddress(),
                treasuryCollected
            );
        }
    }

    /// @inheritdoc ISubscribeMiddleware
    function postProcess(
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }

    /**
     * @notice Call this function to check if the subscription is still valid.
     * @notice Checks for any existing subscription.
     * @notice Checks the last time of subscription to see if it is up to 30 days, returns false if it isn't
     */
    function checkMonthlySubscription(uint256 profileId, address collector)
        internal
        view
        returns (bool)
    {
        uint256 subscribeTime = _paidSubscribeData[msg.sender][profileId].subscribeTime;
        uint256 duration = block.timestamp - subscribeTime;
        address essenceOwnerSubscribeNFT = IProfileNFT(msg.sender)
            .getSubscribeNFT(profileId);

        return (essenceOwnerSubscribeNFT != address(0) &&
            ERC721(essenceOwnerSubscribeNFT).balanceOf(collector) != 0) && 
            (duration < PERIOD);
    }
}
