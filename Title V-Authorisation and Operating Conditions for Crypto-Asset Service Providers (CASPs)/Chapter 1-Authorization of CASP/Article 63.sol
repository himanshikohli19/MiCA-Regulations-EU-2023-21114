// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 63
contract CASPAuthorizationAssessment {
    struct Application {
        address applicantAddress;
        uint256 submissionDate;
        bool isAcknowledged;
        uint256 acknowledgmentDate;
        bool isComplete;
        uint256 completenessDate;
        bool isApproved;
        bool isRejected;
        string rejectionReason;
        bool isSuspended;
        uint256 suspensionDate;
        bool missingInfoRequested;
        bytes32 consultationResult;
        bytes32 amlProof;
        bool hasCloseLinksIssue;
        bytes32 managementProof;
        bytes32 shareholderProof;
        uint256 decisionDate;
        bool esmaNotified;
    }

    mapping(address => Application) public applications;
    mapping(address => mapping(string => bytes32)) public documents;
    mapping(address => bool) public ncAuthority;

    event ReceiptAcknowledged(address indexed applicant);
    event CompletenessConfirmed(address indexed applicant);
    event MissingInfoRequested(address indexed applicant);
    event ConsultationSubmitted(address indexed applicant);
    event AMLCheckSubmitted(address indexed applicant);
    event CloseLinksIssueFlagged(address indexed applicant, string reason);
    event AdditionalInfoRequested(address indexed applicant, string docType);
    event AdditionalInfoSubmitted(address indexed applicant, string docType);
    event ApplicationApproved(address indexed applicant);
    event ApplicationRejected(address indexed applicant, string reason);
    event ESMANotified(address indexed applicant, bool approved);
    event ManagementProofSubmitted(address indexed applicant);
    event ShareholderProofSubmitted(address indexed applicant);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    function submitApplication(address _applicantAddress) external onlyNCA {
        require(_applicantAddress != address(0), "Invalid applicant address");
        require(applications[_applicantAddress].submissionDate == 0, "Application already submitted");
        
        applications[_applicantAddress] = Application({
            applicantAddress: _applicantAddress,
            submissionDate: block.timestamp,
            isAcknowledged: false,
            acknowledgmentDate: 0,
            isComplete: false,
            completenessDate: 0,
            isApproved: false,
            isRejected: false,
            rejectionReason: "",
            isSuspended: false,
            suspensionDate: 0,
            missingInfoRequested: false,
            consultationResult: bytes32(0),
            amlProof: bytes32(0),
            hasCloseLinksIssue: false,
            managementProof: bytes32(0),
            shareholderProof: bytes32(0),
            decisionDate: 0,
            esmaNotified: false
        });
    }

    function acknowledgeReceipt(address _applicantAddress) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.submissionDate > 0, "Application not submitted");
        require(block.timestamp <= app.submissionDate + 5 days, "Acknowledgment period expired");
        
        app.isAcknowledged = true;
        app.acknowledgmentDate = block.timestamp;
        emit ReceiptAcknowledged(_applicantAddress);
    }

    function checkCompleteness(address _applicantAddress) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isAcknowledged, "Receipt not acknowledged");
        require(block.timestamp <= app.submissionDate + 25 days, "Completeness check period expired");

        if (areDocumentsComplete(_applicantAddress)) {
            app.isComplete = true;
            app.completenessDate = block.timestamp;
            emit CompletenessConfirmed(_applicantAddress);
        } else {
            app.missingInfoRequested = true;
            emit MissingInfoRequested(_applicantAddress);
        }
    }

    function areDocumentsComplete(address _applicantAddress) internal view returns (bool) {
        return documents[_applicantAddress]["EntityID"] != bytes32(0) &&
               documents[_applicantAddress]["BusinessOps"] != bytes32(0) &&
               documents[_applicantAddress]["Governance"] != bytes32(0) &&
               documents[_applicantAddress]["RiskManagement"] != bytes32(0) &&
               documents[_applicantAddress]["ClientProtection"] != bytes32(0);
    }

    function submitManagementProof(address _applicantAddress, bytes32 _proof) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isComplete, "Application not complete");
        
        app.managementProof = _proof;
        emit ManagementProofSubmitted(_applicantAddress);
    }

    function submitShareholderProof(address _applicantAddress, bytes32 _proof) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isComplete, "Application not complete");
        
        app.shareholderProof = _proof;
        emit ShareholderProofSubmitted(_applicantAddress);
    }

    function approveApplication(address _applicantAddress) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isComplete, "Application not complete");
        require(block.timestamp <= app.completenessDate + 40 days, "Review period expired");
        require(app.amlProof != bytes32(0), "AML proof missing");
        require(!app.hasCloseLinksIssue, "Close links issue detected");
        require(app.managementProof != bytes32(0), "Management proof missing");
        require(app.shareholderProof != bytes32(0), "Shareholder proof missing");

        app.isApproved = true;
        app.decisionDate = block.timestamp;
        emit ApplicationApproved(_applicantAddress);
    }

    function notifyESMA(address _applicantAddress) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.decisionDate > 0, "No decision made");
        require(!app.esmaNotified, "Already notified ESMA");
        require(block.timestamp <= app.decisionDate + 2 days, "Notification period expired");

        app.esmaNotified = true;
        emit ESMANotified(_applicantAddress, app.isApproved);
    }


}