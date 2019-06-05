pragma solidity ^0.5.2;
import 'openzeppelin-solidity/contracts/payment/PullPayment.sol';
contract SerlogixPayment is PullPayment {
    function callSend(address payable dest, uint256 amount) public {
        _asyncTransfer(dest, amount);
    }
}
