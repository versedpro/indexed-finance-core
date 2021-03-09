# @indexed-finance/indexed-core

[Documentation](https://docs.indexed.finance)

## Deploy

To deploy with proper verification on Etherscan, use the scripts in package.json.

The factory must be deployed first, followed by the controller. After these two, the pool, initializer and seller implementations can be deployed in any order.

The deploy scripts can be run with:

> `yarn deploy:<contract> <network>`

e.g.
> `yarn deploy:pool mainnet`

## Test

> `npm run test`

## Coverage

> `npm run coverage`

## Prerequisites

- Make sure that all dependencies are installed. running `yarn`.
- Please add *MAINNET_PVT_KEY, RINKEBY_PVT_KEY, INFURA_PROJECT_ID* into **.env** file.
- Use the scripts in package.json to build, test.
  - order by something like following
    - `yarn prepare-build`
    - `yarn build`
    - `yarn test`
  - You should see success result like this: 
    ```
    ...
        399 passing (9m)

    Done in 526.89s.
    ```
