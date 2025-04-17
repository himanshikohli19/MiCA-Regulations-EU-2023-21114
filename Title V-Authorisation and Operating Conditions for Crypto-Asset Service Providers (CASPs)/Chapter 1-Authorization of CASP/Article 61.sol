// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Article 61
contract ReverseSolicitationRegistry {
    enum CryptoService {
        Custody,
        TradingPlatform,
        Exchange,
        OrderExecution,
        Advice,
        PortfolioManagement,
        Transfer
    }

    struct ClientRequest {
        address clientAddress;
        CryptoService service;
        uint256 requestDate;
    }

    struct ExemptFirm {
        address firmAddress;
        string country;
        bool isRegistered;
        bool isExemptionValid;
        bool isFlagged;
        CryptoService[] services;
        ClientRequest[] clientRequests;
    }

    mapping(address => ExemptFirm) public firms;
    mapping(address => bool) public ncAuthority;

    event FirmRegistered(address indexed firm, string country, address client, CryptoService initialService);
    event ExemptionApproved(address indexed firm);
    event ServiceRequested(address indexed firm, address client, CryptoService service);
    event SolicitationFlagged(address indexed firm, string reason);

    modifier onlyNCA() {
        require(ncAuthority[msg.sender], "Only NCA can call this function");
        _;
    }

    constructor(address[] memory _ncas) {
        for (uint i = 0; i < _ncas.length; i++) {
            ncAuthority[_ncas[i]] = true;
        }
    }

    function registerExemptFirm(
        address _firmAddress,
        string memory _country,
        address _clientAddress,
        CryptoService _initialService
    ) external {
        require(!firms[_firmAddress].isRegistered, "Firm already registered");
        require(!isEUCountry(_country), "Firm must be non-EU");
        require(_firmAddress != address(0), "Invalid firm address");
        require(_clientAddress != address(0), "Invalid client address");

        ExemptFirm storage firm = firms[_firmAddress];
        firm.firmAddress = _firmAddress;
        firm.country = _country;
        firm.isRegistered = true;
        firm.isExemptionValid = false;
        firm.isFlagged = false;
        
        // Initialize with first service request
        firm.clientRequests.push(ClientRequest({
            clientAddress: _clientAddress,
            service: _initialService,
            requestDate: block.timestamp
        }));

        emit FirmRegistered(_firmAddress, _country, _clientAddress, _initialService);
    }

    function approveExemption(address _firmAddress) external onlyNCA {
        ExemptFirm storage firm = firms[_firmAddress];
        require(firm.isRegistered, "Firm not registered");
        require(!firm.isExemptionValid, "Exemption already approved");
        require(!firm.isFlagged, "Firm is flagged");

        firm.isExemptionValid = true;
        firm.services.push(firm.clientRequests[0].service);

        emit ExemptionApproved(_firmAddress);
    }

    function isEUCountry(string memory _country) internal pure returns (bool) {
        bytes32 countryHash = keccak256(abi.encodePacked(_country));
        return countryHash == keccak256(abi.encodePacked("Germany")) || 
               countryHash == keccak256(abi.encodePacked("France")) || 
               countryHash == keccak256(abi.encodePacked("Italy")) || 
               countryHash == keccak256(abi.encodePacked("Spain"));
    }

    function requestService(
        address _firmAddress,
        address _clientAddress,
        CryptoService _service
    ) external {
        ExemptFirm storage firm = firms[_firmAddress];
        require(firm.isRegistered, "Firm not registered");
        require(firm.isExemptionValid, "Exemption not approved");
        require(msg.sender == _clientAddress, "Only client can request");
        require(isServiceAllowed(_firmAddress, _service), "Service not authorized");

        // Check for duplicate requests
        for (uint i = 0; i < firm.clientRequests.length; i++) {
            if (firm.clientRequests[i].clientAddress == _clientAddress &&
                firm.clientRequests[i].service == _service) {
                revert("Service already requested by this client");
            }
        }

        firm.clientRequests.push(ClientRequest({
            clientAddress: _clientAddress,
            service: _service,
            requestDate: block.timestamp
        }));

        emit ServiceRequested(_firmAddress, _clientAddress, _service);
    }

    function isServiceAllowed(address _firmAddress, CryptoService _service) public view returns (bool) {
        ExemptFirm storage firm = firms[_firmAddress];
        if (!firm.isExemptionValid || firm.isFlagged) return false;
        
        for (uint i = 0; i < firm.services.length; i++) {
            if (firm.services[i] == _service) return true;
        }
        return false;
    }

    function flagSolicitation(address _firmAddress, string memory _reason) external onlyNCA {
        ExemptFirm storage firm = firms[_firmAddress];
        require(firm.isRegistered, "Firm not registered");
        
        firm.isExemptionValid = false;
        firm.isFlagged = true;
        emit SolicitationFlagged(_firmAddress, _reason);
    }

    function getFirmDetails(address _firmAddress) public view returns (
        string memory country,
        bool isRegistered,
        bool isExemptionValid,
        bool isFlagged,
        CryptoService[] memory services,
        uint clientRequestCount
    ) {
        ExemptFirm storage firm = firms[_firmAddress];
        return (
            firm.country,
            firm.isRegistered,
            firm.isExemptionValid,
            firm.isFlagged,
            firm.services,
            firm.clientRequests.length
        );
    }
}