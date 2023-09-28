import { concat, hexConcat, hexlify, keccak256, randomBytes, toUtf8Bytes } from "ethers/lib/utils";

import type { BytesLike } from "ethers";

export const makeArray = <T>(len: number, getValue: (i: number) => T) =>
  Array(len)
    .fill(0)
    .map((_, i) => getValue(i));

export const chunk = <T>(array: T[], size: number) => {
  return makeArray(Math.ceil(array.length / size), (i) =>
    array.slice(i * size, (i + 1) * size),
  );
};

export const bufferToHex = (buf: Buffer) => hexlify(buf);

export const hexToBuffer = (value: string) =>
  Buffer.from(value.slice(2), "hex");

export const bufferKeccak = (value: BytesLike) => hexToBuffer(keccak256(value));

export const hashConcat = (arr: BytesLike[]) => bufferKeccak(hexConcat(arr));

export const fillArray = <T>(arr: T[], length: number, value: T) => {
  if (length > arr.length) arr.push(...Array(length - arr.length).fill(value));
  return arr;
};

export const getRoot = (elements: (Buffer | string)[], hashLeaves = true) => {
  if (elements.length === 0) throw new Error("empty tree");

  const leaves = elements.map((e) => {
    const leaf = Buffer.isBuffer(e) ? e : hexToBuffer(e);
    return hashLeaves ? bufferKeccak(leaf) : leaf;
  });

  const layers: Buffer[][] = [leaves];

  // Get next layer until we reach the root
  while (layers[layers.length - 1].length > 1) {
    layers.push(getNextLayer(layers[layers.length - 1]));
  }

  return layers[layers.length - 1][0];
};

export const getNextLayer = (elements: Buffer[]) => {
  return chunk(elements, 2).map(hashConcat);
};

export const generateRandomSalt = (domain?: string) => {
  if (domain) {
    return `0x${Buffer.from(
      concat([
        keccak256(toUtf8Bytes(domain)).slice(0, 10),
        Uint8Array.from(Array(20).fill(0)),
        randomBytes(8),
      ]),
    ).toString("hex")}`;
  }
  return `0x${Buffer.from(randomBytes(8)).toString("hex").padStart(64, "0")}`;
};
