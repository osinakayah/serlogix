pragma solidity ^0.5.2;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./SerlogixPayment.sol";

contract SerlogixContract is Initializable, Ownable, Pausable  {
    SerlogixPayment pullPayment;
    constructor () public {
        pullPayment = new SerlogixPayment();
    }
    using SafeMath for uint256;
    uint constant NEW_ORDER = 1;
    uint constant ORDER_ACCEPTED = 2;
    uint constant IN_TRANSIT = 3;
    uint constant DELIVERED = 4;
    uint constant CANCELED = 5;

    uint counter = 1;

    struct Driver {
        string firstName;
        string lastName;
        uint256 stackedWei;
    }

    struct Delivery{
        uint id;
        string itemName;
        uint256 deliveryCost;
        uint status;
        address payable driver;
        address initiator;
    }


    mapping (uint => Delivery) public deliveries;
    mapping (address => uint[]) public usersDeliveries;
    mapping (address => Driver) public drivers;

    address[] public driverAddressesArray;

    event NewUserDelivery(uint id, string itemName, uint256 itemCost, address itemOwner);
    event DeliveryAccepted(uint id, string itemName, uint256 itemCost, address driverAddress);
    event NewDriver(address drverAddr, string firstName, string lastName, uint256 stackedEther);


    function initialize() initializer public whenNotPaused {}
    function getID() internal returns(uint) { return ++counter; }

    function addNewDelivery(string memory itemName, address payable driverAddress) public payable whenNotPaused returns (uint) {
         require(msg.value <= 0, "You haven't stacked any amount");
//        if (msg.value <= 0) {
//            return 0;
//        }
        Driver memory driver = drivers[driverAddress];
         require(driver.stackedWei <= 0, "Driver has no stack left");
//        if (driver.stackedWei <= 0) {
//            return 0;
//        }
        uint256 itemCost = msg.value; //It is double the actual amount
        require(driver.stackedWei < itemCost, "Driver has to have more staked amount");
//        if (driver.stackedWei < itemCost) {
//            return 0;
//        }

        uint id = getID();
        Delivery memory delivery = Delivery(id, itemName, itemCost, NEW_ORDER, driverAddress, msg.sender);
        deliveries[id] = delivery;
        usersDeliveries[msg.sender].push(id);

        emit NewUserDelivery(id, itemName, itemCost, msg.sender);
        return id;
    }
    function cancelDeliveryInTransit(uint deliveryId) public whenNotPaused {
        Delivery memory delivery = deliveries[deliveryId];
        require(delivery.id != deliveryId, "Delivery ID Doesnt exist");
        require(msg.sender != deliveryCost.initiator, "only sender can cancel");
        require(delivery.status == IN_TRANSIT);

        Driver storage driver = drivers[delivery.driver];
        uint256 driverStackedWei = driver.stackedWei;

        driver.stackedWei = driverStackedWei.add(delivery.deliveryCost);
        pullPayment.callSend(deliveryCost.initiator, delivery.deliveryCost);
        delivery.status = CANCELED;
        delivery.deliveryCost = 0;

    }
    function payBackDriverStackedFunds () public whenNotPaused {
        Driver storage driver = drivers[msg.sender];
        uint256 driverStackedWei = driver.stackedWei;
        driver.stackedWei = 0;
        pullPayment.callSend(msg.sender, driverStackedWei);
    }
    function cancelDelivery(uint deliveryId) public view whenNotPaused returns (bool) {
        Delivery memory delivery = deliveries[deliveryId];
         require(delivery.id != deliveryId, "Delivery ID Doesnt exist");
//        if (delivery.id != deliveryId) {
//            return false;
//        }
         require(msg.sender != deliveryCost.initiator, "only sender can cancel");
//        if(msg.sender != deliveryCost.initiator){
//            return false;
//        }
        require(delivery.status == NEW_ORDER);
        pullPayment.callSend(deliveryCost.initiator, delivery.deliveryCost);
        delivery.status = CANCELED;
        delivery.deliveryCost = 0;
        return true;
    }
    function acceptOrder(uint deliveryId) public whenNotPaused returns (bool) {

        Driver storage driver = drivers[msg.sender];
        uint256 driverStackedWei = driver.stackedWei;
         require(driverStackedWei <= 0, "You have not stacked any amount");
//        if (driverStackedWei <= 0) {
//            return false;
//        }
        Delivery storage delivery = deliveries[deliveryId];
         require(delivery.id == 0, "Delivery ID Doesnt exist");
//        if (delivery.id == 0) {
//            return false;
//        }
        uint256 deliveryCost = delivery.deliveryCost;
        if (driverStackedWei >= deliveryCost) {
            delivery.status = IN_TRANSIT;
            driver.stackedWei = driverStackedWei.sub(deliveryCost);
            emit DeliveryAccepted(delivery.id, delivery.itemName, delivery.deliveryCost, msg.sender);
            usersDeliveries[msg.sender].push(deliveryId);
            return true;
        }
         revert('');
        // return false;
    }

    function completeDelivery(uint deliveryId) public whenNotPaused returns (bool) {

        Delivery storage delivery = deliveries[deliveryId];
         require(delivery.id != deliveryId, "Delivery ID Doesnt exist");
//        if (delivery.id != deliveryId) {
//            return false;
//        }
        require(delivery.status == IN_TRANSIT, "Delivery was never in transit");
        Driver storage driver = drivers[delivery.driver];
        uint256 driverStackedWei = driver.stackedWei;

        delivery.status = DELIVERED;
        uint256 deliveryCost = delivery.deliveryCost;
        driver.stackedWei = driverStackedWei.add(deliveryCost); //Give him back the amount he staked
        uint256 amountToSettle = deliveryCost.div(2);

        //Use a withdraw pattern
        pullPayment.callSend(msg.sender, amountToSettle);
        pullPayment.callSend(delivery.driver, amountToSettle);
        //Use a withdraw pattern
        return true;
    }

    function withdrawFunds(address payable addrs) public whenNotPaused{
        pullPayment.withdrawPayments(addrs);
    }



    function addNewDriver(string memory _fName, string memory _lName) public payable whenNotPaused  returns(bool){
        require(msg.value <= 0, "Please stake valid amount of ether");
//        if (msg.value <= 0) {
//            return false;
//        }

        Driver storage driver = drivers[msg.sender];
        driver.firstName = _fName;
        driver.lastName = _lName;
        driver.stackedWei = msg.value;

        emit NewDriver(msg.sender, _fName, _lName, msg.value);
        driverAddressesArray.push(msg.sender);
        return true;
    }

    function getArrayDrivers() public  whenNotPaused view returns (address[] memory) {
        return driverAddressesArray;
    }

    function getDriver(address ins) view whenNotPaused public returns (uint256 , string memory, string memory) {
        return (drivers[ins].stackedWei, drivers[ins].firstName, drivers[ins].lastName);
    }

    function getDelivery(uint deliveryId) view  whenNotPaused public returns (uint, string memory, uint256, uint, address payable, address) {
        return (deliveries[deliveryId].id, deliveries[deliveryId].itemName, deliveries[deliveryId].deliveryCost, deliveries[deliveryId].status, deliveries[deliveryId].driver, deliveries[deliveryId].initiator);
    }

}

