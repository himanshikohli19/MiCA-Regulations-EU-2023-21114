// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 71
contract CASPComplaintsRegistry {
    struct ComplaintsProcedure {
        bytes32 procedureHash;
        string disclosureUrl;
        uint256 submissionDate;
    }

    struct Complaint {
        address complainant;
        bytes32 complaintHash;
        uint256 submissionDate;
        uint256 resolutionDate;
        bytes32 outcomeHash;
        bool isResolved;
    }

    struct ComplaintAwareness {
        bytes32 templateHash;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        ComplaintsProcedure complaintsProcedure;
        Complaint[] complaints;
        ComplaintAwareness complaintAwareness;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;
    bytes32 public rtsStandardsHash;

    event ComplaintsProcedureSubmitted(address indexed casp, string disclosureUrl);
    event ComplaintFiled(address indexed casp, uint256 complaintId, address complainant);
    event ComplaintAwarenessSubmitted(address indexed casp);
    event ComplaintResolved(address indexed casp, uint256 complaintId, address complainant);
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

    // Paragraph 1: Mandatory Complaints-Handling Procedures
    function submitComplaintsProcedure(
        address _caspAddress,
        bytes32 _procedureHash,
        string memory _disclosureUrl
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].complaintsProcedure = ComplaintsProcedure({
            procedureHash: _procedureHash,
            disclosureUrl: _disclosureUrl,
            submissionDate: block.timestamp
        });
        emit ComplaintsProcedureSubmitted(_caspAddress, _disclosureUrl);
    }

    // Paragraph 2: Free Complaint Submission
    function fileComplaint(
        address _caspAddress,
        bytes32 _complaintHash
    ) external {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        uint256 complaintId = casps[_caspAddress].complaints.length;
        casps[_caspAddress].complaints.push(Complaint({
            complainant: msg.sender,
            complaintHash: _complaintHash,
            submissionDate: block.timestamp,
            resolutionDate: 0,
            outcomeHash: bytes32(0),
            isResolved: false
        }));
        emit ComplaintFiled(_caspAddress, complaintId, msg.sender);
    }

    // Paragraph 3: Complaint Awareness & Record-Keeping
    function submitComplaintAwareness(
        address _caspAddress,
        bytes32 _templateHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].complaintAwareness = ComplaintAwareness({
            templateHash: _templateHash,
            submissionDate: block.timestamp
        });
        emit ComplaintAwarenessSubmitted(_caspAddress);
    }

    // Paragraph 4: Fair & Timely Investigation
    function resolveComplaint(
        address _caspAddress,
        uint256 _complaintId,
        bytes32 _outcomeHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        Complaint storage complaint = casps[_caspAddress].complaints[_complaintId];
        require(complaint.submissionDate > 0, "Complaint not found");
        require(!complaint.isResolved, "Complaint already resolved");
        complaint.resolutionDate = block.timestamp;
        complaint.outcomeHash = _outcomeHash;
        complaint.isResolved = true;
        emit ComplaintResolved(_caspAddress, _complaintId, complaint.complainant);
    }

    // Paragraph 5: ESMA’s RTS
    function updateRTSStandards(bytes32 _rtsHash) external onlyESMA {
        rtsStandardsHash = _rtsHash;
        emit RTSStandardsUpdated(_rtsHash);
    }
}