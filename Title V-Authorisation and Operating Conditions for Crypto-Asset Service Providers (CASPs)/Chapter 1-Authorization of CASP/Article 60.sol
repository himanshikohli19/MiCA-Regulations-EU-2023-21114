// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 60
contract ExemptEntityRegistry {
    enum EntityType {
        CreditInstitution,
        CentralSecuritiesDepository,
        InvestmentFirm,
        ElectronicMoneyInstitution,
        UCITS_AIFM,
        MarketOperator
    }

    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct ExemptEntity {
        address entityAddress;
        EntityType entityType;
        bool isNotified;
        uint256 notificationDate;
        uint256 startDate; // 40 days after notification
        bool isNotificationComplete;
        CryptoService[] services;
        bool isRevoked;
    }

    mapping(address => ExemptEntity) public entities;
    mapping(address => mapping(string => bytes32)) public documents; // Moved from struct to external mapping
    mapping(address => bool) public ncAuthority;

    event EntityNotified(address indexed entity, EntityType entityType, CryptoService[] services);
    event NotificationConfirmed(address indexed entity);
    event RightsRevoked(address indexed entity, string reason);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Paragraphs 1-6: Notify Exempt Entity
    function notifyExemptEntity(
        address _entityAddress,
        EntityType _entityType,
        CryptoService[] memory _services
    ) external {
        require(!entities[_entityAddress].isNotified, "Entity already notified");
        validateServices(_entityType, _services);

        ExemptEntity storage entity = entities[_entityAddress];
        entity.entityAddress = _entityAddress;
        entity.entityType = _entityType;
        entity.isNotified = true;
        entity.notificationDate = block.timestamp;
        entity.startDate = block.timestamp + 40 days;
        entity.isNotificationComplete = false;
        entity.services = _services;
        entity.isRevoked = false;

        emit EntityNotified(_entityAddress, _entityType, _services);
    }

    function validateServices(EntityType _entityType, CryptoService[] memory _services) internal pure {
        for (uint i = 0; i < _services.length; i++) {
            if (_entityType == EntityType.CentralSecuritiesDepository) {
                require(_services[i] == CryptoService.Custody, "CSDs limited to custody");
            } else if (_entityType == EntityType.ElectronicMoneyInstitution) {
                require(
                    _services[i] == CryptoService.Custody || _services[i] == CryptoService.Transfer,
                    "EMIs limited to custody/transfer of own tokens"
                );
            } else if (_entityType == EntityType.UCITS_AIFM) {
                require(
                    _services[i] == CryptoService.OrderExecution ||
                    _services[i] == CryptoService.Advice ||
                    _services[i] == CryptoService.PortfolioManagement,
                    "UCITS/AIFM limited to order/advice/portfolio"
                );
            } else if (_entityType == EntityType.MarketOperator) {
                require(_services[i] == CryptoService.TradingPlatform, "Market operators limited to trading platforms");
            }
        }
    }

    // Paragraph 7: Notification Requirements
    function submitDocument(
        address _entityAddress,
        string memory _docType,
        bytes32 _docHash
    ) external onlyNCA {
        require(entities[_entityAddress].isNotified, "Entity not notified");
        documents[_entityAddress][_docType] = _docHash;
    }

    function confirmNotification(address _entityAddress) external onlyNCA {
        require(entities[_entityAddress].isNotified, "Entity not notified");
        require(
            block.timestamp <= entities[_entityAddress].notificationDate + 20 days,
            "20-day review period expired"
        );
        require(areDocumentsComplete(_entityAddress), "Documents incomplete");

        entities[_entityAddress].isNotificationComplete = true;
        emit NotificationConfirmed(_entityAddress);
    }

    function areDocumentsComplete(address _entityAddress) internal view returns (bool) {
        return documents[_entityAddress]["AML_CFT"] != bytes32(0) &&
               documents[_entityAddress]["IT_Security"] != bytes32(0) &&
               documents[_entityAddress]["Client_Asset_Segregation"] != bytes32(0);
    }

    function canStartServices(address _entityAddress) public view returns (bool) {
        ExemptEntity storage entity = entities[_entityAddress];
        return entity.isNotified &&
               entity.isNotificationComplete &&
               block.timestamp >= entity.startDate &&
               !entity.isRevoked;
    }

    // Paragraphs 9-11: Exemptions & Special Rules
    function reuseDocument(
        address _entityAddress,
        string memory _docType,
        bytes32 _existingDocHash
    ) external onlyNCA {
        require(entities[_entityAddress].isNotified, "Entity not notified");
        require(_existingDocHash != bytes32(0), "Invalid document hash");
        documents[_entityAddress][_docType] = _existingDocHash;
    }

    function revokeRights(address _entityAddress) external onlyNCA {
        require(entities[_entityAddress].isNotified, "Entity not notified");
        entities[_entityAddress].isRevoked = true;
        emit RightsRevoked(_entityAddress, "Primary license lost");
    }

    // Paragraphs 12-14: ESMA’s Role
    function getEntityDetails(address _entityAddress) public view returns (
        EntityType entityType,
        bool isNotified,
        uint256 notificationDate,
        uint256 startDate,
        bool isNotificationComplete,
        CryptoService[] memory services,
        bool isRevoked
    ) {
        ExemptEntity storage entity = entities[_entityAddress];
        return (
            entity.entityType,
            entity.isNotified,
            entity.notificationDate,
            entity.startDate,
            entity.isNotificationComplete,
            entity.services,
            entity.isRevoked
        );
    }
}