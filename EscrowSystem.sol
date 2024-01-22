// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract EnergyFuelEscrow {
    enum ServiceType { EV, NonEV }
    address public escrowAgent;

    struct Order {
        address buyer;
        address seller;
        uint256 amount;
        ServiceType serviceType;
        bool deliveryConfirmed;
    }

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;

    event OrderCreated(uint256 orderId, address buyer, address seller, uint256 amount, ServiceType serviceType);
    event OrderFulfilled(uint256 orderId, address seller);
    event OrderCancelled(uint256 orderId, address buyer);

    constructor(address _escrowAgent) {
        escrowAgent = _escrowAgent;
    }

    // Create a new order
    function createOrder(address seller, uint256 amount, ServiceType serviceType) external payable {
        require(msg.value == amount, "Incorrect value sent");

        Order memory newOrder = Order({
            buyer: msg.sender,
            seller: seller,
            amount: amount,
            serviceType: serviceType,
            deliveryConfirmed: false
        });

        orders[orderCount] = newOrder;
        emit OrderCreated(orderCount, msg.sender, seller, amount, serviceType);
        orderCount++;
    }

    // Confirm delivery
    function confirmDelivery(uint256 orderId) external {
        require(msg.sender == escrowAgent, "Only escrow agent can confirm delivery");
        
        Order storage order = orders[orderId];
        require(!order.deliveryConfirmed, "Delivery already confirmed");

        order.deliveryConfirmed = true;
        payable(order.seller).transfer(order.amount);
        emit OrderFulfilled(orderId, order.seller);
    }

    // Cancel order (refund)
    function cancelOrder(uint256 orderId) external {
        require(msg.sender == escrowAgent, "Only escrow agent can cancel order");
        
        Order storage order = orders[orderId];
        require(!order.deliveryConfirmed, "Order already fulfilled");

        payable(order.buyer).transfer(order.amount);
        emit OrderCancelled(orderId, order.buyer);
    }
}
