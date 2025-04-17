// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 73
contract CASPOutsourcingRegistry {
    struct OutsourcingArrangement {
        bytes32 conditionsHash;  // Hash of compliance with conditions (a-g)
        bytes32 policyHash;      // Hash of outsourcing policy
        bytes32 agreementHash;   // Hash of written agreement
        uint256 submissionDate;
    }

    struct RegulatoryAccess {
        bytes32 accessDataHash;  // Hash of data available to regulators
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        mapping(address => OutsourcingArrangement) outsourcingArrangements;
        mapping(address => RegulatoryAccess) regulatoryAccess;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public ncAuthority;

    event OutsourcingConditionsSubmitted(address indexed casp, address indexed thirdParty);
    event OutsourcingPolicySubmitted(address indexed casp, address indexed thirdParty);
    event OutsourcingAgreementSubmitted(address indexed casp, address indexed thirdParty);
    event RegulatoryAccessDataSubmitted(address indexed casp, address indexed thirdParty);

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

    // Paragraph 1: Conditions for Outsourcing
    function submitOutsourcingConditions(
        address _caspAddress,
        address _thirdPartyAddress,
        bytes32 _conditionsHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].outsourcingArrangements[_thirdPartyAddress] = OutsourcingArrangement({
            conditionsHash: _conditionsHash,
            policyHash: bytes32(0),
            agreementHash: bytes32(0),
            submissionDate: block.timestamp
        });
        emit OutsourcingConditionsSubmitted(_caspAddress, _thirdPartyAddress);
    }

    // Paragraph 2: Outsourcing Policy
    function submitOutsourcingPolicy(
        address _caspAddress,
        address _thirdPartyAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        OutsourcingArrangement storage arrangement = casps[_caspAddress].outsourcingArrangements[_thirdPartyAddress];
        require(arrangement.submissionDate > 0, "Outsourcing not initiated");
        arrangement.policyHash = _policyHash;
        emit OutsourcingPolicySubmitted(_caspAddress, _thirdPartyAddress);
    }

    // Paragraph 3: Written Agreements
    function submitOutsourcingAgreement(
        address _caspAddress,
        address _thirdPartyAddress,
        bytes32 _agreementHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        OutsourcingArrangement storage arrangement = casps[_caspAddress].outsourcingArrangements[_thirdPartyAddress];
        require(arrangement.submissionDate > 0, "Outsourcing not initiated");
        arrangement.agreementHash = _agreementHash;
        emit OutsourcingAgreementSubmitted(_caspAddress, _thirdPartyAddress);
    }

    // Paragraph 4: Regulatory Access
    function submitRegulatoryAccessData(
        address _caspAddress,
        address _thirdPartyAddress,
        bytes32 _accessDataHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        OutsourcingArrangement storage arrangement = casps[_caspAddress].outsourcingArrangements[_thirdPartyAddress];
        require(arrangement.submissionDate > 0, "Outsourcing not initiated");
        casps[_caspAddress].regulatoryAccess[_thirdPartyAddress] = RegulatoryAccess({
            accessDataHash: _accessDataHash,
            submissionDate: block.timestamp
        });
        emit RegulatoryAccessDataSubmitted(_caspAddress, _thirdPartyAddress);
    }
}