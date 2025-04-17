// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CASPExchangeRegistry {
    struct CommercialPolicy {
        bytes32 policyHash;  // Hash of client eligibility and conditions
        uint256 submissionDate;
    }

    struct PricingDetails {
        bytes32 pricingHash;  // Hash of fixed prices or methodology
        uint256 exchangeLimit;
        uint256 submissionDate;
    }

    struct TradeExecution {
        address clientAddress;
        bytes32 tradeHash;  // Hash of trade details
        uint256 executionPrice;
        uint256 executionDate;
    }

    struct PostTradeData {
        bytes32 tradeDataHash;  // Hash of aggregated volumes and prices
        uint256 submissionDate;
    }

    struct CASP {
        bool isAuthorized;
        CommercialPolicy commercialPolicy;
        PricingDetails pricingDetails;
        TradeExecution[] tradeExecutions;
        PostTradeData postTradeData;
    }

    mapping(address => CASP) public casps;
    mapping(address => bool) public caspAuthority;

    event CommercialPolicySubmitted(address indexed casp);
    event PricingDetailsSubmitted(address indexed casp, uint256 exchangeLimit);
    event TradeExecutionLogged(address indexed casp, address indexed client);
    event PostTradeDataSubmitted(address indexed casp);

    modifier onlyCASP() {
        require(caspAuthority[msg.sender], "Only CASP can call this function");
        _;
    }

    constructor(address[] memory _casps) {
        for (uint i = 0; i < _casps.length; i++) {
            caspAuthority[_casps[i]] = true;
        }
    }

    // Paragraph 1: Non-Discriminatory Commercial Policy
    function submitCommercialPolicy(
        address _caspAddress,
        bytes32 _policyHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].commercialPolicy = CommercialPolicy({
            policyHash: _policyHash,
            submissionDate: block.timestamp
        });
        emit CommercialPolicySubmitted(_caspAddress);
    }

    // Paragraph 2: Transparent Pricing
    function submitPricingDetails(
        address _caspAddress,
        bytes32 _pricingHash,
        uint256 _exchangeLimit
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].pricingDetails = PricingDetails({
            pricingHash: _pricingHash,
            exchangeLimit: _exchangeLimit,
            submissionDate: block.timestamp
        });
        emit PricingDetailsSubmitted(_caspAddress, _exchangeLimit);
    }

    // Paragraph 3: Execution at Published Prices
    function logTradeExecution(
        address _caspAddress,
        address _clientAddress,
        bytes32 _tradeHash,
        uint256 _executionPrice
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].tradeExecutions.push(TradeExecution({
            clientAddress: _clientAddress,
            tradeHash: _tradeHash,
            executionPrice: _executionPrice,
            executionDate: block.timestamp
        }));
        emit TradeExecutionLogged(_caspAddress, _clientAddress);
    }

    // Paragraph 4: Post-Trade Transparency
    function submitPostTradeData(
        address _caspAddress,
        bytes32 _tradeDataHash
    ) external onlyCASP {
        require(casps[_caspAddress].isAuthorized, "CASP not authorized");
        casps[_caspAddress].postTradeData = PostTradeData({
            tradeDataHash: _tradeDataHash,
            submissionDate: block.timestamp
        });
        emit PostTradeDataSubmitted(_caspAddress);
    }
}