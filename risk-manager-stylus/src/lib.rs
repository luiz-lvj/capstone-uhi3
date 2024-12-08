//!
//! Stylus Hello World
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
use stylus_sdk::{alloy_primitives::{U256, I256,  Address}, prelude::*, msg, evm};

use stylus_sdk::alloy_sol_types::sol;
// Define some persistent storage using the Solidity ABI.
// `Counter` will be the entrypoint.
sol_storage! {
    #[entrypoint]
    pub struct RiskManager {
        address owner;
        bool initialized;
        TokensInfo[] tokens;
        address kyc_nft;

        mapping(address => bool) whitelisted_tokens;
        mapping(address => address) tokens_to_price_oracles;
        mapping(address => address) tokens_to_vol_oracles;

        mapping(address => bool) kyc_users;
    }

    pub struct TokensInfo {
        address token;
    }
}

// Declare events and Solidity error types
sol! {

    event OwnerSet(address indexed owner);
    event TokenWhitelisted(address indexed token, address indexed price_oracle, address indexed vol_oracle);

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

        if self.initialized.get() {
            return Ok(());
        }
        self.initialized.set(true);

        self.owner.set(msg::sender());
        Ok(())
    }

    pub fn set_kyc_nft(&mut self, kyc_nft: Address) -> Result<(), RiskManagerError> {

        if msg::sender() != self.owner.get() {
            return Err(RiskManagerError::NotOwner(NotOwner { owner: self.owner.get(), caller: msg::sender() }));
        }

        self.kyc_nft.set(kyc_nft);
        Ok(())
    }

    pub fn set_user_key(&mut self, user: Address) -> Result<(), RiskManagerError> {


        if msg::sender() != self.kyc_nft.get() {
            return Err(RiskManagerError::NotOwner(NotOwner { owner: self.kyc_nft.get(), caller: msg::sender() }));
        }

        let mut kyc_users = self.kyc_users.setter(user);
        kyc_users.set(true);

        Ok(())
    }

    pub fn is_user_kyc(&self, user: Address) -> Result<bool, RiskManagerError> {
        let kyc_user = self.kyc_users.getter(user);
        Ok(kyc_user.get())
    }


    /// Gets the owner from storage.
    pub fn owner(&self) -> Address {
        self.owner.get()
    }

    /// Sets the owner in storage to a user-specified value.
    pub fn set_owner(&mut self, new_owner: Address)  -> Result<(), RiskManagerError> {

        if msg::sender() != self.owner.get() {
            return Err(RiskManagerError::NotOwner(NotOwner 
                    { owner: self.owner.get(), caller: msg::sender() 
                }));    
        }

        self.owner.set(new_owner);

        evm::log(OwnerSet { owner: new_owner });
        Ok(())
    }

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

        evm::log(TokenWhitelisted { token, price_oracle, vol_oracle });

        Ok(())
    }

    pub fn remove_whitelisted_token(&mut self, token: Address) -> Result<(), RiskManagerError> {

        if msg::sender() != self.owner.get() {
            return Err(RiskManagerError::NotOwner(NotOwner { owner: self.owner.get(), caller: msg::sender() }));
        }

        let mut whitelisted_tokens = self.whitelisted_tokens.setter(token);

        if !whitelisted_tokens.get() {
            return Err(RiskManagerError::TokenNotWhitelisted(TokenNotWhitelisted { token }));
        }

        whitelisted_tokens.set(false);

        Ok(())
    }

    pub fn is_token_whitelisted(&self, token: Address) -> Result<bool, RiskManagerError> {
        let whitelisted_token = self.whitelisted_tokens.getter(token);
        Ok(whitelisted_token.get())
    }


    pub fn get_feed_info(&self, feed: IChainlinkFeed) -> Result<I256, RiskManagerError> {
        
        let data = feed.latest_round_data(self).unwrap();

        Ok(I256::from(data))
    }

    pub fn get_user_balance(&self, token: ERC20, user: Address) -> Result<U256, Vec<u8>> {
        let balance = token.balance_of(self, user)?;
        Ok(U256::from(balance))
    }

    pub fn get_whitelisted_token_info(&self, index: U256) -> (Address, Address, Address) {
        let token = self.tokens.get(index).unwrap();

        let token_address = token.token.get();

        let price_oracle = self.tokens_to_price_oracles.getter(token_address);
        let vol_oracle = self.tokens_to_vol_oracles.getter(token_address);

        (token_address, price_oracle.get(), vol_oracle.get())
    }

    pub fn get_user_data(&self, user: Address) -> Result<(I256, I256), RiskManagerError> {

        let mut user_vol: I256 = I256::unchecked_from(0);
        let mut user_balance_usd: I256 = I256::unchecked_from(0);
        
        for i in 0..self.tokens.len() {

            let (token, price_oracle, vol_oracle) = self.get_whitelisted_token_info(U256::from(i));

            if !self.is_token_whitelisted(token)? {
                continue;
            }

            let price_feed = IChainlinkFeed::new(price_oracle);
            let vol_feed = IChainlinkFeed::new(vol_oracle);

            let price = self.get_feed_info(price_feed)?;
            let vol = self.get_feed_info(vol_feed)?;

            let token_erc20 = ERC20::new(token);
            let balance = self.get_user_balance(token_erc20, user).unwrap();

            user_vol =  user_vol + vol * I256::unchecked_from(balance);
            user_balance_usd = user_balance_usd + price * I256::try_from(balance).unwrap();

        }

        if user_balance_usd == I256::unchecked_from(0) {
            return Ok((I256::unchecked_from(0), I256::unchecked_from(0)));
        }

        user_vol = user_vol / user_balance_usd;

        Ok((user_vol, user_balance_usd))
    }

    pub fn get_delta_vol(&self,token_in: Address, token_in_amount: I256, token_out: Address, token_out_amount: I256) -> Result<I256, RiskManagerError> {

        
        let vol_oracle_in = self.tokens_to_vol_oracles.getter(token_in);
        let vol_oracle_out = self.tokens_to_vol_oracles.getter(token_out);

        let vol_in = self.get_feed_info(IChainlinkFeed::new(vol_oracle_in.get()))?;
        let vol_out = self.get_feed_info(IChainlinkFeed::new(vol_oracle_out.get()))?;

        let delta_vol = vol_in * token_in_amount - vol_out * token_out_amount;

        Ok(delta_vol)

        
    }

    pub fn is_delta_vol_allowed(&self, user_vol: I256, user_balance_usd: I256, delta_vol: I256, max_vol: I256) -> bool {
        
        if user_balance_usd == I256::unchecked_from(0) {
            return delta_vol <= max_vol;
        }

        (user_vol * user_balance_usd + delta_vol)/user_balance_usd <= max_vol
    }

    pub fn allowed_swap(&self, user: Address, max_vol: I256, token_in: Address, token_in_amount: I256, token_out: Address, token_out_amount: I256) -> Result<bool, RiskManagerError> {

        let (user_vol, user_balance_usd) = self.get_user_data(user)?;

        if !self.is_token_whitelisted(token_in)? {
            return Err(RiskManagerError::TokenNotWhitelisted(TokenNotWhitelisted { token: token_in }));
        }

        if !self.is_token_whitelisted(token_out)? {
            return Err(RiskManagerError::TokenNotWhitelisted(TokenNotWhitelisted { token: token_out }));
        }   

        let delta_vol = self.get_delta_vol(token_in, token_in_amount, token_out, token_out_amount)?;

        if delta_vol < I256::unchecked_from(0) {
            return Ok(true);
        }

        Ok(self.is_delta_vol_allowed(user_vol, user_balance_usd, delta_vol, max_vol))
    }

}
