// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 79
contract CASPPlacementRegistry {
    struct PlacementAgreement {
        address issuerAddress;
        bytes32 disclosureHash;  // Hash of type, fees, timing, pricing, purchasers
        bytes32 consentHash;     // Hash of issuer's written consent
        uint256 submissionDate;
    }

    struct ConflictPolicy {
        bytes32 policyHash;  // Hash of conflict management procedures
        uint256 submissionDate;
    }

    struct ConflictDisclosure {
        bytes32 conflictHash;  // Hash of specific conflict details
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        mapping(bytes32 => PlacementAgreement) placementAgreements;
        ConflictPolicy conflictPolicy;
        mapping(bytes32 => ConflictDisclosure) conflictDisclosures;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event PlacementAgreementSubmitted(address indexed casp, address indexed issuer, bytes32 placementId);
    event ConflictPolicySubmitted(address indexed casp);
    event ConflictDisclosureSubmitted(address indexed casp, bytes32 placementId);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
    }

    // Paragraph 1: Mandatory Pre-Agreement Disclosures
    function submitPlacementAgreement(
        address _caspAddress,
        address _issuerAddress,
        bytes32 _disclosureHash,
        bytes32 _consentHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        bytes32 placementId = keccak256(abi.encodePacked(_caspAddress, _issuerAddress, block.timestamp));
        casps[_caspAddress].placementAgreements[placementId] = PlacementAgreement({
            issuerAddress: _issuerAddress,
            disclosureHash: _disclosureHash,
            consentHash: _consentHash,
            submissionDate: block.timestamp
        });
        emit PlacementAgreementSubmitted(_caspAddress, _issuerAddress, placementId);
    }

    // Paragraph 2: Conflict-of-Interest Management (Policy)
    function submitConflictPolicy(
        address _caspAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].conflictPolicy = ConflictPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp
        });
        emit ConflictPolicySubmitted(_caspAddress);
    }

    // Paragraph 2: Conflict-of-Interest Management (Disclosure)
    function submitConflictDisclosure(
        address _caspAddress,
        bytes32 _placementId,
        bytes32 _conflictHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        PlacementAgreement storage agreement = casps[_caspAddress].placementAgreements[_placementId];
        require(agreement.submissionDate > 0, "Placement not found");
        casps[_caspAddress].conflictDisclosures[_placementId] = ConflictDisclosure({
            conflictHash: _conflictHash,
            submissionDate: block.timestamp
        });
        emit ConflictDisclosureSubmitted(_caspAddress, _placementId);
    }
}