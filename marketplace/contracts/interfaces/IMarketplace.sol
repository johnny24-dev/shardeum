//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;


interface IMarketplace {
    event CreateAsk(
        uint256 event_id,
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address to
    );
    event CancelAsk(
        uint256 event_id,
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenID
    );
    event AcceptAsk(
        uint256 event_id,
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed buyer,
        address to
    );

    event CreateBid(
        uint256 event_id,
        uint256 bid_id,
        address indexed nft,
        uint256 indexed tokenID,
        address indexed bidder,
        uint256 price
    );
    event CancelBid(
        uint256 event_id,
        uint256 bid_id,
        address indexed nft,
        uint256 indexed tokenID,
        address indexed bidder
    );

    event AcceptBid(
        uint256 event_id,
        uint256 bid_id,
        address indexed nft,
        uint256 indexed tokenID,
        address bidder,
        address indexed accepter,
        uint256 price
    );

    event CreateCollectionOffer(
        uint256 event_id,
        uint256 collection_offer_id,
        address bidder,
        uint256 price_per_item,
        uint256 quantity
    );

    event CancleCollectionOffer(
        uint256 event_id,
        uint256 collection_offer_id,
        address bidder,
        uint256 price_per_item,
        uint256 quantity,
        uint256 recived_amount
    );

    event AcceptCollectionOffer(
        uint256 event_id,
        uint256 collection_offer_id,
        address bidder,
        uint256 price_per_item,
        uint256 remaining_quantity
    );

    event WithdrawEvent(
        uint256 event_id,
        address sender,
        uint256 amount
    );

    struct Ask {
        bool exists;
        address seller;
        uint256 price;
        address to;
    }

    struct Bid {
        uint256 bid_id;
        bool exists;
        address buyer;
        uint256 price;
    }

    struct CollectionOffer {
        uint256 collection_offer_id;
        address bidder;
        uint256 price_per_item;
        uint256 amount;
    }

    function createAsk(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        address[] calldata to
    ) external;

    function createBid(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price
    ) external payable;

    function createCollectionOffer(
        address nft,
        uint256 pricePerItem,
        uint256 quantity
    ) external payable;

    function cancelAsk(
        address[] calldata nft,
        uint256[] calldata tokenID
    ) external;

    function cancelBid(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata bidID
    ) external;

    function cancelCollectionOffer(
        address nft,
        uint256 collectionOfferId
    ) external;

    function acceptAsk(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata prices
    ) external payable;

    function acceptBid(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata bidID,
        uint256[] calldata prices
    ) external payable;

    function acceptCollectionOffer(
        address nft,
        uint256 tokenID,
        uint256 collectionOfferId,
        uint256 price
    ) external payable;

    function withdraw() external;
}
