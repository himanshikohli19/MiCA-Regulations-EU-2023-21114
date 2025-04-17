// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 68
contract CASPGovernanceRegistry {
    struct Governance {
        bytes32 managementReputeHash;
        bytes32 shareholderReputeHash;
        uint256 submissionDate;
    }

    struct InfluenceMeasure {
        bool isVotingSuspended;
        string reason;
        uint256 actionDate;
    }

    struct CompliancePolicies {
        bytes32 policyHash;
        uint256 lastReviewDate;
        uint256 submissionDate;
    }

    struct BusinessContinuity {
        bytes32 continuityPlanHash;
        uint256 submissionDate;
    }

    struct RiskManagement {
        bytes32 riskManagementHash;
        uint256 submissionDate;
    }

    struct Record {
        bytes32 recordHash;
        uint256 submissionDate;
        uint256 expirationDate;
    }

    struct CASP {
        bool isAuthorized;
        Governance governance;
        mapping(address => InfluenceMeasure) influenceMeasures;
        CompliancePolicies compliancePolicies;
        BusinessContinuity businessContinuity;
        RiskManagement riskManagement;
        Record[] records;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public ncAuthority;
    address public esmaAuthority;
    bytes32 public rtsStandardsHash;

    event ManagementAndShareholdersRegistered(address indexed casp);
    event InfluenceMeasureApplied(address indexed casp, address indexed shareholder, bool suspendVoting, string reason);
    event CompliancePoliciesSubmitted(address indexed casp, uint256 lastReviewDate);
    event BusinessContinuityPlanSubmitted(address indexed casp);
    event RiskManagementSubmitted(address indexed casp);
    event RecordSubmitted(address indexed casp, bytes32 recordHash);
    event RecordRetentionExtended(address indexed casp, uint256 recordIndex);
    event RTSStandardsUpdated(bytes32 rtsHash);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    modifier onlyESMA() {
        require(msg.sender == esmaAuthority, "Only ESMA can call this function");
        _;
    }

    constructor(address[] memory _casps, address[] memory _ncas, address _esma) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
        esmaAuthority = _esma;
    }

    // Paragraphs 1 & 2: Management Body Requirements
    function registerManagementAndShareholders(
        address _caspAddress,
        bytes32 _managementReputeHash,
        bytes32 _shareholderReputeHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].governance = Governance({
            managementReputeHash: _managementReputeHash,
            shareholderReputeHash: _shareholderReputeHash,
            submissionDate: block.timestamp
        });
        emit ManagementAndShareholdersRegistered(_caspAddress);
    }

    // Paragraph 3: Measures Against Harmful Influence
    function applyInfluenceMeasure(
        address _caspAddress,
        address _shareholderAddress,
        bool _suspendVoting,
        string memory _reason
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].influenceMeasures[_shareholderAddress] = InfluenceMeasure({
            isVotingSuspended: _suspendVoting,
            reason: _reason,
            actionDate: block.timestamp
        });
        emit InfluenceMeasureApplied(_caspAddress, _shareholderAddress, _suspendVoting, _reason);
    }

    // Paragraphs 4-6: Compliance Policies & Procedures
    function submitCompliancePolicies(
        address _caspAddress,
        bytes32 _policyHash,
        uint256 _lastReviewDate
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].compliancePolicies = CompliancePolicies({
            policyHash: _policyHash,
            lastReviewDate: _lastReviewDate,
            submissionDate: block.timestamp
        });
        emit CompliancePoliciesSubmitted(_caspAddress, _lastReviewDate);
    }

    // Paragraph 7: Business Continuity & ICT Security
    function submitBusinessContinuityPlan(
        address _caspAddress,
        bytes32 _continuityPlanHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].businessContinuity = BusinessContinuity({
            continuityPlanHash: _continuityPlanHash,
            submissionDate: block.timestamp
        });
        emit BusinessContinuityPlanSubmitted(_caspAddress);
    }

    // Paragraphs 8-9: Risk Management & Record-Keeping
    function submitRiskManagement(
        address _caspAddress,
        bytes32 _riskManagementHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].riskManagement = RiskManagement({
            riskManagementHash: _riskManagementHash,
            submissionDate: block.timestamp
        });
        emit RiskManagementSubmitted(_caspAddress);
    }

    function submitRecord(
        address _caspAddress,
        bytes32 _recordHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].records.push(Record({
            recordHash: _recordHash,
            submissionDate: block.timestamp,
            expirationDate: block.timestamp + 5 * 365 days
        }));
        emit RecordSubmitted(_caspAddress, _recordHash);
    }

    function extendRecordRetention(
        address _caspAddress,
        uint256 _recordIndex
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        Record storage record = casps[_caspAddress].records[_recordIndex];
        record.expirationDate += 2 * 365 days; // Extend to 7 years
        emit RecordRetentionExtended(_caspAddress, _recordIndex);
    }

    // Paragraph 10: ESMA’s RTS
    function updateRTSStandards(bytes32 _rtsHash) external onlyESMA {
        rtsStandardsHash = _rtsHash;
        emit RTSStandardsUpdated(_rtsHash);
    }
}