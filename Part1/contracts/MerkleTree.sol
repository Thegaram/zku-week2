//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        uint256[2] memory input;
        uint256 output;

        // level 3
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);
        hashes.push(0);

        // level 2
        input[0] = 0;
        input[1] = 0;
        output = PoseidonT3.poseidon(input);

        hashes.push(output);
        hashes.push(output);
        hashes.push(output);
        hashes.push(output);

        // level 1
        input[0] = output;
        input[1] = output;
        output = PoseidonT3.poseidon(input);

        hashes.push(output);
        hashes.push(output);

        input[0] = output;
        input[1] = output;
        output = PoseidonT3.poseidon(input);

        // level 0
        hashes.push(output);
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree

        require(index < 8);

        uint256[2] memory input;
        uint256 currentIndex = index++;

        // insert leaf
        hashes[currentIndex] = hashedLeaf;

        // recalculate hashes along path to root
        while (currentIndex < 14) {
            input[0] = hashes[currentIndex - (currentIndex % 2)];
            input[1] = hashes[currentIndex + 1 - (currentIndex % 2)];
            currentIndex = 8 + currentIndex / 2;
            hashes[currentIndex] = PoseidonT3.poseidon(input);
        }

        root = hashes[14];
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return input[0] == root && super.verifyProof(a, b, c, input);
    }
}
