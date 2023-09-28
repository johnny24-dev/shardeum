import { BigNumber } from "ethers"

export interface Order {
    trader: string // 0x00
    collection: string // 0x20
    listingsRoot: string // 0x40
    numberOfListings: number // 0x60
    expirationTime: BigInt | string // 0x80
    assetType: number // 0xa0
    makerFee: FeeRate; // 0xc0
    salt: string // 0xe0
    
}

export interface FeeRate {
    recipient: string // 0x00
    rate: number // 0x20
}

export interface Taker {
    tokenId: number // 0x00
    amount: number // 0x20
}

export interface Exchange {
    index: number // 0x00
    proof: string[] // 0x20
    listing: Listing // 0x40
    taker: Taker // 0x60
}

export interface Listing {
    index: number // 0x00
    tokenId: number // 0x20
    amount: number // 0x40
    price: BigInt | string // 0x60
}


export interface CreateOrderInput {
    trader: string // 0x00
    collection: string // 0x20
    numberOfListings: number // 0x60
    expirationTime?: BigInt | string // 0x80
    assetType: number // 0xa0
    makerFee?: FeeRate // 0xc0
    salt?: string // 0xe0
    nonce: number // default is 0, get from contract for user
    tokenId: number // 0x20
    amount: number // 0x40
    price: BigInt // 0x60
}

export interface CreateCollectionOfferInput {
    trader: string // 0x00
    collection: string // 0x20
    numberOfListings: number // 0x60
    expirationTime?: BigInt | string // 0x80
    assetType: number // 0xa0
    makerFee?: FeeRate // 0xc0
    salt?: string // 0xe0
    nonce: number // default is 0, get from contract for user
    pricePerItem: BigInt // 0x60
}


export interface OrderDetail extends Order {
    orderHash?: string
    signature?:string
}

export interface CollectionOfferDetail extends Order {
    colectionOfferHash:string
    signature:string
    pricePerItem:BigInt | string
}

export interface CreateOrderResponse {
    orders: OrderDetail[]
    exchanges: any[]
    takerFee: FeeRate
    tokenRecipient?: string
    signatures: string
}

export interface CreateOrderAndSignResponse {
    order:OrderDetail,
    exchange:Exchange,
    takerFee:FeeRate
}

export interface CreateCollectionOfferResponse {
    order:OrderDetail,
    listing:Listing,
    takerFee:FeeRate,
    signature?: string
}


export enum AssetType {
    ERC721,
    ERC1155
}

export enum OrderType {
    ASK,
    BID,
    OFFER_COLLECTION
}