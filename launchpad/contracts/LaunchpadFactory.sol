// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./BlueMoveNFT.sol";
import "./IBlueMoveNFT.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./FixinTokenSpender.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LaunchpadFactory is FixinTokenSpender {
    struct Collection {
        address collection_address;
        string name;
        string symbol;
        uint256 supply;
        string token_uri;
        uint256 royalty;
        address royalty_wallet;
        address creator_wallet;
        uint256 next_token_id;
        bool iterated_uri;
    }

    struct MintGroup {
        string name;
        bytes32 merkle_root;
        uint256 max_tokens;
        uint256 unit_price;
        uint256 start_time;
        uint256 end_time;
    }

    struct MintInfoDetail {
        bool exist;
        string group_name;
        uint256 minted;
    }

    event RegisterCollectionEvent(
        address indexed collection_address,
        string name,
        string symbol,
        uint256 supply
    );

    event UpdateCollectionEvent(
        address indexed collection_address,
        string name,
        string symbol,
        uint256 supply
    );

    event MintNativeEvent(
        address indexed collection_address,
        address indexed minter,
        uint256 quantity,
        uint256 price_per_item
    );

    mapping(address => Collection) private collections;
    mapping(address => mapping(address => mapping( string => MintInfoDetail)))
        private mint_nft_info;
    mapping(address => mapping(uint256 => address)) private token_info;
    mapping(address => mapping(string => MintGroup)) private mint_groups;

    address admin;

    constructor() {
        admin = msg.sender;
    }

    // function initialize() public initializer {
    //     admin = msg.sender;
    // }

    function register_collection(
        string memory name,
        string memory symbol,
        uint256 supply,
        string memory token_uri,
        uint256 royalty,
        address royalty_wallet,
        address creator_wallet,
        bool iterated_uri,
        MintGroup[] calldata _mint_groups
    ) external {
        require(msg.sender == admin, "Invalid Owner");
        address new_collection_address = address(
            new BlueMoveNFT(name, symbol, royalty, royalty_wallet)
        );
        Collection memory collection = Collection(
            new_collection_address,
            name,
            symbol,
            supply,
            token_uri,
            royalty,
            royalty_wallet,
            creator_wallet,
            1,
            iterated_uri
        );
        collections[new_collection_address] = collection;

        for (uint i = 0; i < _mint_groups.length; ) {
            mint_groups[new_collection_address][
                _mint_groups[i].name
            ] = _mint_groups[i];
            unchecked {
                i++;
            }
        }

        emit RegisterCollectionEvent(
            new_collection_address,
            name,
            symbol,
            supply
        );
    }

    function update_collection(
        address collection_address,
        string memory name,
        string memory symbol,
        uint256 supply,
        string memory token_uri,
        address creator_wallet,
        bool iterated_uri,
        MintGroup[] calldata _mint_groups
    ) external {
        require(msg.sender == admin, "Invalid Owner");
        Collection memory new_collection = Collection(
            collection_address,
            name,
            symbol,
            supply,
            token_uri,
            collections[collection_address].royalty,
            collections[collection_address].royalty_wallet,
            creator_wallet,
            1,
            iterated_uri
        );
        require(
            collections[collection_address].supply > 0,
            "Collection not exist!"
        );
        collections[collection_address] = new_collection;

        for (uint i = 0; i < _mint_groups.length; ) {
            mint_groups[collection_address][
                _mint_groups[i].name
            ] = _mint_groups[i];
            unchecked {
                i++;
            }
        }

        emit UpdateCollectionEvent(collection_address, name, symbol, supply);
    }

    function mint_native(
        address collection_address,
        string memory group_name,
        uint256 quantity,
        bytes32[] calldata _proof
    ) external payable {
        Collection memory collection = collections[collection_address];

        MintGroup memory mint_group = mint_groups[collection_address][
            group_name
        ];

        require(
            collection.supply > 0 &&
                collection.next_token_id + quantity <= collection.supply,
            "Not enough for sale"
        );

        uint256 current_time = block.timestamp * 1000;
        require(mint_group.start_time <= current_time && current_time <= mint_group.end_time, "Not time to mint");

        uint256 must_pay = quantity * mint_group.unit_price;
        require(msg.value == must_pay, "Invalid Balance");
        // check wl
        if (bytes32(0) != mint_group.merkle_root) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verifyCalldata(
                    _proof,
                    mint_group.merkle_root,
                    leaf
                ),
                "Invalid proof"
            );
        }

        MintInfoDetail memory mint_info = mint_nft_info[msg.sender][
            collection_address
        ][group_name];

        require(mint_info.minted < mint_group.max_tokens, "Max Token Minted");

        // send eth to creator
        _transferEth(collection.creator_wallet, must_pay);
        // // mint nft
        for (uint256 j = 0; j < quantity; ) {
            uint256 current_id = collection.next_token_id;
            string memory token_uri = create_token_uri(
                collection.token_uri,
                current_id
            );
            IBlueMoveNFT(collection_address).safeMint(
                msg.sender,
                current_id,
                token_uri
            );
            if (!mint_info.exist) {
                mint_info.group_name = group_name;
                mint_info.exist = true;
            }
            mint_info.minted += 1;
            collection.next_token_id += 1;
            token_info[collection_address][current_id] = msg.sender;
            unchecked {
                j += 1;
            }
        }

        // // update state

        collections[collection_address] = collection;
        mint_nft_info[msg.sender][collection_address][group_name] = mint_info;

        emit MintNativeEvent(
            collection_address,
            msg.sender,
            quantity,
            mint_group.unit_price
        );
    }

    // view function

    function getCollection(
        address collection_address
    ) public view returns (Collection memory collection) {
        collection = collections[collection_address];
    }

    function getMintInfoDetail(
        address collection_address,
        string memory group_name
    ) public view returns (MintInfoDetail memory mint_info) {
        mint_info = mint_nft_info[msg.sender][collection_address][group_name];
    }

    function getMinter(
        address collection_address,
        uint256 token_id
    ) public view returns (address minter) {
        minter = token_info[collection_address][token_id];
    }

    function getPhase(address collection_address, string memory group_name) public view returns (MintGroup memory phase){
        phase = mint_groups[collection_address][group_name];
    }

    // utils
    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function create_token_uri(
        string memory base_token_uri,
        uint256 token_id
    ) internal pure returns (string memory token_uri) {
        string memory str_token_id = string(abi.encode(token_id));
        token_uri = string(
            abi.encodePacked(base_token_uri, "/", str_token_id, ".json")
        );
    }
}
