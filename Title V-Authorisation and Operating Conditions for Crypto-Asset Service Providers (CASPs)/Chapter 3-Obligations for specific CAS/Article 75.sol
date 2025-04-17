// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPCustodyRegistry {
    struct ClientAgreement {
        bytes32 agreementHash;
        uint256 submissionDate;
    }

    struct ClientPosition {
        bytes32 positionHash;
        uint256 lastUpdate;
    }

    struct CustodyPolicy {
        bytes32 policyHash;
        uint256 submissionDate;
    }

    struct ClientRights {
        bytes32 rightsHash;
        uint256 submissionDate;
    }

    struct ClientReporting {
        bytes32 reportHash;
        uint256 lastReportDate;
    }

    struct AssetReturnProcedure {
        bytes32 procedureHash;
        uint256 submissionDate;
    }

    struct SegregationPolicy {
        bytes32 segregationHash;
        uint256 submissionDate;
    }

    struct LiabilityEvent {
        bytes32 eventHash;
        uint256 submissionDate;
    }

    struct SubCustodyArrangement {
        bytes32 arrangementHash;
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        mapping(address => ClientAgreement) clientAgreements;
        mapping(address => ClientPosition) clientPositions;
        CustodyPolicy custodyPolicy;
        mapping(address => ClientRights) clientRights;
        mapping(address => ClientReporting) clientReporting;
        AssetReturnProcedure assetReturnProcedure;
        SegregationPolicy segregationPolicy;
        LiabilityEvent[] liabilityEvents;
        mapping(address => SubCustodyArrangement) subCustodyArrangements;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event ClientAgreementSubmitted(address indexed casp, address indexed client);
    event ClientPositionUpdated(address indexed casp, address indexed client);
    event CustodyPolicySubmitted(address indexed casp);
    event ClientRightsSubmitted(address indexed casp, address indexed client);
    event ClientReportSubmitted(address indexed casp, address indexed client);
    event AssetReturnProcedureSubmitted(address indexed casp);
    event SegregationPolicySubmitted(address indexed casp);
    event LiabilityEventLogged(address indexed casp);
    event SubCustodyArrangementSubmitted(address indexed casp, address indexed subCustodian);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
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

    // Paragraph 2: Register of Client Positions
    function updateClientPosition(
        address _caspAddress,
        address _clientAddress,
        bytes32 _positionHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].clientPositions[_clientAddress] = ClientPosition({
            positionHash: _positionHash,
            lastUpdate: block.timestamp
        });
        emit ClientPositionUpdated(_caspAddress, _clientAddress);
    }

    // Paragraph 3: Custody Policy
    function submitCustodyPolicy(
        address _caspAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].custodyPolicy = CustodyPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp
        });
        emit CustodyPolicySubmitted(_caspAddress);
    }

    // Paragraph 4: Handling Crypto-Asset Rights
    function submitClientRights(
        address _caspAddress,
        address _clientAddress,
        bytes32 _rightsHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].clientRights[_clientAddress] = ClientRights({
            rightsHash: _rightsHash,
            submissionDate: block.timestamp
        });
        emit ClientRightsSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 5: Client Reporting
    function submitClientReport(
        address _caspAddress,
        address _clientAddress,
        bytes32 _reportHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        ClientReporting storage reporting = casps[_caspAddress].clientReporting[_clientAddress];
        require(block.timestamp >= reporting.lastReportDate + 90 days || reporting.lastReportDate == 0,
            "Quarterly report not yet due");
        reporting.reportHash = _reportHash;
        reporting.lastReportDate = block.timestamp;
        emit ClientReportSubmitted(_caspAddress, _clientAddress);
    }

    // Paragraph 6: Asset Return Procedures
    function submitAssetReturnProcedure(
        address _caspAddress,
        bytes32 _procedureHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].assetReturnProcedure = AssetReturnProcedure({
            procedureHash: _procedureHash,
            submissionDate: block.timestamp
        });
        emit AssetReturnProcedureSubmitted(_caspAddress);
    }

    // Paragraph 7: Segregation of Client Assets
    function submitSegregationPolicy(
        address _caspAddress,
        bytes32 _segregationHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].segregationPolicy = SegregationPolicy({
            segregationHash: _segregationHash,
            submissionDate: block.timestamp
        });
        emit SegregationPolicySubmitted(_caspAddress);
    }

    // Paragraph 8: Liability for Losses
    function logLiabilityEvent(
        address _caspAddress,
        bytes32 _eventHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].liabilityEvents.push(LiabilityEvent({
            eventHash: _eventHash,
            submissionDate: block.timestamp
        }));
        emit LiabilityEventLogged(_caspAddress);
    }

    // Paragraph 9: Sub-Custody Rules
    function submitSubCustodyArrangement(
        address _caspAddress,
        address _subCustodianAddress,
        bytes32 _arrangementHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].subCustodyArrangements[_subCustodianAddress] = SubCustodyArrangement({
            arrangementHash: _arrangementHash,
            submissionDate: block.timestamp
        });
        emit SubCustodyArrangementSubmitted(_caspAddress, _subCustodianAddress);
    }
}