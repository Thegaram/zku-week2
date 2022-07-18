pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    component cr;
    component hash[2 ** (n - 1)];

    if (n == 0) {
        root <== leaves[0];
    }
    else {
        cr = CheckRoot(2 ** (n - 1));

        for (var ii = 0; ii < 2 ** (n - 1); ii++) {
            hash[ii] = Poseidon(2);
            hash[ii].inputs[0] <== leaves[2 * ii];
            hash[ii].inputs[1] <== leaves[2 * ii + 1];
            cr.leaves[ii] <== hash[ii].out;
        }

        root <== cr.root;
    }
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component hash[n];
    signal level[n + 1];
    signal temp[2 * n];

    level[0] <== leaf;

    for (var ii = 0; ii < n; ii++) {
        hash[ii] = Poseidon(2);

        temp[2 * ii] <== (1 - path_index[ii]) * level[ii];
        hash[ii].inputs[0] <== temp[2 * ii] + path_index[ii] * path_elements[ii];

        temp[2 * ii + 1] <== (1 - path_index[ii]) * path_elements[ii];
        hash[ii].inputs[1] <== temp[2 * ii + 1] + path_index[ii] * level[ii];

        level[ii + 1] <== hash[ii].out;
    }

    root <== level[n];
}
