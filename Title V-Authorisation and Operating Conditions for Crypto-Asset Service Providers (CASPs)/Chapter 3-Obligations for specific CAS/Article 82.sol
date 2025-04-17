// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPTransferServiceRegistry {
    struct ClientAgreement {
        bytes32 agreementHash;  // Hash of agreement details (identity, service, security, fees, law)
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        mapping(address => ClientAgreement) clientAgreements;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    mapping(address => bool) public regulatorAuthority;  // For ESMA/EBA
    bytes32 public guidelinesHash;

    event ClientAgreementSubmitted(address indexed casp, address indexed client);
    event GuidelinesUpdated(bytes32 guidelineHash);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    modifier onlyRegulator() {
        require(regulatorAuthority[msg.sender], "Only regulator can call this function");
        _;
    }

    constructor(address[] memory _casps, address[] memory _regulators) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
        for (uint i = 0; i < _regulators.length; i++) {
            regulatorAuthority[_regulators[i]] = true;
        }
    }

    // Paragraph 1: Mandatory Client Agreement
    function submitClientAgreement(
        address _caspAddress,
        address _clientAddress,
        bytes32 _agreementHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].clientAgreements[_clientAddress] = ClientAgreement({
            agreementHash: _agreementHash,
            submissionDate: block.timestamp
        });
        emit ClientAgreementSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 2: ESMA & EBA Guidelines
    function updateGuidelines(
        bytes32 _guidelineHash
    ) external onlyRegulator {
        guidelinesHash = _guidelineHash;
        emit GuidelinesUpdated(_guidelineHash);
    }
}