// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPPrudentialRegistry {
    enum SafeguardType { OwnFunds, Insurance }

    struct PrudentialSafeguards {
        uint256 minimumCapital;
        uint256 fixedOverheads;
        uint256 requiredAmount;
        uint256 submissionDate;
        bool isNewCASP;
    }

    struct FixedOverheadsDetails {
        uint256 totalOverheads;
        uint256 adjustedOverheads;
        uint256 bonuses;
        uint256 profitSharing;
        uint256 discretionaryProfits;
        uint256 nonRecurringExpenses;
        uint256 submissionDate;
    }

    struct SafeguardForm {
        SafeguardType safeguardType;
        uint256 amount;
        uint256 submissionDate;
    }

    struct InsurancePolicy {
        string policyUrl;
        uint256 termStart;
        uint256 termEnd;
        bytes32 coverageHash;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        PrudentialSafeguards prudentialSafeguards;
        FixedOverheadsDetails fixedOverheadsDetails;
        SafeguardForm safeguardForm;
        InsurancePolicy insurancePolicy;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event PrudentialSafeguardsSubmitted(address indexed casp, uint256 requiredAmount);
    event FixedOverheadsSubmitted(address indexed casp, uint256 adjustedOverheads);
    event SafeguardFormSubmitted(address indexed casp, SafeguardType safeguardType, uint256 amount);
    event InsurancePolicySubmitted(address indexed casp, string policyUrl);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
    }

    // Paragraph 1: Minimum Prudential Safeguards
    function submitPrudentialSafeguards(
        address _caspAddress,
        uint256 _minimumCapital,
        uint256 _fixedOverheads
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        uint256 requiredSafeguards = _minimumCapital > (_fixedOverheads * 25 / 100)
            ? _minimumCapital
            : (_fixedOverheads * 25 / 100);
        casps[_caspAddress].prudentialSafeguards = PrudentialSafeguards({
            minimumCapital: _minimumCapital,
            fixedOverheads: _fixedOverheads,
            requiredAmount: requiredSafeguards,
            submissionDate: block.timestamp,
            isNewCASP: false
        });
        emit PrudentialSafeguardsSubmitted(_caspAddress, requiredSafeguards);
    }

    // Paragraph 2: New CASPs
    function submitNewCASPPrudentialSafeguards(
        address _caspAddress,
        uint256 _minimumCapital,
        uint256 _projectedOverheads
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(!casps[_caspAddress].prudentialSafeguards.isNewCASP, "Already submitted as new CASP");
        uint256 requiredSafeguards = _minimumCapital > (_projectedOverheads * 25 / 100)
            ? _minimumCapital
            : (_projectedOverheads * 25 / 100);
        casps[_caspAddress].prudentialSafeguards = PrudentialSafeguards({
            minimumCapital: _minimumCapital,
            fixedOverheads: _projectedOverheads,
            requiredAmount: requiredSafeguards,
            submissionDate: block.timestamp,
            isNewCASP: true
        });
        emit PrudentialSafeguardsSubmitted(_caspAddress, requiredSafeguards);
    }

    // Paragraph 3: Calculation of Fixed Overheads
    function submitFixedOverheads(
        address _caspAddress,
        uint256 _totalOverheads,
        uint256 _bonuses,
        uint256 _profitSharing,
        uint256 _discretionaryProfits,
        uint256 _nonRecurringExpenses
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        uint256 adjustedOverheads = _totalOverheads
            - _bonuses
            - _profitSharing
            - _discretionaryProfits
            - _nonRecurringExpenses;
        casps[_caspAddress].fixedOverheadsDetails = FixedOverheadsDetails({
            totalOverheads: _totalOverheads,
            adjustedOverheads: adjustedOverheads,
            bonuses: _bonuses,
            profitSharing: _profitSharing,
            discretionaryProfits: _discretionaryProfits,
            nonRecurringExpenses: _nonRecurringExpenses,
            submissionDate: block.timestamp
        });
        emit FixedOverheadsSubmitted(_caspAddress, adjustedOverheads);
    }

    // Paragraph 4: Forms of Prudential Safeguards
    function submitSafeguardForm(
        address _caspAddress,
        SafeguardType _type,
        uint256 _amount
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(casps[_caspAddress].prudentialSafeguards.requiredAmount > 0,
            "Prudential safeguards not submitted");
        require(_amount >= casps[_caspAddress].prudentialSafeguards.requiredAmount,
            "Amount below required safeguards");
        casps[_caspAddress].safeguardForm = SafeguardForm({
            safeguardType: _type,
            amount: _amount,
            submissionDate: block.timestamp
        });
        emit SafeguardFormSubmitted(_caspAddress, _type, _amount);
    }

    // Paragraphs 5 & 6: Insurance Policy Requirements
    function submitInsurancePolicy(
        address _caspAddress,
        string memory _policyUrl,
        uint256 _termStart,
        uint256 _termEnd,
        bytes32 _coverageHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(casps[_caspAddress].safeguardForm.safeguardType == SafeguardType.Insurance,
            "Safeguard type must be insurance");
        require(_termEnd >= _termStart + 365 days, "Term must be at least 1 year");
        casps[_caspAddress].insurancePolicy = InsurancePolicy({
            policyUrl: _policyUrl,
            termStart: _termStart,
            termEnd: _termEnd,
            coverageHash: _coverageHash,
            submissionDate: block.timestamp
        });
        emit InsurancePolicySubmitted(_caspAddress, _policyUrl);
    }
}