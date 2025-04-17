// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 62
contract CASPApplicationRegistry {
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct Application {
        address applicantAddress;
        string memberState;
        string legalName;
        bool isSubmitted;
        bool isApproved;
        uint256 submissionDate;
        mapping(string => bytes32) documents; // e.g., "EntityID" -> hash
        mapping(CryptoService => bytes32) serviceDocs; // Service-specific docs
        bytes32 managementProof;
        bytes32 shareholderProof;
    }

    struct ExemptEntity {
        bool isNotified;
    }

    mapping(address => Application) public applications;
    mapping(address => bool) public ncAuthority;
    mapping(address => ExemptEntity) public exemptEntities; // Article 60 exemptions

    event ApplicationSubmitted(address indexed applicant, string memberState, string legalName);
    event DocumentsSubmitted(address indexed applicant, string docType, bytes32 docHash);
    event DocumentsReused(address indexed applicant, string docType, bytes32 docHash);
    event FitAndProperSubmitted(address indexed applicant);
    event ApplicationApproved(address indexed applicant);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Who Must Apply
    function submitApplication(
        address _applicantAddress,
        string memory _memberState,
        string memory _legalName
    ) external onlyNCA {
        require(!applications[_applicantAddress].isSubmitted, "Application already submitted");
        require(!isExemptEntity(_applicantAddress), "Entity exempt under Article 60");
        require(bytes(_memberState).length > 0, "Must specify EU Member State");

        Application storage app = applications[_applicantAddress];
        app.applicantAddress = _applicantAddress;
        app.memberState = _memberState;
        app.legalName = _legalName;
        app.isSubmitted = true;
        app.isApproved = false;
        app.submissionDate = block.timestamp;

        emit ApplicationSubmitted(_applicantAddress, _memberState, _legalName);
    }

    // Paragraph 2: Required Documents
    function submitDocuments(
        address _applicantAddress,
        string memory _docType,
        bytes32 _docHash,
        CryptoService[] memory _services
    ) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isSubmitted, "Application not submitted");
        
        app.documents[_docType] = _docHash;
        if (keccak256(abi.encodePacked(_docType)) == keccak256(abi.encodePacked("ServiceSpecific"))) {
            for (uint i = 0; i < _services.length; i++) {
                app.serviceDocs[_services[i]] = _docHash;
            }
        }
        emit DocumentsSubmitted(_applicantAddress, _docType, _docHash);
    }

    function areDocumentsComplete(address _applicantAddress) public view returns (bool) {
        Application storage app = applications[_applicantAddress];
        return app.documents["EntityID"] != bytes32(0) &&
               app.documents["BusinessOps"] != bytes32(0) &&
               app.documents["Governance"] != bytes32(0) &&
               app.documents["RiskManagement"] != bytes32(0) &&
               app.documents["ClientProtection"] != bytes32(0);
    }

    // Paragraph 3: Fit-and-Proper Checks
    function submitFitAndProperProof(
        address _applicantAddress,
        bytes32 _managementProof,
        bytes32 _shareholderProof
    ) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isSubmitted, "Application not submitted");
        
        app.managementProof = _managementProof;
        app.shareholderProof = _shareholderProof;
        emit FitAndProperSubmitted(_applicantAddress);
    }

    // Paragraph 4: Avoid Duplicate Submissions
    function reuseDocuments(
        address _applicantAddress,
        string memory _docType,
        bytes32 _existingDocHash
    ) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isSubmitted, "Application not submitted");
        require(_existingDocHash != bytes32(0), "Invalid document hash");
        
        app.documents[_docType] = _existingDocHash;
        emit DocumentsReused(_applicantAddress, _docType, _existingDocHash);
    }

    // Paragraphs 5-6: ESMA’s Role
    function getApplicationDetails(address _applicantAddress) public view returns (
        string memory memberState,
        string memory legalName,
        bool isSubmitted,
        bool isApproved,
        uint256 submissionDate
    ) {
        Application storage app = applications[_applicantAddress];
        return (
            app.memberState,
            app.legalName,
            app.isSubmitted,
            app.isApproved,
            app.submissionDate
        );
    }

    // Approval (Links to Article 63)
    function approveApplication(address _applicantAddress) external onlyNCA {
        Application storage app = applications[_applicantAddress];
        require(app.isSubmitted, "Application not submitted");
        require(block.timestamp <= app.submissionDate + 90 days, "3-month review period expired");
        require(areDocumentsComplete(_applicantAddress), "Documents incomplete");
        require(app.managementProof != bytes32(0) && app.shareholderProof != bytes32(0), 
            "Fit-and-proper proof missing");
        
        app.isApproved = true;
        emit ApplicationApproved(_applicantAddress);
    }

    function isExemptEntity(address _entity) public view returns (bool) {
        return exemptEntities[_entity].isNotified;
    }
}