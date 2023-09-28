import { Wallet, ethers } from 'ethers';


import artifact from './ZeZuExchange.json';
import { AssetType, CreateCollectionOfferInput, CreateOrderInput, Exchange, FeeRate, Listing, Order, OrderType } from '../types';
import { CONTRACT_ADDRESS, DOMAIN, EIP_712_OFFER_COLLECTION_TYPE, EIP_712_ORDER_TYPE } from '../constants';
import { _formatOrderResponse, createCollectionOfferAndSign, createOrdersAndSignOrders } from '../eip712/orderHash';
import { bufferToHex, hashConcat } from '../eip712/utils';
import { _TypedDataEncoder, defaultAbiCoder, hexConcat, keccak256 } from 'ethers/lib/utils';


const bulkOrders = async () => {

    // for list nft
    const provider = new ethers.providers.JsonRpcProvider('https://dapps.shardeum.org');
    const signer = new Wallet('', provider);

    // for buy nft
    const signer2 = new Wallet('', provider);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, artifact.abi, signer2);

    const orderInputs: CreateOrderInput[] = [
        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 3, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 1, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // },
        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 3, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 2, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // },
        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 3, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 3, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // },

        {
            trader: signer.address, // 0x00
            collection: "0x03da067737c70b159e115c588640953391d2253c", // 0x20
            numberOfListings: 1, // 0x60
            expirationTime: undefined, // 0x80
            assetType: AssetType.ERC721, // 0xa0
            makerFee: undefined, // 0xc0
            salt: undefined,// 0xe0
            nonce: 0, // default is 0, get from contract for user
            tokenId: 2, // 0x20
            amount: 1, // 0x40
            price: BigInt('1000000000000000000') // 0x60
        }
    ]

    const ordersResponse = await createOrdersAndSignOrders(signer, orderInputs, OrderType.ASK);
    // console.log("🚀 ~ file: test_order_hash.ts:192 ~ bulkOrders ~ ordersResponse:", ordersResponse)
    
    const takeAsk:any = _formatOrderResponse(ordersResponse, signer2.address, OrderType.ASK);
    console.log("🚀 ~ file: test_order_hash.ts:194 ~ bulkOrders ~ takeAsk:", takeAsk)

    // for bulk
    // const tx = await contract.takeAsk(takeAsk, { value:'300000000'})
    // const res_tx = await tx.wait()
    // console.log("🚀 ~ file: test_order_hash.ts:201 ~ bulkOrders ~ tx:", res_tx)

    // for single
    const tx_takeSingle = await contract.takeAskSingle(takeAsk, { value: '1000000000000000000', gasLimit:'3000000' })
    const resr_tx_takeSingle = await tx_takeSingle.wait();
    console.log("🚀 ~ file: test_order_hash.ts:146 ~ takeOrder ~ resr_tx_takeSingle:", resr_tx_takeSingle)
}


const bulkBids = async () => {


    const provider = new ethers.providers.JsonRpcProvider('https://goerli.blockpi.network/v1/rpc/public');
    const signer = new Wallet('', provider);

    // for accept bid
    const signer2 = new Wallet('', provider);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, artifact.abi, signer2);

    const orderInputs: CreateOrderInput[] = [
        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 3, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 1, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // },
        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 3, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 2, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // },
        {
            trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
            collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
            numberOfListings: 1, // 0x60
            expirationTime: undefined, // 0x80
            assetType: AssetType.ERC721, // 0xa0
            makerFee: undefined, // 0xc0
            salt: undefined,// 0xe0
            nonce: 0, // default is 0, get from contract for user
            tokenId: 5, // 0x20
            amount: 1, // 0x40
            price: BigInt('100000000') // 0x60
        },

        // {
        //     trader: "0x41E13C809E6DfB4De936c1180E66b17798B6a91a", // 0x00
        //     collection: "0x9AA1eB2D3F298918375521e1442A6F797d78B9d3", // 0x20
        //     numberOfListings: 1, // 0x60
        //     expirationTime: undefined, // 0x80
        //     assetType: AssetType.ERC721, // 0xa0
        //     makerFee: undefined, // 0xc0
        //     salt: undefined,// 0xe0
        //     nonce: 0, // default is 0, get from contract for user
        //     tokenId: 4, // 0x20
        //     amount: 1, // 0x40
        //     price: BigInt('100000000') // 0x60
        // }
    ]

    const ordersResponse = await createOrdersAndSignOrders(signer, orderInputs, OrderType.BID);
    // console.log("🚀 ~ file: test_order_hash.ts:192 ~ bulkOrders ~ ordersResponse:", ordersResponse)
    const takeBid = _formatOrderResponse(ordersResponse, '', OrderType.BID);
    console.log("🚀 ~ file: test_order_hash.ts:164 ~ bulkBids ~ takeBid:", takeBid)
    const tx_takeBid = await contract.takeBidSingle(takeBid)
    const res_tx_takeBid = await tx_takeBid.wait()
    console.log("🚀 ~ file: test_order_hash.ts:166 ~ bulkBids ~ res_tx_takeBid:", res_tx_takeBid)
}

const collectionOffer = async () => {
    const provider = new ethers.providers.JsonRpcProvider('https://goerli.blockpi.network/v1/rpc/public');
    const signer = new Wallet('', provider);

    // for accept bid
    const signer2 = new Wallet('', provider);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, artifact.abi, signer2);


    const input: CreateCollectionOfferInput = {
        trader: signer.address,
        collection: '0x9AA1eB2D3F298918375521e1442A6F797d78B9d3',
        numberOfListings: 1,
        assetType: AssetType.ERC721,
        nonce: 0,
        pricePerItem: BigInt('100000000')
    }

    const colectionOfferResponse = await createCollectionOfferAndSign(signer, input);
    console.log("🚀 ~ file: test_order_hash.ts:189 ~ collectionOffer ~ colectionOfferResponse:", colectionOfferResponse)

    const order: Order = {
        trader: colectionOfferResponse.trader,
        collection: colectionOfferResponse.collection,
        listingsRoot: colectionOfferResponse.listingsRoot,
        numberOfListings: colectionOfferResponse.numberOfListings,
        expirationTime: colectionOfferResponse.expirationTime.toString(),
        assetType: colectionOfferResponse.assetType,
        makerFee: colectionOfferResponse.makerFee,
        salt: colectionOfferResponse.salt
    }

    const order_fake = {
        trader: '0x41E13C809E6DfB4De936c1180E66b17798B6a91a',
        collection: '0x9AA1eB2D3F298918375521e1442A6F797d78B9d3',
        listingsRoot: '0x0000000000000000000000000000000000000000000000000000000000000000',
        numberOfListings: 1,
        expirationTime: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
        assetType: 0,
        makerFee: { rate: 0, recipient: '0x0000000000000000000000000000000000000000' },
        salt: '2417717211378636194',
        pricePerItem: '100000000',
        colectionOfferHash: '0x56fdcb5cafa22e6a17934dafd6703f6184fc303fd7adccfd065fa0e578d446c8',
        signature: '0x870068c5387a08bc9e8de0c506d75acf7724e265721bf480bbfd9734e78a44c31f252ad265da0e6a929730c8a81fe73fa75b2df8afd02ccffdcae3d8730e8e171c'
    }

    const hash = colectionOfferResponse.colectionOfferHash;

    const _hash = await contract.hashOfferCollection(order, OrderType.OFFER_COLLECTION, '100000000')
    // console.log("🚀 ~ file: test_order_hash.ts:205 ~ collectionOffer ~ _hash:", _hash)

    // console.log('check_hash', hash == _hash)

    const hash_to_sign = await contract._hashToSign(hash)
    // console.log("🚀 ~ file: test_order_hash.ts:208 ~ collectionOffer ~ hash_to_sign:", hash_to_sign)

    const hash_2 = _TypedDataEncoder.hashStruct('OfferColection', EIP_712_OFFER_COLLECTION_TYPE, {
        ...order,
        orderType: OrderType.OFFER_COLLECTION,
        nonce: 0,
        pricePerItem: '100000000'
    });
    // console.log("🚀 ~ file: test_order_hash.ts:215 ~ collectionOffer ~ hash_2:", hash_2)

    const premire_type = _TypedDataEncoder.getPrimaryType(EIP_712_OFFER_COLLECTION_TYPE)
    // console.log("🚀 ~ file: test_order_hash.ts:219 ~ collectionOffer ~ premire_type:", premire_type)

    const _hash_to_sign = _TypedDataEncoder.hash(DOMAIN, EIP_712_OFFER_COLLECTION_TYPE,
        {
            ...order,
            orderType: OrderType.OFFER_COLLECTION,
            nonce: 0,
            pricePerItem: '100000000'
        })
    // console.log("🚀 ~ file: test_order_hash.ts:214 ~ collectionOffer ~ _hash_to_sign:", _hash_to_sign)

    console.log('check_hash_sign', hash_to_sign == _hash_to_sign)


    // nft for accept
    const listing: Listing = {
        index: 0, // alaways is 0
        tokenId: 2,
        amount: 1,
        price: BigInt('100000000').toString()
    }

    const takerFee: FeeRate = {
        recipient: ethers.constants.AddressZero,
        rate: 0
    }

    const takeCollectionOffer = {
        order:order_fake,
        listing,
        takerFee,
        signature: colectionOfferResponse.signature
    }
    // console.log("🚀 ~ file: test_order_hash.ts:221 ~ collectionOffer ~ takeCollectionOffer:", takeCollectionOffer)


    // const tx_verify = await contract.verifyAuthorizationPublic(signer.address,hash,colectionOfferResponse.signature,0)
    // console.log("🚀 ~ file: test_order_hash.ts:244 ~ collectionOffer ~ tx_verify:", tx_verify)

    const tx_take = await contract.takeCollectionOffer(takeCollectionOffer)
    const res_tx_take = await tx_take.wait()
    console.log("🚀 ~ file: test_order_hash.ts:166 ~ bulkBids ~ res_tx_takeBid:", res_tx_take)


}

// collectionOffer()

// bulkBids()


bulkOrders()
