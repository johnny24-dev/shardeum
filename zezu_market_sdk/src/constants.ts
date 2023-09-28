
export const CONTRACT_NAME = "ZeZu Exchange";
export const CONTRACT_VERSION = "1.0";
export const CONTRACT_ADDRESS = "0x082b17d39cA772400F9cF311daA72bc3eF94e599";
export const CHAIN_ID = 8081;


export const DOMAIN = {
  name: CONTRACT_NAME,
  version: CONTRACT_VERSION,
  chainId: CHAIN_ID,
  verifyingContract: CONTRACT_ADDRESS
}

export const EIP_712_ORDER_TYPE = {
  Order: [
    { name: "trader", type: "address" },
    { name: "collection", type: "address" },
    { name: "listingsRoot", type: "bytes32" },
    { name: "numberOfListings", type: "uint256" },
    { name: "expirationTime", type: "uint256" },
    { name: "assetType", type: "uint8" },
    { name: "makerFee", type: "FeeRate" },
    { name: "salt", type: "uint256" },
    { name: "orderType", type: "uint8" },
    { name: "nonce", type: "uint256" },
  ],
  FeeRate: [
    { name: "recipient", type: "address" },
    { name: "rate", type: "uint16" }
  ]
};

export const EIP_712_OFFER_COLLECTION_TYPE = {
  OfferColection: [
    { name: "trader", type: "address" },
    { name: "collection", type: "address" },
    { name: "listingsRoot", type: "bytes32" },
    { name: "numberOfListings", type: "uint256" },
    { name: "expirationTime", type: "uint256" },
    { name: "assetType", type: "uint8" },
    { name: "makerFee", type: "FeeRate" },
    { name: "salt", type: "uint256" },
    { name: "orderType", type: "uint8" },
    { name: "nonce", type: "uint256" },
    { name: "pricePerItem", type: "uint256" },
  ],
  FeeRate: [
    { name: "recipient", type: "address" },
    { name: "rate", type: "uint16" }
  ]
};

export const MAX_INT = BigInt(
  "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
);
export const ONE_HUNDRED_PERCENT_BP = 10000;
export const NO_CONDUIT =
  "0x0000000000000000000000000000000000000000000000000000000000000000";