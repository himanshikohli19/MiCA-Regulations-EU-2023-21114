// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPOrderTransmissionRegistry {
    struct OrderTransmission {
        address clientAddress;
        address destinationAddress;  // Trading platform or authorized CASP
        bytes32 orderHash;           // Hash of order details
        uint256 transmissionDate;
    }

    struct RoutingCompliance {
        bytes32 complianceHash;  // Hash of no-compensation commitment
        uint256 submissionDate;
    }

    struct OrderInfoProtection {
        bytes32 protectionHash;  // Hash of protection policy
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        OrderTransmission[] orderTransmissions;
        RoutingCompliance routingCompliance;
        OrderInfoProtection orderInfoProtection;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event OrderTransmissionLogged(address indexed casp, address indexed client, address destination);
    event RoutingComplianceSubmitted(address indexed casp);
    event OrderInfoProtectionSubmitted(address indexed casp);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
    }

    // Paragraph 1: Order Transmission Procedures
    function logOrderTransmission(
        address _caspAddress,
        address _clientAddress,
        address _destinationAddress,
        bytes32 _orderHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].orderTransmissions.push(OrderTransmission({
            clientAddress: _clientAddress,
            destinationAddress: _destinationAddress,
            orderHash: _orderHash,
            transmissionDate: block.timestamp
        }));
        emit OrderTransmissionLogged(_caspAddress, _clientAddress, _destinationAddress);
    }

    // Paragraph 2: Ban on Preferential Order Routing
    function submitRoutingCompliance(
        address _caspAddress,
        bytes32 _complianceHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].routingCompliance = RoutingCompliance({
            complianceHash: _complianceHash,
            submissionDate: block.timestamp
        });
        emit RoutingComplianceSubmitted(_caspAddress);
    }

    // Paragraph 3: Protection of Client Order Information
    function submitOrderInfoProtection(
        address _caspAddress,
        bytes32 _protectionHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].orderInfoProtection = OrderInfoProtection({
            protectionHash: _protectionHash,
            submissionDate: block.timestamp
        });
        emit OrderInfoProtectionSubmitted(_caspAddress);
    }
}