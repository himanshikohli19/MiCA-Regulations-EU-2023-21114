// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Article 64: Withdrawal of CASP Authorization under MiCA
contract CASPWithdrawalRegistry {
    // Enum defining crypto-asset services per MiCA
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    // Struct to track CASP authorization and withdrawal status
    struct CASP {
        address caspAddress;
        bool isAuthorized;
        bool isActive;
        uint256 authorizationDate;
        uint256 lastActivityDate;
        string withdrawalReason;
        CryptoService[] services;
        bytes32 consultationProof;
        bool reassessmentRequested;
        string reassessmentReason;
        bytes32 windDownPlan;
    }

    // Storage mappings
    mapping(address => CASP) public casps;
    mapping(address => bool) public ncAuthority;

    // Events
    event AuthorizationWithdrawn(address indexed casp, string reason, bool isFullWithdrawal);
    event WithdrawalNotified(address indexed casp, string reason);
    event ConsultationSubmitted(address indexed casp);
    event ReassessmentRequested(address indexed casp, string reason);
    event WindDownPlanSubmitted(address indexed casp);

    // Modifier to restrict functions to NCAs
    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    // Constructor to initialize NCAs
    constructor(address[] memory _ncas) {
        for (uint256 i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    // Register a new CASP
    function registerCASP(address _caspAddress, CryptoService[] memory _services) external onlyNCA {
        require(!casps[_caspAddress].isAuthorized, "CASP already authorized");
        require(_caspAddress != address(0), "Invalid address");

        CASP storage casp = casps[_caspAddress];
        casp.caspAddress = _caspAddress;
        casp.isAuthorized = true;
        casp.isActive = true;
        casp.authorizationDate = block.timestamp;
        casp.lastActivityDate = block.timestamp;
        casp.services = _services;
    }

    // Mandatory withdrawal for non-use or inactivity
    function withdrawAuthorization(address _caspAddress, string memory _reason) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");

        CASP storage casp = casps[_caspAddress];

        if (keccak256(bytes(_reason)) == keccak256("NonUse")) {
            require(block.timestamp >= casp.authorizationDate + 365 days, "12-month non-use period not met");
        } else if (keccak256(bytes(_reason)) == keccak256("Inactivity")) {
            require(block.timestamp >= casp.lastActivityDate + 270 days, "9-month inactivity period not met");
        }

        casp.isAuthorized = false;
        casp.isActive = false;
        casp.withdrawalReason = _reason;

        emit AuthorizationWithdrawn(_caspAddress, _reason, true);
    }

    // Update last activity date
    function updateLastActivity(address _caspAddress) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].lastActivityDate = block.timestamp;
    }

    // Discretionary withdrawal by NCA
    function discretionaryWithdrawal(
        address _caspAddress,
        string memory _reason,
        uint256 _violationDate
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");

        if (keccak256(bytes(_reason)) == keccak256("LostPaymentLicense")) {
            require(block.timestamp >= _violationDate + 40 days, "40-day fix period not elapsed");
        }

        CASP storage casp = casps[_caspAddress];
        casp.isAuthorized = false;
        casp.isActive = false;
        casp.withdrawalReason = _reason;

        emit AuthorizationWithdrawn(_caspAddress, _reason, true);
    }

    // Notify withdrawal to ESMA and other authorities
    function notifyWithdrawal(address _caspAddress) external onlyNCA {
        require(!casps[_caspAddress].isAuthorized, "CASP still authorized");
        emit WithdrawalNotified(_caspAddress, casps[_caspAddress].withdrawalReason);
    }

    // Check if CASP can operate (simplified state check)
    function canOperateInState(address _caspAddress, string memory /* _state */) public view returns (bool) {
        CASP storage casp = casps[_caspAddress];
        return casp.isAuthorized && casp.isActive;
    }

    // Partial withdrawal of specific services
    function partialWithdrawal(
        address _caspAddress,
        CryptoService[] memory _servicesToRemove,
        string memory _reason
    ) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");

        CASP storage casp = casps[_caspAddress];
        CryptoService[] storage services = casp.services;

        for (uint256 i = 0; i < _servicesToRemove.length; i++) {
            for (uint256 j = 0; j < services.length; j++) {
                if (services[j] == _servicesToRemove[i]) {
                    services[j] = services[services.length - 1];
                    services.pop();
                    break;
                }
            }
        }

        emit AuthorizationWithdrawn(_caspAddress, _reason, false);
    }

    // Consultation with other NCAs before withdrawal
    function submitConsultationProof(address _caspAddress, bytes32 _consultationHash) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");

        CASP storage casp = casps[_caspAddress];
        casp.consultationProof = _consultationHash;

        emit ConsultationSubmitted(_caspAddress);
    }

    // Request reassessment before final withdrawal
    function requestReassessment(address _caspAddress, string memory _reason) external onlyNCA {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");

        CASP storage casp = casps[_caspAddress];
        casp.reassessmentRequested = true;
        casp.reassessmentReason = _reason;

        emit ReassessmentRequested(_caspAddress, _reason);
    }

    // Submit wind-down plan to protect client assets
    function submitWindDownPlan(address _caspAddress, bytes32 _windDownPlanHash) external onlyNCA {
        CASP storage casp = casps[_caspAddress];
        require(casp.isAuthorized || !casp.isActive, "CASP must be under withdrawal process");

        casp.windDownPlan = _windDownPlanHash;

        emit WindDownPlanSubmitted(_caspAddress);
    }
}