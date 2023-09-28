import { keccak256, defaultAbiCoder, hexConcat } from 'ethers/lib/utils';
import { CHAIN_ID, CONTRACT_ADDRESS, CONTRACT_NAME, CONTRACT_VERSION, DOMAIN, EIP_712_OFFER_COLLECTION_TYPE, EIP_712_ORDER_TYPE, MAX_INT } from '../constants';
import { CollectionOfferDetail, CreateCollectionOfferInput, CreateOrderAndSignResponse, CreateOrderInput, CreateOrderResponse, Exchange, FeeRate, Listing, Order, OrderType } from '../types';
import { generateRandomSalt } from './utils';
import { BigNumber, Signer, Wallet, ethers } from 'ethers';
import MerkleTree from 'merkletreejs';


export const _FEE_RATE_TYPEHASH = "0xa192ca867b0af2744eab247871e1a6c69fcaeef80ace07b70395b60f43c0f489";

export const _ORDER_TYPEHASH = "0xaf92fd8295121c3ba2d0dc4f6af18edcd0b3aaeff05fc72c591de6d457ee0c05";

export const _OFFER_COLLECTION_TYPEHASH = "0xa371e9a6bd38416bd8ee647804ea48892a3be51a21db09335720e1bbf67dca92";

export const _hashFeeRate = (feeRate: FeeRate) => {
    return keccak256(defaultAbiCoder.encode(["bytes32", "address", "uint16"], [
        _FEE_RATE_TYPEHASH,
        feeRate.recipient,
        feeRate.rate
    ]
    ))
}

export const _hashListing = (listing: Listing) => {
    return keccak256(defaultAbiCoder.encode([
        "uint256",
        "uint256",
        "uint256",
        "uint256"
    ], [
        listing.index,
        listing.tokenId,
        listing.amount,
        listing.price.toString()
    ]))
}


export const _hash_order = (order: Order, orderType: OrderType, nonce: number) => {

    return keccak256(defaultAbiCoder.encode([
        "bytes32",
        "address",
        "address",
        "bytes32",
        "uint256",
        "uint256",
        "uint8",
        "bytes32",
        "uint256",
        "uint8",
        "uint256"
    ], [
        _ORDER_TYPEHASH,
        order.trader,
        order.collection,
        order.listingsRoot,
        order.numberOfListings,
        order.expirationTime.toString(),
        order.assetType,
        _hashFeeRate(order.makerFee),
        BigNumber.from(order.salt).toBigInt().toString(),
        orderType,
        nonce
    ]))
}

export const _hash_offer_collection = (order: Order, orderType: OrderType, nonce: number, pricePerItem: BigInt) => {

    return keccak256(defaultAbiCoder.encode([
        "bytes32",
        "address",
        "address",
        "bytes32",
        "uint256",
        "uint256",
        "uint8",
        "bytes32",
        "uint256",
        "uint8",
        "uint256",
        "uint256"
    ], [
        _OFFER_COLLECTION_TYPEHASH,
        order.trader,
        order.collection,
        order.listingsRoot,
        order.numberOfListings,
        order.expirationTime.toString(),
        order.assetType,
        _hashFeeRate(order.makerFee),
        BigNumber.from(order.salt).toBigInt().toString(),
        orderType,
        nonce,
        pricePerItem.toString()
    ]))
}


export const createOrdersAndSignOrders = async (singer: Wallet, orderInputs: CreateOrderInput[], orderType: number): Promise<CreateOrderAndSignResponse[]> => {
    const leaves = orderInputs.map((orderInput, index) => _hashListing({
        index,
        tokenId: orderInput.tokenId,
        amount: orderInput.amount,
        price: orderInput.price
    }));
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })
    const listingRoot = tree.getHexRoot()

    let res = Array<CreateOrderAndSignResponse>();

    for (let i = 0; i < orderInputs.length; i++) {

        const listing: Listing = {
            index: i,
            tokenId: orderInputs[i].tokenId,
            amount: orderInputs[i].amount,
            price: orderInputs[i].price
        }

        const leaf = _hashListing(listing);
        const proof = tree.getHexProof(leaf)

        const order: any = {
            trader: orderInputs[i].trader,
            collection: orderInputs[i].collection,
            listingsRoot: listingRoot,
            numberOfListings: orderInputs.length,
            expirationTime: orderInputs[i].expirationTime ?? MAX_INT,
            assetType: orderInputs[i].assetType,
            makerFee: orderInputs[i].makerFee ?? {
                rate: 0,
                recipient: ethers.constants.AddressZero
            },
            salt: orderInputs[i].salt ?? generateRandomSalt(),
            orderType: orderType,
            nonce: orderInputs[i].nonce
        }
        // console.log("🚀 ~ file: orderHash.ts:124 ~ ceateOrders ~ order:", { ...order, salt: BigNumber.from(order.salt).toBigInt().toString(), expirationTime: order.expirationTime.toString() })

        const order_hash = _hash_order(order, orderType, orderInputs[i].nonce)
        console.log("🚀 ~ file: orderHash.ts:142 ~ createOrdersAndSignOrders ~ order_hash:", order_hash)

        const signature = await singer._signTypedData(DOMAIN, EIP_712_ORDER_TYPE, order);

        delete order.orderType;
        delete order.nonce;

        const order_response: CreateOrderAndSignResponse = {
            order: {
                orderHash: order_hash,
                ...order,
                signature
            },
            exchange: {
                index: i,
                proof,
                listing,
                taker: {
                    amount: listing.amount,
                    tokenId: listing.tokenId
                }
            },
            takerFee: {
                rate: 0,
                recipient: ethers.constants.AddressZero
            }
        }

        res.push(order_response)

    }

    return res
}


export const createCollectionOfferAndSign = async (singer: Wallet, createCollectionOfferInput: CreateCollectionOfferInput): Promise<CollectionOfferDetail> => {


    const order: any = {
        trader: createCollectionOfferInput.trader,
        collection: createCollectionOfferInput.collection,
        listingsRoot: ethers.constants.HashZero,
        numberOfListings: createCollectionOfferInput.numberOfListings,
        expirationTime: (createCollectionOfferInput.expirationTime ?? MAX_INT).toString(),
        assetType: createCollectionOfferInput.assetType,
        makerFee: createCollectionOfferInput.makerFee ?? {
            rate: 0,
            recipient: ethers.constants.AddressZero
        },
        salt: BigNumber.from(createCollectionOfferInput.salt ?? generateRandomSalt()).toBigInt().toString(),
        orderType: OrderType.OFFER_COLLECTION,
        nonce: createCollectionOfferInput.nonce,
        pricePerItem: createCollectionOfferInput.pricePerItem.toString()
    }
    // console.log("🚀 ~ file: orderHash.ts:124 ~ ceateOrders ~ order:", { ...order, salt: BigNumber.from(order.salt).toBigInt().toString(), expirationTime: order.expirationTime.toString() })

    const offer_collection_hash = _hash_offer_collection(order, OrderType.OFFER_COLLECTION, createCollectionOfferInput.nonce, createCollectionOfferInput.pricePerItem);

    const signature = await singer._signTypedData(DOMAIN, EIP_712_OFFER_COLLECTION_TYPE, order);

    delete order.orderType;
    delete order.nonce;

    const colection_offer_response: CollectionOfferDetail = {
        ...order,
        colectionOfferHash: offer_collection_hash,
        signature,
        pricePerItem:createCollectionOfferInput.pricePerItem.toString()
    }


    return colection_offer_response
}

export const _formatOrderResponse = (createOrderAndSigResponses: CreateOrderAndSignResponse[], recipent: string, orderType: number) => {
    const res: CreateOrderResponse = {
        orders: [],
        exchanges: [],
        takerFee: {
            recipient: ethers.constants.AddressZero,
            rate: 0
        },
        tokenRecipient: recipent,
        signatures: ''
    }

    const raw_signature: (string | undefined)[] = []

    createOrderAndSigResponses.forEach((item, index) => {
        const order: Order = {
            trader: item.order.trader,
            collection: item.order.collection,
            listingsRoot: item.order.listingsRoot,
            numberOfListings: item.order.numberOfListings,
            expirationTime: item.order.expirationTime.toString(),
            assetType: item.order.assetType,
            makerFee: item.order.makerFee,
            salt: item.order.salt
        }
        const exchange: Exchange = {
            index: index,
            proof: item.exchange.proof,
            listing: { ...item.exchange.listing, price: item.exchange.listing.price.toString() },
            taker: item.exchange.taker
        }
        raw_signature.push(item.order.signature)
        res.orders.push(order)
        res.exchanges.push(exchange)
    })

    res.signatures = hexConcat(raw_signature as string[]);

    if (orderType == OrderType.BID) {
        delete res.tokenRecipient
    }

    if (createOrderAndSigResponses.length > 1) {
        return res
    } else {
        if (orderType == OrderType.ASK) {
            return {
                order: res.orders[0],
                exchange: res.exchanges[0],
                takerFee: res.takerFee,
                signature: res.signatures,
                tokenRecipient: res.tokenRecipient
            }
        } else {
            return {
                order: res.orders[0],
                exchange: res.exchanges[0],
                takerFee: res.takerFee,
                signature: res.signatures
            }
        }

    }

}