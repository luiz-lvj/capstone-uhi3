cargo stylus deploy --endpoint=$ARB_SEPOLIA_STYLUS_RPC_URL --private-key=$PRIVATE_KEY

cast send --rpc-url $ARB_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY 0x086ccaf62d35e15300f8719c950a90269f9d72c6 "init()"

cast send --rpc-url $ARB_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY 0x086ccaf62d35e15300f8719c950a90269f9d72c6 "addWhitelistedToken(address, address, address)" 0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7 0x2EfFBDd18E77C646F79735E320c7A69816995e29 0xf45D07E6083e3835536e38Eaf3D10d7aEacE31C3

 cast send --rpc-url $ARB_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY 0x086ccaf62d35e15300f8719c950a90269f9d72c6 "addWhitelistedToken(address, address, address)" 0xf21B5d9574d84eF4c253132691D76F62FEE4Daab 0x11c2C521E7dc24491Cae35979ab1032E80Bbf6e1 0xa5D8dc3f4F3a355064A32642EC6e5d178F161Cc3

 cast send --rpc-url $ARB_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY 0x086ccaf62d35e15300f8719c950a90269f9d72c6 "allowedSwap(address,int256,address,int256,address,int256)" 0x000ef5F21dC574226A06C76AAE7060642A30eB74 1000000 0xf21B5d9574d84eF4c253132691D76F62FEE4Daab 100000000000000000 0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7 100000000000000000




funciona

cast send 0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB \
"swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)" \
"(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7,0xf21B5d9574d84eF4c253132691D76F62FEE4Daab,3000,120,0x8133De27B31fbf57C0de8F4d5A083B62c8d08040)" \
"(false,-100000000000000000,1461446703485210103287273052203988822378723970341)" "(false, false)" \
"0x000000000000000000000000000ef5f21dc574226a06c76aae7060642a30eb740000000000000000000000000000000000000000000000000000000000000000" --private-key $PRIVATE_KEY --rpc-url $ARB_SEPOLIA_RPC_URL




cast send 0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB \
"swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)" \
"(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7,0xf21B5d9574d84eF4c253132691D76F62FEE4Daab,3000,120,0x8133De27B31fbf57C0de8F4d5A083B62c8d08040)" \
"(false,-100000000000000000,1461446703485210103287273052203988822378723970341)" "(false, false)" \
"0x000000000000000000000000000ef5f21dc574226a06c76aae7060642a30eb7400000000000000000000000000000000000000000000000000000000000f4240" --private-key $PRIVATE_KEY --rpc-url $ARB_SEPOLIA_RPC_URL


cast send 0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB \
"swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)" \
"(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7,0xf21B5d9574d84eF4c253132691D76F62FEE4Daab,3000,120,0x7E0C31C8fF8f1e6Ef42fc25B3DAacdB806B90040)" \
"(true,-100000000000000000,4295128740)" "(false, false)" \
"0x000000000000000000000000000ef5f21dc574226a06c76aae7060642a30eb7400000000000000000000000000000000000000000000000000000000000f4240" --private-key $PRIVATE_KEY --rpc-url $ARB_SEPOLIA_RPC_URL


 cast send 0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB \
"swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)" \
"(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7,0xf21B5d9574d84eF4c253132691D76F62FEE4Daab,3000,120,0x7E0C31C8fF8f1e6Ef42fc25B3DAacdB806B90040)" \
"(true,-100000000000000000,4295128740)" "(false, false)" \
"0x000000000000000000000000000ef5f21dc574226a06c76aae7060642a30eb7400000000000000000000000000000000000000000000000000000000000f4240" --private-key $PRIVATE_KEY --rpc-url $ARB_SEPOLIA_RPC_URL