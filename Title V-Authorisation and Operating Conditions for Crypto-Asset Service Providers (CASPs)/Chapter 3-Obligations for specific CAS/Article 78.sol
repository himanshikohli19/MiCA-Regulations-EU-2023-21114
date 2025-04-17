// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPOrderExecutionRegistry {
    struct OrderExecution {
        address clientAddress;
        bytes32 orderHash;  // Includes price, costs, speed, etc.
        uint256 executionPrice;
        uint256 executionDate;
    }

    struct ExecutionPolicy {
        bytes32 policyHash;  // Policy for fair execution
        uint256 submissionDate;
    }

    struct ClientConsent {
        bytes32 consentHash;  // Consent to policy
        uint256 submissionDate;
    }

    struct ComplianceProof {
        bytes32 proofHash;  // Proof of execution quality
        uint256 submissionDate;
    }

    struct OffExchangeConsent {
        bytes32 offExchangeConsentHash;  // Consent for off-exchange trades
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        OrderExecution[] orderExecutions;
        ExecutionPolicy executionPolicy;
        mapping(address => ClientConsent) clientConsents;
        ComplianceProof[] complianceProofs;
        mapping(address => OffExchangeConsent) offExchangeConsents;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event OrderExecutionLogged(address indexed casp, address indexed client);
    event ExecutionPolicySubmitted(address indexed casp);
    event ClientConsentSubmitted(address indexed casp, address indexed client);
    event ComplianceProofSubmitted(address indexed casp);
    event OffExchangeConsentSubmitted(address indexed casp, address indexed client);
    event ExecutionPolicyUpdated(address indexed casp);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
    }

    // Paragraph 1: Best Execution Obligation
    function logOrderExecution(
        address _caspAddress,
        address _clientAddress,
        bytes32 _orderHash,
        uint256 _executionPrice
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].orderExecutions.push(OrderExecution({
            clientAddress: _clientAddress,
            orderHash: _orderHash,
            executionPrice: _executionPrice,
            executionDate: block.timestamp
        }));
        emit OrderExecutionLogged(_caspAddress, _clientAddress);
    }

    // Paragraph 2: Order Execution Policy
    function submitExecutionPolicy(
        address _caspAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].executionPolicy = ExecutionPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp
        });
        emit ExecutionPolicySubmitted(_caspAddress);
    }

    // Paragraph 3: Client Disclosure & Consent
    function submitClientConsent(
        address _caspAddress,
        address _clientAddress,
        bytes32 _consentHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].clientConsents[_clientAddress] = ClientConsent({
            consentHash: _consentHash,
            submissionDate: block.timestamp
        });
        emit ClientConsentSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 4: Compliance Proof
    function submitComplianceProof(
        address _caspAddress,
        bytes32 _proofHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].complianceProofs.push(ComplianceProof({
            proofHash: _proofHash,
            submissionDate: block.timestamp
        }));
        emit ComplianceProofSubmitted(_caspAddress);
    }

    // Paragraph 5: Off-Exchange Execution
    function submitOffExchangeConsent(
        address _caspAddress,
        address _clientAddress,
        bytes32 _offExchangeConsentHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].offExchangeConsents[_clientAddress] = OffExchangeConsent({
            offExchangeConsentHash: _offExchangeConsentHash,
            submissionDate: block.timestamp
        });
        emit OffExchangeConsentSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 6: Ongoing Monitoring & Updates
    function updateExecutionPolicy(
        address _caspAddress,
        bytes32 _newPolicyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        ExecutionPolicy storage policy = casps[_caspAddress].executionPolicy;
        require(policy.submissionDate > 0, "No initial policy submitted");
        require(block.timestamp >= policy.submissionDate + 365 days ||
                policy.submissionDate == block.timestamp,
            "Annual review not yet due unless material change");
        policy.policyHash = _newPolicyHash;
        policy.submissionDate = block.timestamp;
        emit ExecutionPolicyUpdated(_caspAddress);
    }
}