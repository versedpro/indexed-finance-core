pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MockERC20.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";
import { BPool } from "../balancer/BPool.sol";
import "../balancer/BMath.sol";
import "../MarketOracle.sol";

contract MockTokenMarketDeployer is BMath {
  MockERC20 public weth;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;

  event TokenDeployed(address token);

  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  constructor(
    MockERC20 _weth,
    IUniswapV2Factory _factory,
    IUniswapV2Router02 _router
  ) public {
    weth = _weth;
    factory = _factory;
    router = _router;
  }

  function computePoolValue(
    MarketOracle oracle,
    BPool pool
  ) external view returns (uint256) {
    address[] memory tokens = pool.getCurrentTokens();
    uint256 totalValue = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = pool.getBalance(token);
      uint256 balValue = oracle.computeAverageAmountOut(token, bal);
      totalValue += balValue;
    }
    return totalValue;
  }

  function deployTokenAndMarketWithLiquidity(
    string memory name,
    string memory symbol,
    uint256 amountToken,
    uint256 amountWeth
  ) public {
    MockERC20 token = new MockERC20(name, symbol);
    emit TokenDeployed(address(token));
    factory.createPair(address(token), address(weth));
    addLiquidity(token, amountToken, amountWeth);
  }

  function addLiquidity(
    MockERC20 token,
    uint256 amountToken,
    uint256 amountWeth
  ) public {
    token.getFreeTokens(address(this), amountToken);
    weth.getFreeTokens(address(this), amountWeth);
    token.approve(address(router), amountToken);
    weth.approve(address(router), amountWeth);
    router.addLiquidity(
      address(token),
      address(weth),
      amountToken,
      amountWeth,
      amountToken,
      amountWeth,
      address(this),
      now + 1
    );
  }

  function deployPoolMarketWithLiquidity(
    BPool pool,
    uint256 amountPool,
    uint256 amountWeth
  ) public {
    
    factory.createPair(address(pool), address(weth));
    mintPoolTokens(pool, amountPool);
    pool.approve(address(router), amountPool);
    weth.getFreeTokens(address(this), amountWeth);
    weth.approve(address(router), amountWeth);
  }

  function addPoolMarketLiquidity(
    BPool pool,
    uint256 amountPool,
    uint256 amountWeth
  ) public {
    mintPoolTokens(pool, amountPool);
    pool.approve(address(router), amountPool);
    weth.getFreeTokens(address(this), amountWeth);
    weth.approve(address(router), amountWeth);
    router.addLiquidity(
      address(pool),
      address(weth),
      amountPool,
      amountWeth,
      amountPool,
      amountWeth,
      address(this),
      now + 1
    );
  }

  function mintPoolTokens(
    BPool pool,
    uint256 poolAmountOut
  ) public {
    uint256 poolTotal = pool.totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    address[] memory tokens = pool.getCurrentTokens();
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 usedBalance = pool.getUsedBalance(token);
      uint256 tokenAmountIn = bmul(ratio, usedBalance);
      MockERC20(token).getFreeTokens(address(this), tokenAmountIn);
      MockERC20(token).approve(address(pool), tokenAmountIn);
      maxAmountsIn[i] = tokenAmountIn;
    }
    pool.joinPool(
      poolAmountOut,
      maxAmountsIn
    );
  }
}