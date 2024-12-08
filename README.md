Link to the video: https://drive.google.com/drive/u/0/folders/1Putt2CvD7P5MdVzsl9AM78bjmRkmnDAp

Link to the deck: https://docs.google.com/presentation/d/1BImiWRa0F6AOFCHcwX5h8fu2icZKXuTrdAQNBG7xGHQ/edit?usp=sharing

This hook implements the idea of a volatility compliant swap. It's intended to be used by institutions, who need to perform swaps in a compliant environment.

This hook uses the **beforeSwap** and **beforeSwapReturnsDelta** flags, in order to be a NoOp hook, in case the transaction doesn't meet the criteria. The compliance criteria starts with a whitelist check: 
both the token0 and token1 must be whitelisted in order to be traded. After that, I calculate the user's portifolio volatility, which is a sum of the volatility of all of the user's assets (for simplicity, 
we are considering only the whitelisted tokens here) weighted by its price and percentage on the user's portfolio. After that, I calculate what is the expected delta in volatility if that swaps occurs.
 With that information, I have the expected volatility of the user's portfolio if the swap happens. This way, I simply check if this result is smaller than the max volatility allowed (informed by the user).
 If it is not, the swap doesn't happen, performing like a NoOp hook.

 In order to achieve that, all of the logic is written in Arbitrum Stylus, in order to do the computations in a cheaper way than using EVM.

 ## Deployed Contracts (Arbitrum)

 - Risk Manager Contract (Stylus): [0x086ccaf62d35e15300f8719c950a90269f9d72c6](https://sepolia.arbiscan.io/address/0x086ccaf62d35e15300f8719c950a90269f9d72c6)
 - Hook Address: [0x46da141D7c712824c04Ab1d3216C8368860f0088](https://sepolia.arbiscan.io/address/0x46da141D7c712824c04Ab1d3216C8368860f0088)
 - Pool Manager (Uniswap v4):  [0xc420C3A3F81f2A059fF56D45c0A82D1F9aF38dCc](https://sepolia.arbiscan.io/address/0xc420C3A3F81f2A059fF56D45c0A82D1F9aF38dCc)
 - PoolSwapTest: [0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB](https://sepolia.arbiscan.io/address/0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB)
 - PoolModifyLiquidityTest: [0x2298870DB1Fa24F3F6cc1fa0B2760AB7c1803bC1](https://sepolia.arbiscan.io/address/0x2298870DB1Fa24F3F6cc1fa0B2760AB7c1803bC1)

## Tokens and Oracles deployed for tests (Arbitrum)
- WBTC token: [0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7](https://sepolia.arbiscan.io/address/0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7)
- WBTC price oracle: [0x2EfFBDd18E77C646F79735E320c7A69816995e29](https://sepolia.arbiscan.io/address/0x2EfFBDd18E77C646F79735E320c7A69816995e29)
- WBTC volatitlity oracle: [0xf45D07E6083e3835536e38Eaf3D10d7aEacE31C3](https://sepolia.arbiscan.io/address/0xf45D07E6083e3835536e38Eaf3D10d7aEacE31C3)
- WETH token: [0xf21B5d9574d84eF4c253132691D76F62FEE4Daab](https://sepolia.arbiscan.io/address/0xf21B5d9574d84eF4c253132691D76F62FEE4Daab)
- WETH price oracle: [0x11c2C521E7dc24491Cae35979ab1032E80Bbf6e1](https://sepolia.arbiscan.io/address/0x11c2C521E7dc24491Cae35979ab1032E80Bbf6e1)
- WETH volatility oracle: [0xa5D8dc3f4F3a355064A32642EC6e5d178F161Cc3](https://sepolia.arbiscan.io/address/0xa5D8dc3f4F3a355064A32642EC6e5d178F161Cc3)

 
 


