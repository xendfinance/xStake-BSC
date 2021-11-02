# Documentation

This is a staking contract that can be used in several network like Ethereum, BSC, Polygon and etc.

The functionality of the staking contract is as follows.

- Users deposit token and it's locked in some time, and gives reward when users withdraw their tokens. `stakeToken` and `withdrawStakedTokens` are main entry function to deposit and withdraw tokens.

- Each deposit has its own identifier and all staking algorithm works based on the unit of the identifier. i.e. The reward/penalty amount of token is calculated inside of the identifier.

- Users can get current status of staking contract by passing staking identifier and address.

- Admin can pause or resume the staking.

- Admin can create an unlimited number of package. A package has properties of lock time, full staking period, reward percent, penalty percent and capacity of package.