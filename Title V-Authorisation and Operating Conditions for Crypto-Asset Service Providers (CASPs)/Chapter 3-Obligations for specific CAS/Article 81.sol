// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 81
contract CASPAdvicePortfolioRegistry {
    struct SuitabilityAssessment {
        bytes32 assessmentHash;
        uint256 submissionDate;
    }

    struct AdviceDisclosure {
        bytes32 disclosureHash;
        uint256 submissionDate;
    }

    struct CostDisclosure {
        bytes32 costHash;
        uint256 submissionDate;
    }

    struct PortfolioConflictPolicy {
        bytes32 conflictHash;
        uint256 submissionDate;
    }

    struct AdvisorCompetency {
        bytes32 competencyHash;
        uint256 submissionDate;
    }

    struct RiskWarnings {
        bytes32 warningHash;
        uint256 submissionDate;
    }

    struct SuitabilityPolicy {
        bytes32 policyHash;
        uint256 submissionDate;
    }

    struct SuitabilityReport {
        bytes32 reportHash;
        uint256 submissionDate;
    }

    struct PortfolioStatement {
        bytes32 statementHash;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        mapping(address => SuitabilityAssessment) suitabilityAssessments;
        AdviceDisclosure adviceDisclosure;
        CostDisclosure costDisclosure;
        PortfolioConflictPolicy portfolioConflictPolicy;
        AdvisorCompetency advisorCompetency;
        mapping(address => RiskWarnings) riskWarnings;
        SuitabilityPolicy suitabilityPolicy;
        mapping(address => SuitabilityReport) suitabilityReports;
        mapping(address => PortfolioStatement) portfolioStatements;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;
    bytes32 public esmaGuidelinesHash;

    event SuitabilityAssessmentSubmitted(address indexed casp, address indexed client);
    event AdviceDisclosureSubmitted(address indexed casp);
    event CostDisclosureSubmitted(address indexed casp);
    event PortfolioConflictPolicySubmitted(address indexed casp);
    event AdvisorCompetencySubmitted(address indexed casp);
    event RiskWarningsSubmitted(address indexed casp, address indexed client);
    event SuitabilityPolicySubmitted(address indexed casp);
    event SuitabilityAssessmentUpdated(address indexed casp, address indexed client);
    event SuitabilityReportSubmitted(address indexed casp, address indexed client);
    event PortfolioStatementSubmitted(address indexed casp, address indexed client);
    event ESMAGuidelinesUpdated(bytes32 guidelineHash);

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

    // Paragraph 1: Suitability Assessment
    function submitSuitabilityAssessment(address _caspAddress, address _clientAddress, bytes32 _assessmentHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].suitabilityAssessments[_clientAddress] = SuitabilityAssessment({
            assessmentHash: _assessmentHash,
            submissionDate: block.timestamp
        });
        emit SuitabilityAssessmentSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 2: Disclosure of Advice Nature
    function submitAdviceDisclosure(address _caspAddress, bytes32 _disclosureHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].adviceDisclosure = AdviceDisclosure({
            disclosureHash: _disclosureHash,
            submissionDate: block.timestamp
        });
        emit AdviceDisclosureSubmitted(_caspAddress);
    }

    // Paragraph 4: Cost Transparency
    function submitCostDisclosure(address _caspAddress, bytes32 _costHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].costDisclosure = CostDisclosure({
            costHash: _costHash,
            submissionDate: block.timestamp
        });
        emit CostDisclosureSubmitted(_caspAddress);
    }

    // Paragraph 5: Portfolio Management Conflicts
    function submitPortfolioConflictPolicy(address _caspAddress, bytes32 _conflictHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].portfolioConflictPolicy = PortfolioConflictPolicy({
            conflictHash: _conflictHash,
            submissionDate: block.timestamp
        });
        emit PortfolioConflictPolicySubmitted(_caspAddress);
    }

    // Paragraph 7: Advisor Competency
    function submitAdvisorCompetency(address _caspAddress, bytes32 _competencyHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].advisorCompetency = AdvisorCompetency({
            competencyHash: _competencyHash,
            submissionDate: block.timestamp
        });
        emit AdvisorCompetencySubmitted(_caspAddress);
    }

    // Paragraph 9: Mandatory Risk Warnings
    function submitRiskWarnings(address _caspAddress, address _clientAddress, bytes32 _warningHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].riskWarnings[_clientAddress] = RiskWarnings({
            warningHash: _warningHash,
            submissionDate: block.timestamp
        });
        emit RiskWarningsSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 10: Suitability Policies
    function submitSuitabilityPolicy(address _caspAddress, bytes32 _policyHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].suitabilityPolicy = SuitabilityPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp
        });
        emit SuitabilityPolicySubmitted(_caspAddress);
    }

    // Paragraph 12: Regular Suitability Reviews
    function updateSuitabilityAssessment(address _caspAddress, address _clientAddress, bytes32 _newAssessmentHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        SuitabilityAssessment storage assessment = casps[_caspAddress].suitabilityAssessments[_clientAddress];
        require(assessment.submissionDate > 0, "No initial assessment");
        require(block.timestamp >= assessment.submissionDate + 2 * 365 days,
            "Review not yet due unless significant change");
        assessment.assessmentHash = _newAssessmentHash;
        assessment.submissionDate = block.timestamp;
        emit SuitabilityAssessmentUpdated(_caspAddress, _clientAddress);
    }

    // Paragraph 13: Suitability Reports
    function submitSuitabilityReport(address _caspAddress, address _clientAddress, bytes32 _reportHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].suitabilityReports[_clientAddress] = SuitabilityReport({
            reportHash: _reportHash,
            submissionDate: block.timestamp
        });
        emit SuitabilityReportSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 14: Portfolio Management Statements
    function submitPortfolioStatement(address _caspAddress, address _clientAddress, bytes32 _statementHash) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        PortfolioStatement storage statement = casps[_caspAddress].portfolioStatements[_clientAddress];
        require(block.timestamp >= statement.submissionDate + 90 days || statement.submissionDate == 0,
            "Quarterly statement not yet due");
        statement.statementHash = _statementHash;
        statement.submissionDate = block.timestamp;
        emit PortfolioStatementSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 15: ESMA Guidelines
    function updateESMAGuidelines(bytes32 _guidelineHash) external onlyESMA {
        esmaGuidelinesHash = _guidelineHash;
        emit ESMAGuidelinesUpdated(_guidelineHash);
    }
}