const { poseidonContract } = require("circomlibjs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { groth16 } = require("snarkjs");

describe("MerkleTree", function () {
    let merkleTree;

    beforeEach(async function () {

        const PoseidonT3 = await ethers.getContractFactory(
            poseidonContract.generateABI(2),
            poseidonContract.createCode(2)
        )
        const poseidonT3 = await PoseidonT3.deploy();
        await poseidonT3.deployed();

        const MerkleTree = await ethers.getContractFactory("MerkleTree", {
            libraries: {
                PoseidonT3: poseidonT3.address
            },
          });
        merkleTree = await MerkleTree.deploy();
        await merkleTree.deployed();
    });

    it("Insert two new leaves and verify the first leaf in an inclusion proof", async function () {
        await merkleTree.insertLeaf(1);
        await merkleTree.insertLeaf(2);

        const node9 = (await merkleTree.hashes(9)).toString();
        const node13 = (await merkleTree.hashes(13)).toString();

        const Input = {
            "leaf": "1",
            "path_elements": ["2", node9, node13],
            "path_index": ["0", "0", "0"]
        }
        let { proof, publicSignals } = await groth16.fullProve(Input, "circuits/circuit_js/circuit.wasm","circuits/circuit_final.zkey");

        let calldata = await groth16.exportSolidityCallData(proof, publicSignals);
    
        let argv = calldata.replace(/["[\]\s]/g, "").split(',').map(x => BigInt(x).toString());
    
        let a = [argv[0], argv[1]];
        let b = [[argv[2], argv[3]], [argv[4], argv[5]]];
        let c = [argv[6], argv[7]];
        let input = argv.slice(8);

        expect(await merkleTree.verify(a, b, c, input)).to.be.true;

        // [bonus] verify the second leaf with the inclusion proof

        const Input2 = {
            "leaf": "2",
            "path_elements": ["1", node9, node13],
            "path_index": ["1", "0", "0"]
        };

        ({ proof, publicSignals } = await groth16.fullProve(Input2, "circuits/circuit_js/circuit.wasm","circuits/circuit_final.zkey"));

        calldata = await groth16.exportSolidityCallData(proof, publicSignals);

        argv = calldata.replace(/["[\]\s]/g, "").split(',').map(x => BigInt(x).toString());

        a = [argv[0], argv[1]];
        b = [[argv[2], argv[3]], [argv[4], argv[5]]];
        c = [argv[6], argv[7]];
        input = argv.slice(8);

        expect(await merkleTree.verify(a, b, c, input)).to.be.true;
    });
});
