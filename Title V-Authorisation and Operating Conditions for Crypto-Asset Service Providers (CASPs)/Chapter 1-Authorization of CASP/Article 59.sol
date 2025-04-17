// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 59
contract CASPRegistry {
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct CASP {
        address caspAddress;
        string legalName;
        string memberState;
        CryptoService[] services;
        bool isAuthorized;
        uint256 authorizationDate;
        bool isActive;
        string[] targetMemberStates;
        bool isNonLegalEntity;
        bytes32 managementProof;
        bytes32 lastUpdatedDocs;
        uint256 lastUpdatedDate;
    }

    struct ExemptEntity {
        bool isNotified;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public ncAuthority;
    mapping(address => ExemptEntity) public exemptEntities; // Placeholder for Article 60 integration

    event CASPRegistered(address indexed casp, string memberState, CryptoService[] services);
    event CrossBorderNotified(address indexed casp, string[] targetStates);
    event ServicesExtended(address indexed casp, CryptoService[] newServices);
    event ComplianceFailed(address indexed casp, string reason);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraph 1: Authorization Requirement
    function registerCASP(
        address _caspAddress,
        string memory _legalName,
        string memory _memberState,
        CryptoService[] memory _services
    ) external onlyNCA {
        require(!casps[_caspAddress].isAuthorized, "CASP already authorized");
        require(!isExemptEntity(_caspAddress), "Entity is exempt under Article 60");
        require(bytes(_memberState).length > 0, "Must specify EU Member State"); // Paragraph 2: Registered Office

        casps[_caspAddress] = CASP({
            caspAddress: _caspAddress,
            legalName: _legalName,
            memberState: _memberState,
            services: _services,
            isAuthorized: true,
            authorizationDate: block.timestamp,
            isActive: true,
            targetMemberStates: new string[](0),
            isNonLegalEntity: false,
            managementProof: bytes32(0),
            lastUpdatedDocs: bytes32(0),
            lastUpdatedDate: 0
        });

        emit CASPRegistered(_caspAddress, _memberState, _services);
    }

    // Paragraph 2: Management Proof
    function submitManagementProof(address _caspAddress, bytes32 _proofHash) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].managementProof = _proofHash;
    }

    // Paragraph 3: Non-Legal Entities
    function registerNonLegalEntity(
        address _caspAddress,
        string memory _legalName,
        string memory _memberState,
        CryptoService[] memory _services,
        bool _isNonLegalEntity
    ) external onlyNCA {
        require(_isNonLegalEntity, "Must confirm non-legal entity status");

        casps[_caspAddress] = CASP({
            caspAddress: _caspAddress,
            legalName: _legalName,
            memberState: _memberState,
            services: _services,
            isAuthorized: true,
            authorizationDate: block.timestamp,
            isActive: true,
            targetMemberStates: new string[](0),
            isNonLegalEntity: true,
            managementProof: bytes32(0),
            lastUpdatedDocs: bytes32(0),
            lastUpdatedDate: 0
        });

        emit CASPRegistered(_caspAddress, _memberState, _services);
    }

    // Paragraph 4: Ongoing Compliance
    function updateComplianceStatus(address _caspAddress, bool _isCompliant) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].isActive = _isCompliant;
        if (!_isCompliant) {
            emit ComplianceFailed(_caspAddress, "Non-compliant with MiCA conditions");
        }
    }

    // Paragraph 5: Misleading Practices Ban
    function verifyAuthorization(address _caspAddress) public view returns (bool) {
        return casps[_caspAddress].isAuthorized && casps[_caspAddress].isActive;
    }

    // Paragraph 6: Scope of Authorization
    function isServiceAuthorized(address _caspAddress, CryptoService _service) public view returns (bool) {
        CASP storage casp = casps[_caspAddress];
        for (uint i = 0; i < casp.services.length; i++) {
            if (casp.services[i] == _service) {
                return true;
            }
        }
        return false;
    }

    // Paragraph 7: EU Passporting Rights
    function notifyCrossBorder(address _caspAddress, string[] memory _targetMemberStates) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].targetMemberStates = _targetMemberStates;
        emit CrossBorderNotified(_caspAddress, _targetMemberStates);
    }

    function canOperateInState(address _caspAddress, string memory _state) public view returns (bool) {
        CASP memory casp = casps[_caspAddress];
        if (!casp.isAuthorized || !casp.isActive) {
            return false;
        }
        if (keccak256(bytes(casp.memberState)) == keccak256(bytes(_state))) {
            return true;
        }
        for (uint i = 0; i < casp.targetMemberStates.length; i++) {
            if (keccak256(bytes(casp.targetMemberStates[i])) == keccak256(bytes(_state))) {
                return true;
            }
        }
        return false;
    }

    // Paragraph 8: Extending Authorization
    function extendAuthorization(
        address _caspAddress,
        CryptoService[] memory _newServices,
        bytes32 _updatedDocsHash
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].services = _newServices;
        casps[_caspAddress].lastUpdatedDocs = _updatedDocsHash;
        casps[_caspAddress].lastUpdatedDate = block.timestamp;
        emit ServicesExtended(_caspAddress, _newServices);
    }

    // Placeholder for Article 60 integration
    function isExemptEntity(address _entity) public view returns (bool) {
        return exemptEntities[_entity].isNotified;
    }
}