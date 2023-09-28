// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TakeAsk, TakeBid, TakeAskSingle, TakeBidSingle, Order, Exchange, Fees, FeeRate, AssetType, OrderType, Transfer, FungibleTransfers, StateUpdate, Cancel, Listing, TakeCollectionOffer} from "../lib/Structs.sol";

interface IZeZuExchange {
    error InsufficientFunds();
    error TokenTransferFailed();
    error InvalidOrder();
    error ProtocolFeeTooHigh();

    event NewProtocolFee(address indexed recipient, uint16 indexed rate);
    event NewGovernor(address indexed governor);
    event NewBlockRange(uint256 blockRange);
    event CancelTrade(
        address indexed user,
        bytes32 hash,
        uint256 index,
        uint256 amount
    );
    event NonceIncremented(address indexed user, uint256 newNonce);
    event SetOracle(address indexed user, bool approved);

    // function initialize() external;

    function setProtocolFee(address recipient, uint16 rate) external;

    function setGovernor(address _governor) external;

    // function setOracle(address oracle, bool approved) external;

    // function setBlockRange(uint256 _blockRange) external;

    function cancelTrades(Cancel[] memory cancels) external;

    function incrementNonce() external;

    /*//////////////////////////////////////////////////////////////
                          EXECUTION WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function takeAsk(TakeAsk memory inputs) external payable;

    function takeBid(TakeBid memory inputs) external;

    function takeAskSingle(TakeAskSingle memory inputs) external payable;

    function takeBidSingle(TakeBidSingle memory inputs) external;

    function takeCollectionOffer(TakeCollectionOffer memory input) external;

    /*//////////////////////////////////////////////////////////////
                        EXECUTION POOL WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function takeAskSinglePool(
        TakeAskSingle memory inputs,
        uint256 amountToWithdraw
    ) external payable;

    function takeAskPool(
        TakeAsk memory inputs,
        uint256 amountToWithdraw
    ) external payable;
}
