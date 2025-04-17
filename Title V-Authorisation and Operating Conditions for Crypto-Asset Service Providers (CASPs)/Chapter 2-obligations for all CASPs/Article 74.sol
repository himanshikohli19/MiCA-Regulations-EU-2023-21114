// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 74
contract CASPWindDownRegistry {
    struct WindDownPlan {
        bytes32 planHash;        // Hash of wind-down plan document
        uint256 submissionDate;
        uint256 lastReviewDate;
        bool isCompliant;        // Confirmed by NCA
    }

    struct CASP {
        bool isAuthorized;
        WindDownPlan windDownPlan;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public ncAuthority;

    event WindDownPlanSubmitted(address indexed casp);
    event PlanComplianceConfirmed(address indexed casp, bool isCompliant);
    event WindDownPlanUpdated(address indexed casp, uint256 reviewDate);
    event NonComplianceFlagged(address indexed casp, string reason);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _casps, address[] memory _ncas) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Wind-Down Plan Obligations
    function submitWindDownPlan(
        address _caspAddress,
        bytes32 _planHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(casps[_caspAddress].windDownPlan.submissionDate == 0, "Plan already submitted");
        casps[_caspAddress].windDownPlan = WindDownPlan({
            planHash: _planHash,
            submissionDate: block.timestamp,
            lastReviewDate: block.timestamp,
            isCompliant: false
        });
        emit WindDownPlanSubmitted(_caspAddress);
    }

    // Paragraph 2: Objectives of the Plan (Compliance Confirmation)
    function confirmPlanCompliance(
        address _caspAddress,
        bool _isCompliant
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        WindDownPlan storage plan = casps[_caspAddress].windDownPlan;
        require(plan.submissionDate > 0, "No plan submitted");
        plan.isCompliant = _isCompliant;
        emit PlanComplianceConfirmed(_caspAddress, _isCompliant);
    }

    // Paragraph 3: Regulatory & Client Protection Focus (Annual Update)
    function updateWindDownPlan(
        address _caspAddress,
        bytes32 _newPlanHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        WindDownPlan storage plan = casps[_caspAddress].windDownPlan;
        require(plan.submissionDate > 0, "No initial plan submitted");
        require(block.timestamp >= plan.lastReviewDate + 365 days,
            "Annual review not yet due");
        plan.planHash = _newPlanHash;
        plan.lastReviewDate = block.timestamp;
        plan.isCompliant = false;  // Requires re-confirmation
        emit WindDownPlanUpdated(_caspAddress, block.timestamp);
    }

    // Paragraph 3: Regulatory & Client Protection Focus (Non-Compliance)
    function flagNonCompliance(
        address _caspAddress,
        string memory _reason
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        WindDownPlan storage plan = casps[_caspAddress].windDownPlan;
        require(plan.submissionDate > 0, "No plan submitted");
        plan.isCompliant = false;
        emit NonComplianceFlagged(_caspAddress, _reason);
    }
}