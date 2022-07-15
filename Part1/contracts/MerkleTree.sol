//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256 public constant TREE_HEIGHT = 3;
    uint256 public constant TREE_WIDTH = 2**TREE_HEIGHT;
    uint256 public constant NUM_NODES = 15;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        // First we insert the leaves
        for (uint256 i = 0; i < TREE_WIDTH; i++) {
            hashes.push(0);
        }

        uint256 currentPosition = 0;
        //calculate hashes from level 1 to root
        for (uint256 i = TREE_WIDTH; i < NUM_NODES; i++) {
            hashes.push(
                PoseidonT3.poseidon(
                    [hashes[currentPosition], hashes[currentPosition + 1]]
                )
            );
            currentPosition += 2;
        }

        // the root is the last hash
        root = hashes[hashes.length - 1];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < TREE_WIDTH, "There is no space in the merkle tree");

        uint256 currentPosition = index;
        uint256 computedHash;

        hashes[index] = hashedLeaf; // assign hashed leave

        for (uint256 level = 0; level < TREE_HEIGHT; level++) {
            if (currentPosition % 2 == 0) {
                computedHash = PoseidonT3.poseidon(
                    [hashes[currentPosition], hashes[currentPosition + 1]]
                );
                currentPosition = (currentPosition / 2) + TREE_WIDTH; // next level of the merkle tree
            } else {
                computedHash = PoseidonT3.poseidon(
                    [hashes[currentPosition - 1], hashes[currentPosition]]
                );
                currentPosition = ((currentPosition - 1) / 2) + TREE_WIDTH; // next level of the merkle tree
            }

            hashes[currentPosition] = computedHash; // store the value computedHash in parent level
        }

        // last computedHash is the root of the tree
        root = computedHash;
        index++; // new empty leaf available

        return root; // root of the tree
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        bool checkProof = verifyProof(a, b, c, input);
        return (root == input[0] && checkProof);
    }
}
