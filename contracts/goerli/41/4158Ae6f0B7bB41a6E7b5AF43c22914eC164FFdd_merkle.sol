// license: MIT

pragma solidity ^0.6.2;


contract merkle  {
    
    function buildRoot(bytes32[] memory addresses) public pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(addresses[i]));
        }
        return buildRootFromLeaves(leaves);
    }

    function buildRootFromLeaves(bytes32[] memory leaves) private pure returns (bytes32) {
        if (leaves.length == 0) {
            return 0x0;
        }
        if (leaves.length == 1) {
            return leaves[0];
        }
        if (leaves.length % 2 == 1) {
            bytes32[] memory tmp = new bytes32[](leaves.length + 1);
            for (uint i = 0; i < leaves.length; i++) {
                tmp[i] = leaves[i];
            }
            tmp[leaves.length] = leaves[leaves.length - 1];
            leaves = tmp;
        }
        bytes32[] memory parents = new bytes32[](leaves.length / 2);
        for (uint i = 0; i < leaves.length; i += 2) {
            parents[i / 2] = keccak256(abi.encodePacked(leaves[i], leaves[i + 1]));
        }
        return buildRootFromLeaves(parents);
    }

    function verifyRoot(bytes32 root, bytes32[] memory proof) public pure returns (bool) {
        bytes32 computedHash = root;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
    
}