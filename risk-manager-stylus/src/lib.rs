//!
//! Risk Manager
//!
//! The following contract implements the Counter example from Foundry.
//!
//! ```
//! contract Counter {
//!     uint256 public number;
//!     function setNumber(uint256 newNumber) public {
//!         number = newNumber;
//!     }
//!     function increment() public {
//!         number++;
//!     }
//! }
//! ```
//!
//! The program is ABI-equivalent with Solidity, which means you can call it from both Solidity and Rust.
//! To do this, run `cargo stylus export-abi`.
//!
//! Note: this code is a template-only and has not been audited.
//!

// Allow `cargo stylus export-abi` to generate a main function.
#![cfg_attr(not(feature = "export-abi"), no_main)]
extern crate alloc;

/// Import items from the SDK. The prelude contains common traits and macros.
use stylus_sdk::{alloy_primitives::{I256,  Address}, prelude::*, msg};

use stylus_sdk::alloy_sol_types::sol;
// Define some persistent storage using the Solidity ABI.
// `Counter` will be the entrypoint.
sol_storage! {
    #[entrypoint]
    pub struct RiskManager {
        address owner;
        //bool initialized;
        TokensInfo[] tokens;

        mapping(address => bool) whitelisted_tokens;
        mapping(address => address) tokens_to_price_oracles;
        mapping(address => address) tokens_to_vol_oracles;
    }

    pub struct TokensInfo {
        address token;
    }
}

// Declare events and Solidity error types
sol! {

    // event OwnerSet(address indexed owner);
    // event TokenWhitelisted(address indexed token, address indexed price_oracle, address indexed vol_oracle);

    error NotOwner(address owner, address caller);
    error TokenAlreadyWhitelisted(address token);

    error TokenNotWhitelisted(address token);
}


sol_interface! {
    interface IChainlinkFeed {
        function latestRoundData() external  view returns (int256);

    }

    interface ERC20 {
        function balanceOf(address) external view returns (uint256);
    }
}

#[derive(SolidityError)]
pub enum RiskManagerError {
    NotOwner(NotOwner),
    TokenAlreadyWhitelisted(TokenAlreadyWhitelisted),
    TokenNotWhitelisted(TokenNotWhitelisted),
}

/// Declare that `Counter` is a contract with the following external methods.
#[public]
impl RiskManager {

    pub fn init(&mut self) -> Result<(), Vec<u8>> {

        // if self.initialized.get() {
        //     return Ok(());
        // }
        // self.initialized.set(true);

        self.owner.set(msg::sender());
        Ok(())
    }


    /// Gets the owner from storage.
    pub fn owner(&self) -> Address {
        self.owner.get()
    }

    /// Sets the owner in storage to a user-specified value.
    // pub fn set_owner(&mut self, new_owner: Address)  -> Result<(), RiskManagerError> {

    //     if msg::sender() != self.owner.get() {
    //         return Err(RiskManagerError::NotOwner(NotOwner { owner: self.owner.get(), caller: msg::sender() }));
    //     }

    //     self.owner.set(new_owner);

    //     //evm::log(OwnerSet { owner: new_owner });
    //     Ok(())
    // }

    pub fn add_whitelisted_token(&mut self, token: Address, price_oracle: Address, vol_oracle: Address) -> Result<(), RiskManagerError> {

        if msg::sender() != self.owner.get() {
            return Err(RiskManagerError::NotOwner(NotOwner { owner: self.owner.get(), caller: msg::sender() }));
        }

        let mut whitelisted_tokens = self.whitelisted_tokens.setter(token);

        if whitelisted_tokens.get() {
            return Err(RiskManagerError::TokenAlreadyWhitelisted(TokenAlreadyWhitelisted { token }));
        }

        whitelisted_tokens.set(true);

        let mut new_token = self.tokens.grow();

        new_token.token.set(token);

        let mut price_oracle_setter = self.tokens_to_price_oracles.setter(token);
        let mut vol_oracle_setter = self.tokens_to_vol_oracles.setter(token);

        price_oracle_setter.set(price_oracle);
        vol_oracle_setter.set(vol_oracle);

        //evm::log(TokenWhitelisted { token, price_oracle, vol_oracle });

        Ok(())
    }
    

    pub fn allowed_swap(&self, user: Address, max_vol: I256, token_in: Address, token_in_amount: I256, token_out: Address, token_out_amount: I256) -> Result<bool, RiskManagerError> {
        // Initialize user data
        let mut user_vol: I256 = I256::unchecked_from(0);
        let mut user_balance_usd: I256 = I256::unchecked_from(0);
    
        for i in 0..self.tokens.len() {
            let token = self.tokens.get(i).unwrap();
            let token_address = token.token.get();
    
            let price_oracle = self.tokens_to_price_oracles.getter(token_address).get();
            let vol_oracle = self.tokens_to_vol_oracles.getter(token_address).get();
    
            let price_feed = IChainlinkFeed::new(price_oracle);
            let vol_feed = IChainlinkFeed::new(vol_oracle);
    
            let price = I256::from(price_feed.latest_round_data(self).unwrap());
            let vol = I256::from(vol_feed.latest_round_data(self).unwrap());
    
            let token_erc20 = ERC20::new(token_address);
            let balance = I256::unchecked_from(token_erc20.balance_of(self, user).unwrap());
    
            user_vol = user_vol + vol * balance;
            user_balance_usd = user_balance_usd + price * balance;
        }
    
        if user_balance_usd == I256::unchecked_from(0) {
            user_vol = I256::unchecked_from(0);
        } else {
            user_vol = user_vol / user_balance_usd;
        }
    
        // Check token whitelist
        let token_in_whitelisted = self.whitelisted_tokens.getter(token_in).get();
        let token_out_whitelisted = self.whitelisted_tokens.getter(token_out).get();
    
        if !token_in_whitelisted {
            return Err(RiskManagerError::TokenNotWhitelisted(TokenNotWhitelisted { token: token_in }));
        }
        if !token_out_whitelisted {
            return Err(RiskManagerError::TokenNotWhitelisted(TokenNotWhitelisted { token: token_out }));
        }
    
        // Calculate delta vol
        let vol_oracle_in = self.tokens_to_vol_oracles.getter(token_in).get();
        let vol_oracle_out = self.tokens_to_vol_oracles.getter(token_out).get();
    
        let vol_in = I256::from(IChainlinkFeed::new(vol_oracle_in).latest_round_data(self).unwrap());
        let vol_out = I256::from(IChainlinkFeed::new(vol_oracle_out).latest_round_data(self).unwrap());
    
        let delta_vol = vol_out * token_out_amount - vol_in * token_in_amount;
    
        // Check if delta vol is allowed
        if delta_vol < I256::unchecked_from(0) {
            return Ok(true);
        }
    
        let is_allowed = if user_balance_usd == I256::unchecked_from(0) {
            delta_vol <= max_vol
        } else {
            (user_vol * user_balance_usd + delta_vol) / user_balance_usd <= max_vol
        };
    
        Ok(is_allowed)
    }
    

}
