# NFT-Backed Lending Contract V1

## Overview

The **NFT-Backed Lending Contract V1** is a decentralized, peer-to-peer lending platform where users can borrow or lend NFTs as collateral for loans. This smart contract allows for the creation of loans backed by NFTs, where the lender provides an NFT as collateral, and the borrower agrees to repay the loan with an interest rate. Upon repayment, the NFT is returned to the borrower.

This contract is designed to facilitate a secure, trustless environment for users to participate in NFT-backed lending without intermediaries, relying on the security and transparency of blockchain technology.

---

## Features

### 1. **NFT Deposit & Withdrawal**
   - Users can deposit NFTs into the contract as collateral or withdraw them after loan repayment.
   
### 2. **Loan Creation**
   - A lender can create a loan by offering an NFT as collateral and specifying the loan amount, interest rate, and loan term (expiry).
   
### 3. **Loan Borrowing**
   - Borrowers can borrow NFTs by accepting the loan terms. The loan is backed by a specified amount of collateral in the form of NFTs.

### 4. **Loan Repayment**
   - Borrowers must repay the loan amount plus interest before they can reclaim the collateral NFT. Once the loan is repaid, the collateral NFT is returned to the borrower.

### 5. **Loan Types**
   - **Fixed Loan**: A fixed loan with a set repayment amount.
   - **Flexible Loan**: The loan repayment amount can be adjusted based on the agreement terms.

### 6. **Interest Rates**
   - Lenders specify the interest rate for the loan, which will be applied to the principal loan amount when it is repaid.

### 7. **NFT Ownership & Transfer**
   - NFTs can be locked as collateral when the loan is created, and they can only be transferred once the loan is repaid.

### 8. **Oracle Integration**
   - The contract includes functionality for setting and retrieving the price of NFTs in the market.

---

## How It Works

### 1. **Deposit NFTs**
   - Users deposit their NFTs to the contract to use them as collateral in a loan agreement. This ensures that the NFTs are securely locked and cannot be transferred unless certain conditions are met (e.g., loan repayment).

### 2. **Create Loan**
   - A lender creates a loan by specifying:
     - **Loan Amount**: The amount of tokens being lent.
     - **Collateral NFT**: The NFT being used as collateral.
     - **Interest Rate**: The rate at which the loan will accrue interest.
     - **Expiry**: The expiration time after which the loan will no longer be valid.
   
   The contract then locks the NFT in the contract until the loan terms are met (loan repayment).

### 3. **Borrow Loan**
   - Borrowers can view the available loans and choose to accept them. Upon accepting, they borrow the loan amount from the lender and receive the collateral NFT.

### 4. **Repay Loan**
   - Borrowers can repay the loan with the original loan amount plus the interest. After repayment, the collateral NFT is transferred back to the borrower, and the loan is marked as "repaid".

---

## Functions

### Public Functions

- **`deposit-nft(nft-id: uint)`**
  - Allows users to deposit NFTs into the contract as collateral.
  - Arguments:
    - `nft-id`: The unique identifier of the NFT being deposited.
  - Returns: `true` on success.

- **`withdraw-nft(nft-id: uint)`**
  - Allows users to withdraw NFTs from the contract after repayment of the loan.
  - Arguments:
    - `nft-id`: The unique identifier of the NFT being withdrawn.
  - Returns: `true` on success.

- **`create-loan(loan-type: uint, loan-amount: uint, collateral-nft: uint, interest-rate: uint, expiry: uint)`**
  - Allows users to create a loan, where they specify the loan amount, collateral (NFT), interest rate, and expiry.
  - Arguments:
    - `loan-type`: Type of loan (fixed or flexible).
    - `loan-amount`: The amount of tokens being lent.
    - `collateral-nft`: The NFT being used as collateral.
    - `interest-rate`: Interest rate for the loan.
    - `expiry`: The expiration height (block number).
  - Returns: `loan-id` of the created loan.

- **`borrow-loan(loan-id: uint)`**
  - Allows users to borrow an NFT-based loan, which provides the specified loan amount to the borrower.
  - Arguments:
    - `loan-id`: The unique identifier of the loan to be borrowed.
  - Returns: `true` on success.

- **`repay-loan(loan-id: uint)`**
  - Allows borrowers to repay their loan and retrieve their collateral (NFT).
  - Arguments:
    - `loan-id`: The unique identifier of the loan to be repaid.
  - Returns: `true` on success.

### Read-only Functions

- **`get-loan(loan-id: uint)`**
  - Retrieves information about a specific loan.
  - Arguments:
    - `loan-id`: The unique identifier of the loan.
  - Returns: Loan details (lender, borrower, collateral NFT, loan amount, etc.).

- **`get-nft-balance(holder: principal)`**
  - Retrieves the balance of NFTs for a specific user.
  - Arguments:
    - `holder`: The principal (user) whose NFT balance is being queried.
  - Returns: The NFT ID held by the user.

- **`get-user-loans(user: principal)`**
  - Retrieves all loans lent or borrowed by a specific user.
  - Arguments:
    - `user`: The principal (user) whose loan details are being queried.
  - Returns: Details of loans lent and borrowed.

- **`get-nft-price()`**
  - Retrieves the current price of NFTs from the oracle.
  - Returns: The price of NFTs as set by the contract owner.

### Oracle Functions

- **`set-nft-price(price: uint)`**
  - Allows the contract owner to set the market price of NFTs.
  - Arguments:
    - `price`: The market price of NFTs.
  - Returns: `true` on success.

---

## Example Use Cases

### Example 1: Lender Creates a Loan
1. Alice deposits an NFT (ID 123) into the contract as collateral.
2. Alice creates a loan of 100 STX, with an interest rate of 5% and a loan expiry of 1000 blocks.
3. Bob sees the available loan and borrows 100 STX from Alice, using the NFT as collateral.
4. Alice transfers the NFT as collateral and Bob receives the 100 STX loan.

### Example 2: Borrower Repays the Loan
1. After borrowing, Bob repays the loan with 105 STX (including the 5% interest).
2. The contract transfers the 105 STX from Bob to Alice.
3. Bob gets back his collateral NFT (ID 123).

---
