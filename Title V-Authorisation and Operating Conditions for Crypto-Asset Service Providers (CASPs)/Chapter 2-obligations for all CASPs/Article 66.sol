// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 66
contract CASPConductRegistry {
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct Communication {
        bytes32 communicationHash;
        bool isMarketing;
        uint256 submissionDate;
    }

    struct RiskWarning {
        bytes32 riskWarningHash;
        string whitePaperUrl;
        uint256 submissionDate;
    }

    struct FeeDisclosure {
        bytes32 feeStructureHash;
        string feeUrl;
        uint256 submissionDate;
    }

    struct EnvironmentalDisclosure {
        bytes32 environmentalDataHash;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        bool conductCommitted;
        Communication[] communications;
        mapping(CryptoService => RiskWarning) riskWarnings;
        FeeDisclosure feeDisclosure;
        mapping(string => EnvironmentalDisclosure) environmentalDisclosures;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;
    address public esmaAuthority;
    bytes32 public rtsStandardsHash;

    event ConductCommitmentRegistered(address indexed casp);
    event CommunicationSubmitted(address indexed casp, bytes32 communicationHash, bool isMarketing);
    event RiskWarningSubmitted(address indexed casp, CryptoService service, string whitePaperUrl);
    event FeeDisclosureSubmitted(address indexed casp, string feeUrl);
    event EnvironmentalDisclosureSubmitted(address indexed casp, string cryptoAsset);
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

    // Paragraph 1a: Duty of Conduct
    function registerConductCommitment(address _caspAddress) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        require(!casps[_caspAddress].conductCommitted, "Conduct already committed");
        casps[_caspAddress].conductCommitted = true;
        emit ConductCommitmentRegistered(_caspAddress);
    }

    // Paragraph 1b: Transparency in Communications
    function submitCommunication(
        address _caspAddress,
        bytes32 _communicationHash,
        bool _isMarketing
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].communications.push(Communication({
            communicationHash: _communicationHash,
            isMarketing: _isMarketing,
            submissionDate: block.timestamp
        }));
        emit CommunicationSubmitted(_caspAddress, _communicationHash, _isMarketing);
    }

    // Paragraph 1c: Risk Warnings
    function submitRiskWarning(
        address _caspAddress,
        CryptoService _service,
        bytes32 _riskWarningHash,
        string memory _whitePaperUrl
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].riskWarnings[_service] = RiskWarning({
            riskWarningHash: _riskWarningHash,
            whitePaperUrl: _whitePaperUrl,
            submissionDate: block.timestamp
        });
        emit RiskWarningSubmitted(_caspAddress, _service, _whitePaperUrl);
    }

    // Paragraph 1d: Fee Transparency
    function submitFeeDisclosure(
        address _caspAddress,
        bytes32 _feeStructureHash,
        string memory _feeUrl
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].feeDisclosure = FeeDisclosure({
            feeStructureHash: _feeStructureHash,
            feeUrl: _feeUrl,
            submissionDate: block.timestamp
        });
        emit FeeDisclosureSubmitted(_caspAddress, _feeUrl);
    }

    // Paragraph 1e: Environmental Disclosures
    function submitEnvironmentalDisclosure(
        address _caspAddress,
        string memory _cryptoAsset,
        bytes32 _environmentalDataHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].environmentalDisclosures[_cryptoAsset] = EnvironmentalDisclosure({
            environmentalDataHash: _environmentalDataHash,
            submissionDate: block.timestamp
        });
        emit EnvironmentalDisclosureSubmitted(_caspAddress, _cryptoAsset);
    }

    // Paragraph 6: Regulatory Technical Standards
    function updateRTSStandards(bytes32 _rtsHash) external onlyESMA {
        rtsStandardsHash = _rtsHash;
        emit RTSStandardsUpdated(_rtsHash);
    }
}
