//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IMarketplace.sol";
import "./interfaces/INFTContract.sol";
import "./NFTCommon.sol";


contract Marketplace is IMarketplace, Initializable {
    using Address for address payable;
    using NFTCommon for INFTContract;

    mapping(address => mapping(uint256 => Ask)) public asks;
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) public bids;
    mapping(address => mapping(uint256 => CollectionOffer))
        public collectionOffers;
    mapping(address => uint256) public escrow;

    // =====================================================================

    address payable beneficiary;
    address admin;
    uint256 marketFee;
    uint256 current_bid_id;
    uint256 current_collection_offer_id;

    // =====================================================================

    string private constant REVERT_NOT_OWNER_OF_TOKEN_ID =
        "Marketplace::not an owner of token ID";
    string private constant REVERT_OWNER_OF_TOKEN_ID =
        "Marketplace::owner of token ID";
    string private constant REVERT_BID_TOO_LOW = "Marketplace::bid too low";
    string private constant REVERT_NOT_A_CREATOR_OF_BID =
        "Marketplace::not a creator of the bid";
    string private constant REVERT_NOT_A_CREATOR_OF_ASK =
        "Marketplace::not a creator of the ask";
    string private constant REVERT_ASK_DOES_NOT_EXIST =
        "Marketplace::ask does not exist";
    string private constant REVERT_CANT_ACCEPT_OWN_ASK =
        "Marketplace::cant accept own ask";
    string private constant REVERT_ASK_IS_RESERVED =
        "Marketplace::ask is reserved";
    string private constant REVERT_ASK_INSUFFICIENT_VALUE =
        "Marketplace::ask price higher than sent value";
    string private constant REVERT_ASK_SELLER_NOT_OWNER =
        "Marketplace::ask creator not owner";
    string private constant REVERT_NFT_NOT_SENT = "Marketplace::NFT not sent";
    string private constant REVERT_INSUFFICIENT_ETHER =
        "Marketplace::insufficient ether sent";

    // =====================================================================

    function initialize(
        address payable newBeneficiary,
        uint256 _marketFee
    ) public initializer {
        beneficiary = newBeneficiary;
        admin = msg.sender;
        marketFee = _marketFee;
        current_bid_id = 0;
        current_collection_offer_id = 0;
    }

    // constructor() initializer {}



    // admin function ==============================

    function updateFundAddress(address payable _newFund) external {
        require(admin == msg.sender, "Invalid Admin");
        beneficiary = _newFund;
    }

    function updateMarketFee(uint256 _newFee) external {
        require(admin == msg.sender, "Invalid Admin");
        marketFee = _newFee;
    }


    // /// @notice Sellers can receive their payment by calling this function.
    function withdraw() external override {
        uint256 amount = escrow[msg.sender];
        require(amount > 0, "Not enough amount to withdraw");
        escrow[msg.sender] = 0;
        (bool sent, bytes memory _data) = address(msg.sender).call{
            value: amount
        }("");
        require(sent, "Failed to send Ether");
        emit WithdrawEvent(address(msg.sender), amount);
    }


    // ======= CREATE ASK / BID ============================================

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`, which can
    /// be reserved for `to`, if `to` is not a zero address.
    /// @dev Creating an ask requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to sell.
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param to      Addresses for which the sale is reserved. If zero address,
    /// then anyone can accept.
    function createAsk(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        address[] calldata to
    ) external override {
        for (uint256 i = 0; i < nft.length; i++) {
            require(
                nft[i].quantityOf(msg.sender, tokenID[i]) > 0,
                REVERT_NOT_OWNER_OF_TOKEN_ID
            );
            // if feecollector extension applied, this ensures math is correct
            require(price[i] > 10_000, "price too low");

            bool isApproved = nft[i].approveCommon(address(this), tokenID[i]);
            require(isApproved, "NFT is not approved");

            // overwristes or creates a new one
            asks[address(nft[i])][tokenID[i]] = Ask({
                exists: true,
                seller: msg.sender,
                price: price[i],
                to: to[i]
            });

            emit CreateAsk({
                seller: msg.sender,
                nft: address(nft[i]),
                tokenID: tokenID[i],
                price: price[i],
                to: to[i]
            });
        }
    }

    /// @notice Creates a bid on (`nft`, `tokenID`) tuple for `price`.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to buy.
    /// @param price   Prices at which the buyer is willing to buy the NFTs.
    function createBid(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price
    ) external payable override {
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < nft.length; i++) {
            address nftAddress = address(nft[i]);
            // overwrites or creates a new one
            uint256 bid_id = current_bid_id + 1;
            bids[nftAddress][tokenID[i]][bid_id] = Bid({
                bid_id: bid_id,
                exists: true,
                buyer: msg.sender,
                price: price[i]
            });

            emit CreateBid({
                bid_id: bid_id,
                nft: nftAddress,
                tokenID: tokenID[i],
                bidder: msg.sender,
                price: price[i]
            });
            current_bid_id = bid_id;
            totalPrice += price[i];
        }

        require(totalPrice == msg.value, REVERT_INSUFFICIENT_ETHER);
    }

    function createCollectionOffer(
        INFTContract nft,
        uint256 pricePerItem,
        uint256 quantity
    ) external payable override {
        uint256 mustPay = quantity * pricePerItem;
        require(mustPay == msg.value, "INVALID BALANCE");
        uint256 collection_offer_id = current_collection_offer_id + 1;
        address nftAddress = address(nft);

        collectionOffers[nftAddress][collection_offer_id] = CollectionOffer({
            collection_offer_id: collection_offer_id,
            bidder: msg.sender,
            price_per_item: pricePerItem,
            amount: quantity
        });

        emit CreateCollectionOffer({
            collection_offer_id: collection_offer_id,
            bidder: msg.sender,
            price_per_item: pricePerItem,
            quantity: quantity
        });
    }

    // ======= CANCEL ASK / BID ============================================

    /// @notice Cancels ask(s) that the seller previously created.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the
    /// asks on.
    function cancelAsk(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID
    ) external override {
        for (uint256 i = 0; i < nft.length; i++) {
            address nftAddress = address(nft[i]);
            require(
                asks[nftAddress][tokenID[i]].seller == msg.sender,
                REVERT_NOT_A_CREATOR_OF_ASK
            );

            bool revoke = nft[i].revokesCommon(address(this), tokenID[i]);
            require(revoke, "NFT is not revoked!");

            delete asks[nftAddress][tokenID[i]];

            emit CancelAsk({
                seller: msg.sender,
                nft: nftAddress,
                tokenID: tokenID[i]
            });
        }
    }

    /// @notice Cancels bid(s) that the msg.sender previously created.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the
    /// bids on.
    function cancelBid(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata bidID
    ) external override {
        for (uint256 i = 0; i < nft.length; i++) {
            address nftAddress = address(nft[i]);
            require(
                bids[nftAddress][tokenID[i]][bidID[i]].buyer == msg.sender,
                REVERT_NOT_A_CREATOR_OF_BID
            );

            escrow[msg.sender] += bids[nftAddress][tokenID[i]][bidID[i]].price;

            delete bids[nftAddress][tokenID[i]][bidID[i]];

            emit CancelBid({
                bid_id: bidID[i],
                nft: nftAddress,
                tokenID: tokenID[i],
                bidder: msg.sender
            });
        }
    }

    function cancelCollectionOffer(
        INFTContract nft,
        uint256 collectionOfferId
    ) external {
        address nftAddress = address(nft);
        require(
            collectionOffers[nftAddress][collectionOfferId].bidder ==
                msg.sender,
            REVERT_NOT_A_CREATOR_OF_ASK
        );
        uint256 reFund = collectionOffers[nftAddress][collectionOfferId]
            .amount *
            collectionOffers[nftAddress][collectionOfferId].price_per_item;
        escrow[msg.sender] += reFund;

        emit CancleCollectionOffer({
            collection_offer_id: collectionOfferId,
            bidder: msg.sender,
            price_per_item: collectionOffers[nftAddress][collectionOfferId]
                .price_per_item,
            quantity: collectionOffers[nftAddress][collectionOfferId].amount,
            recived_amount: reFund
        });

        delete collectionOffers[nftAddress][collectionOfferId];
    }

    // ======= ACCEPT ASK / BID ===========================================

    /// @notice Seller placed ask(s), you (buyer) are fine with the terms. You accept
    /// their ask by sending the required msg.value and indicating the id of the
    /// token(s) you are purchasing.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the
    /// asks on.
    function acceptAsk(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID
    ) external payable override {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < nft.length; i++) {
            address nftAddress = address(nft[i]);

            require(
                asks[nftAddress][tokenID[i]].exists,
                REVERT_ASK_DOES_NOT_EXIST
            );
            require(
                asks[nftAddress][tokenID[i]].seller != msg.sender,
                REVERT_CANT_ACCEPT_OWN_ASK
            );
            if (asks[nftAddress][tokenID[i]].to != address(0)) {
                require(
                    asks[nftAddress][tokenID[i]].to == msg.sender,
                    REVERT_ASK_IS_RESERVED
                );
            }
            require(
                nft[i].quantityOf(
                    asks[nftAddress][tokenID[i]].seller,
                    tokenID[i]
                ) > 0,
                REVERT_ASK_SELLER_NOT_OWNER
            );

            totalPrice += asks[nftAddress][tokenID[i]].price;

            // escrow[asks[nftAddress][tokenID[i]].seller] += _takeFee(
            //     asks[nftAddress][tokenID[i]].price
            // );

            _distribute(
                nftAddress,
                tokenID[i],
                asks[nftAddress][tokenID[i]].seller,
                asks[nftAddress][tokenID[i]].price
            );

            // if there is a bid for this tokenID from msg.sender, cancel and refund
            // if (bids[nftAddress][tokenID[i]].buyer == msg.sender) {
            //     escrow[bids[nftAddress][tokenID[i]].buyer] += bids[nftAddress][
            //         tokenID[i]
            //     ].price;
            //     delete bids[nftAddress][tokenID[i]];
            // }

            emit AcceptAsk({
                nft: nftAddress,
                tokenID: tokenID[i],
                price: asks[nftAddress][tokenID[i]].price,
                buyer: msg.sender,
                to: asks[nftAddress][tokenID[i]].to
            });

            bool success = nft[i].safeTransferFrom_(
                asks[nftAddress][tokenID[i]].seller,
                msg.sender,
                tokenID[i],
                new bytes(0)
            );
            require(success, REVERT_NFT_NOT_SENT);

            delete asks[nftAddress][tokenID[i]];
        }

        require(totalPrice == msg.value, REVERT_ASK_INSUFFICIENT_VALUE);
    }

    /// @notice You are the owner of the NFTs, someone submitted the bids on them.
    /// You accept one or more of these bids.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the
    /// bids on.
    function acceptBid(
        INFTContract[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata bidID
    ) external payable override {
        uint256 escrowDelta = 0;
        for (uint256 i = 0; i < nft.length; i++) {
            require(
                nft[i].quantityOf(msg.sender, tokenID[i]) > 0,
                REVERT_NOT_OWNER_OF_TOKEN_ID
            );

            address nftAddress = address(nft[i]);

            escrowDelta += bids[nftAddress][tokenID[i]][bidID[i]].price;

            _distribute(
                nftAddress,
                tokenID[i],
                msg.sender,
                bids[nftAddress][tokenID[i]][bidID[i]].price
            );

            bool isApproved = nft[i].approveCommon(address(this), tokenID[i]);
            require(isApproved, "NFT is not approved");

            emit AcceptBid({
                bid_id: bids[nftAddress][tokenID[i]][bidID[i]].bid_id,
                nft: nftAddress,
                tokenID: tokenID[i],
                bidder: bids[nftAddress][tokenID[i]][bidID[i]].buyer,
                accepter: msg.sender,
                price: bids[nftAddress][tokenID[i]][bidID[i]].price
            });

            bool success = nft[i].safeTransferFrom_(
                msg.sender,
                bids[nftAddress][tokenID[i]][bidID[i]].buyer,
                tokenID[i],
                new bytes(0)
            );
            require(success, REVERT_NFT_NOT_SENT);
            if (asks[nftAddress][tokenID[i]].exists) {
                delete asks[nftAddress][tokenID[i]];
            }

            delete bids[nftAddress][tokenID[i]][bidID[i]];
        }

        // uint256 remaining = _takeFee(escrowDelta);
        // escrow[msg.sender] = remaining;
        require(escrowDelta == msg.value, REVERT_ASK_INSUFFICIENT_VALUE);
    }

    function acceptCollectionOffer(
        INFTContract nft,
        uint256 tokenID,
        uint256 collectionOfferId
    ) external payable {
        address nftAddress = address(nft);
        require(
            collectionOffers[nftAddress][collectionOfferId].amount > 0,
            "reamain amount must greater than 0 "
        );
        require(
            nft.quantityOf(msg.sender, tokenID) > 0,
            REVERT_NOT_OWNER_OF_TOKEN_ID
        );

        bool isApproved = nft.approveCommon(address(this), tokenID);
        require(isApproved, "NFT is not approved");

        bool success = nft.safeTransferFrom_(
            msg.sender,
            collectionOffers[nftAddress][collectionOfferId].bidder,
            tokenID,
            new bytes(0)
        );
        require(success, REVERT_NFT_NOT_SENT);
        if (asks[nftAddress][tokenID].exists) {
            delete asks[nftAddress][tokenID];
        }
        _distribute(
            nftAddress,
            tokenID,
            msg.sender,
            collectionOffers[nftAddress][tokenID].price_per_item
        );
        collectionOffers[nftAddress][tokenID].amount =
            collectionOffers[nftAddress][tokenID].amount -
            1;

        address bidder = collectionOffers[nftAddress][collectionOfferId].bidder;
        uint256 price_per_item = collectionOffers[nftAddress][collectionOfferId]
            .price_per_item;
        uint256 remain_quantity = collectionOffers[nftAddress][tokenID].amount;

        if (collectionOffers[nftAddress][tokenID].amount == 0) {
            delete collectionOffers[nftAddress][collectionOfferId];
        }

        emit AcceptCollectionOffer({
            collection_offer_id: collectionOfferId,
            bidder: bidder,
            price_per_item: price_per_item,
            remaining_quantity: remain_quantity
        });
    }

    
    // ============ ADMIN ==================================================

    /// @dev Used to change the address of the trade fee receiver.
    function changeBeneficiary(address payable newBeneficiary) external {
        require(msg.sender == admin, "");
        require(newBeneficiary != payable(address(0)), "");
        beneficiary = newBeneficiary;
    }

    /// @dev sets the admin to the zero address. This implies that beneficiary
    /// address and other admin only functions are disabled.
    function revokeAdmin() external {
        require(msg.sender == admin, "");
        admin = address(0);
    }

    // ============ EXTENSIONS =============================================

    /// @dev Hook that is called to collect the fees in FeeCollector extension.
    /// Plain implementation of marketplace (without the FeeCollector extension)
    /// has no fees.
    /// @param totalPrice Total price payable for the trade(s).
    function _takeFee(uint256 totalPrice) internal virtual returns (uint256) {
        return totalPrice;
    }

    function _distribute(
        address _collectionAddress,
        uint256 _tokenId,
        address _sellerAddress,
        uint256 _salePrice
    ) internal {
        uint256 marketShare = (_salePrice * marketFee) / 10000;
        (address creatorAddress, uint256 creatorShare) = _getCreatorShare(
            _collectionAddress,
            _tokenId,
            _salePrice
        );

        uint256 sellerShare = _salePrice - marketShare - creatorShare;

        if (creatorShare > 0 && creatorAddress != address(0)) {
            escrow[creatorAddress] += creatorShare;
        }
        escrow[beneficiary] += marketShare;
        escrow[_sellerAddress] += sellerShare;
    }

    function _getCreatorShare(
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _salePrice
    ) private view returns (address, uint256) {
        if (
            ERC165Checker.supportsInterface(
                _collectionAddress,
                type(IERC2981).interfaceId
            )
        ) {
            (address creatorAddress, uint256 creatorShare) = INFTContract(
                _collectionAddress
            ).royaltyInfo(_tokenId, _salePrice);

            return (creatorAddress, creatorShare);
        } else {
            return (address(0), 0);
        }
    }
}
