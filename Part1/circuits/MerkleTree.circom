pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var totalLeaves = 2**n; // total leaves
    var nLeavesHashes = totalLeaves/2; // number of hashes from leaves in level 0
    var nIntermediateHashes = nLeavesHashes - 1; // number of intermediate hashes

    component computedHash[totalLeaves - 1];
    //calculate hashes from leaves (level 0 of the tree)
    for (var i = 0; i < nLeavesHashes ; i++) {
        computedHash[i] = Poseidon(2);
        computedHash[i].inputs[0] <== leaves[i*2];
        computedHash[i].inputs[1] <== leaves[i*2+1];
    }

    var j = 0;
    //calculate intermediate hashes going up in the tree (from level 1 to the root)
    for (var i = nLeavesHashes; i < nLeavesHashes + nIntermediateHashes; i++) {
        computedHash[i] = Poseidon(2);
        computedHash[i].inputs[0] <== computedHash[j*2].out;
        computedHash[i].inputs[1] <== computedHash[j*2+1].out;
        j++;
    }
    
    // out Merkle root
    root <== computedHash[totalLeaves - 1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component computedHash[n]; // computed hash for each level
    component mux[n]; // multiplexer for selecting in function of path_index[i] (0,1)

    signal levelHashes[n+1]; // hashes for computing the merkle root
    levelHashes[0] <== leaf;

    for(var i=0; i<n; i++){
        computedHash[i] = Poseidon(2); // poseidon component for computing the hash
        mux[i] = MultiMux1(2); // multiplexer component for selecting depending on path_index[i] (0,1)

        // path_index[i] = 0
        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== path_elements[i];

        // path_index[i] = 1
        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== levelHashes[i];

        mux[i].s <== path_index[i]; // select option

        // poseidon computed hash of the parent
        computedHash[i].inputs[0] <== mux[i].out[0];
        computedHash[i].inputs[1] <== mux[i].out[1];

        // update the hash of the parent
        levelHashes[i+1] <== computedHash[i].out;        
    }

    // out Merkle root
    root <== levelHashes[n];
}