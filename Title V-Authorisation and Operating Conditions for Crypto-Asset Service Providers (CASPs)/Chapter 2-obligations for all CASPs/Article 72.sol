// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 72
contract CASPConflictRegistry {
    struct ConflictPolicy {
        bytes32 policyHash;  // Hash of written conflict policy
        uint256 submissionDate;
        uint256 lastReviewDate;
    }

    struct ConflictDisclosure {
        bytes32 disclosureHash;  // Hash of conflicts and mitigation measures
        string disclosureUrl;    // Website URL for public access
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        ConflictPolicy conflictPolicy;
        ConflictDisclosure conflictDisclosure;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;
    bytes32 public rtsStandardsHash;

    event ConflictPolicySubmitted(address indexed casp);
    event ConflictDisclosureSubmitted(address indexed casp, string disclosureUrl);
    event ConflictPolicyUpdated(address indexed casp, uint256 reviewDate);
    event RTSStandardsUpdated(bytes32 rtsHash);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyESMA() {
        require(msg.sender == esmaAuthority, "Only ESMA can call this function");
        _;
    }

    constructor(address[] memory _casps, address _esma) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        esmaAuthority = _esma;
    }

    // Paragraph 1: Policies & Procedures to Manage Conflicts
    function submitConflictPolicy(
        address _caspAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].conflictPolicy = ConflictPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp,
            lastReviewDate: block.timestamp
        });
        emit ConflictPolicySubmitted(_caspAddress);
    }

    // Paragraphs 2 & 3: Public Disclosure of Conflicts
    function submitConflictDisclosure(
        address _caspAddress,
        bytes32 _disclosureHash,
        string memory _disclosureUrl
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].conflictDisclosure = ConflictDisclosure({
            disclosureHash: _disclosureHash,
            disclosureUrl: _disclosureUrl,
            submissionDate: block.timestamp
        });
        emit ConflictDisclosureSubmitted(_caspAddress, _disclosureUrl);
    }

    // Paragraph 4: Annual Review & Updates
    function updateConflictPolicy(
        address _caspAddress,
        bytes32 _newPolicyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        ConflictPolicy storage policy = casps[_caspAddress].conflictPolicy;
        require(policy.submissionDate > 0, "No initial policy submitted");
        require(block.timestamp >= policy.lastReviewDate + 365 days,
            "Annual review not yet due");
        policy.policyHash = _newPolicyHash;
        policy.lastReviewDate = block.timestamp;
        emit ConflictPolicyUpdated(_caspAddress, block.timestamp);
    }

    // Paragraph 5: ESMA’s RTS
    function updateRTSStandards(bytes32 _rtsHash) external onlyESMA {
        rtsStandardsHash = _rtsHash;
        emit RTSStandardsUpdated(_rtsHash);
    }
}