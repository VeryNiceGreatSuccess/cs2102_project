# CS2102 Project (Part 2)

⏰ Due on ***8 April 2022***

## Constraints to be Enforced using Triggers
#### Product related:
(1) Each shop should sell at least one product.
#### Order related:
(2) An order must involve one or more products from one or more shops.
#### Coupon related:
(3) A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds
the minimum order amount.
#### Refund related:
(4) The refund quantity must not exceed the ordered quantity.\
(5) The refund request date must be within 30 days of the delivery date.\
(6) Refund request can only be made for a delivered product.
#### Comment related:
(7) A user can only make a product review for a product that they themselves purchased.\
(8) A comment is either a review or a reply, not both (non-overlapping and covering).\
(9) A reply has at least one reply version.\
(10) A review has at least one review version.
#### Complaint related:
(11) A delivery complaint can only be made when the product has been delivered.\
(12) A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related
complaint (non-overlapping and covering).

