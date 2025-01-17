// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ConvertToUSD {
    // 通过合同地址确定real world中挂钩的事务

    function getLatestPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        // (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10 ** 10); //保留汇率转换的小数位
    }

    //ethAmout单位位wei，从而可以保留许多小数位的eth表示
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getLatestPrice(priceFeed);
        uint256 convertedUsdValue = (ethPrice * ethAmount) / 10 ** 18;
        return convertedUsdValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./ConvertToUSD.sol";

error NotOwner();

contract FundMe {
    //调用library
    using ConvertToUSD for uint256;
    /*
        1. 依据chainlink将一定数量的ETH转变为USD表示的数字  ETH/USD: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        为保留小数位，ethAmount需用wei，USD的单位也变相使用wei进行表示
    */
    uint256 public constant MINIMUM_USD = 8.366586 * 10 ** 18;

    address[] public funders;
    mapping(address => uint256) public addressToAmount;

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "You need spend more ETH!");
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need spend more ETH!"
        );
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }

        funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "You are not the money's owner!");
        if (msg.sender != i_owner) revert NotOwner();
        _; //表示后面的全部代码
    }

    //意外调用直接重定向至fund；可依据合同地址直接进行fund
    receive() external payable {
        fund();
    }

    //有函数调用即存在msg.data，但是合同中不包含该函数，意外调用直接重定向至fund；
    fallback() external payable {
        fund();
    }
}