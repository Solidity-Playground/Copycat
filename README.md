# Copycat - NFT Inheritance 

`Mint token proxies that return the contents of other NFTs`

An ERC721 that inherits its properties from another ERC721 you own.




* Mint proxy tokens that are mapped to other tokens in other contracts on the same chain
* TokenURI is inherited from the origin NFT
* OwnerOf is inherited from the origin NFT
* Validates that you own the destination token when minting
