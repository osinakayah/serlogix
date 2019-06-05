pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "../contracts/SerlogixContract.sol";

contract TestSerlogixContract {
    uint public initialBalance = 11 ether;
    SerlogixContract serlogixContract ;
    function beforeEach() public {
        serlogixContract = new SerlogixContract();
    }

//    function testAddNewDriverFailure() public {
//        bool success = serlogixContract.addNewDriver.gas(200000)("Nora", "Ifea");
//        Assert.isFalse(success, "It should not create");
//    }
//
//    function testAddNewDriverSuccess() public {
//        bool success = serlogixContract.addNewDriver.value(1).gas(200000)("Nora", "Ifea");
//        Assert.isTrue(success, "It should create");
//        Assert.equal(1, address(serlogixContract).balance, "Contract balance");
//    }

//    function testGetDrivers() public {
//        address[] memory driverAddressesArray = serlogixContract.getArrayDrivers();
//        Assert.equal(0, driverAddressesArray.length, "Number of drivers");
//
//        bool success = serlogixContract.addNewDriver.value(1).gas(200000)("Nora", "Ife");
//        Assert.isTrue(success, "It should create");
//        Assert.equal(1, address(serlogixContract).balance, "Contract balance");
//
//        driverAddressesArray = serlogixContract.getArrayDrivers();
//        Assert.equal(1, driverAddressesArray.length, "Number of drivers");
//
//        (uint256 stackedWei, string memory firstName, string memory lastName) = serlogixContract.getDriver(address(driverAddressesArray[0]));
//         Assert.equal(1, stackedWei, "Stacked Wei");
//        Assert.equal("Nora", firstName, "First Name");
//        Assert.equal("Ife", lastName, "Lastname");
//
//    }

//    function testAddNewDeliverySuccess() public {
//        serlogixContract.addNewDriver.value(10).gas(2000000)("Nora", "Ife");
//        address[] memory driverAddressesArray = serlogixContract.getArrayDrivers();
//        uint256  initialBalance = address(this).balance;
//
//        uint  deliveryID = serlogixContract.addNewDelivery.value(10).gas(2000000)("Shoe",  address(uint160(driverAddressesArray[0])));
//        Assert.isTrue(deliveryID > 0, "It should create delivery");
//        Assert.equal((initialBalance - 10), address(this).balance,"It should create delivery");
//
//        (uint256 stackedWei, string memory firstName, string memory lastName) = serlogixContract.getDriver(address(driverAddressesArray[0]));
//        Assert.equal(10, stackedWei, "Stacked Wei");
//
//    }

//    function testAddNewDeliveryFailure() public {
//        serlogixContract.addNewDriver.value(5).gas(200000)("Nora", "Ife");
//        address[] memory driverAddressesArray = serlogixContract.getArrayDrivers();
//        uint256  initialBalance = address(this).balance;
//
//        uint  deliveryID = serlogixContract.addNewDelivery.value(10).gas(200000)("Shoe",  address(uint160(driverAddressesArray[0])));
//        Assert.equal(deliveryID,  0, "It should not create delivery");
//    }

//    function testAcceptDeliverySuccess() public {
//        serlogixContract.addNewDriver.value(10).gas(2000000)("Nora", "Ife");
//        address[] memory driverAddressesArray = serlogixContract.getArrayDrivers();
//
//
//        uint  deliveryID = serlogixContract.addNewDelivery.value(10).gas(2000000)("Shoe",  address(uint160(driverAddressesArray[0])));
//        Assert.isTrue(deliveryID > 0, "It should create delivery");
//
//        bool status = serlogixContract.acceptOrder(deliveryID);
//        Assert.isTrue(status, "Order Accepted");
//
//        (uint256 stackedWei, string memory firstName, string memory lastName) = serlogixContract.getDriver(address(driverAddressesArray[0]));
//        Assert.equal(0, stackedWei, "Stacked Wei");
//        (uint id, string memory itemName, uint256 deliveryCost, uint acceptedStatus, address payable driver, address initiator) = serlogixContract.getDelivery(deliveryID);
//        Assert.equal("Shoe", itemName, "Stacked Wei");
//        Assert.equal(acceptedStatus, 3, "Order in transit");
//    }

    function testCompleteDelivery() public {
        serlogixContract.addNewDriver.value(10).gas(2000000)("Nora", "Ife");
        address[] memory driverAddressesArray = serlogixContract.getArrayDrivers();


        uint  deliveryID = serlogixContract.addNewDelivery.value(10).gas(2000000)("Shoe",  address(uint160(driverAddressesArray[0])));
        Assert.isTrue(deliveryID > 0, "It should create delivery");

        bool status = serlogixContract.acceptOrder(deliveryID);
        Assert.isTrue(status, "Order Accepted");

        (bool completeStatus) = serlogixContract.completeDelivery(deliveryID);
        Assert.isTrue(completeStatus, "Order Completed");

        (uint ida, string memory itemNamea, uint256 deliveryCosta, uint acceptedStatusa, address payable drivera, address initiatora) = serlogixContract.getDelivery(deliveryID);

        Assert.equal(acceptedStatusa, 4, "Order in transit");
        (uint256 stackedWei, string memory firstName, string memory lastName) = serlogixContract.getDriver(address(driverAddressesArray[0]));
        Assert.equal(10, stackedWei, "Stacked Wei");
    }
}
