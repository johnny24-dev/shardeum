//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// helps with sending the NFTs, will be particularly useful for batch operations
library NFTCommon {
    /**
     @notice Transfers the NFT tokenID from to.
     @dev safuTransferFrom name to avoid collision with the interface signature definitions. The reason it is implemented the way it is,
      is because some NFT contracts implement both the 721 and 1155 standard at the same time. Sometimes, 721 or 1155 function does not work.
      So instead of relying on the user's input, or asking the contract what interface it implements, it is best to just make a good assumption
      about what NFT type it is (here we guess it is 721 first), and if that fails, we use the 1155 function to tranfer the NFT.
     @param nft     NFT address
     @param from    Source address
     @param to      Target address
     @param tokenID ID of the token type
     @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom_(
        address nft,
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) internal returns (bool) {
        // most are 721s, so we assume that that is what the NFT type is
        try IERC721(nft).safeTransferFrom(from, to, tokenID, data) {
            return true;
            // on fail, use 1155s format
        } catch (bytes memory) {
            try IERC1155(nft).safeTransferFrom(from, to, tokenID, 1, data) {
                return true;
            } catch (bytes memory) {
                return false;
            }
        }
    }

    /**
     @notice Determines if potentialOwner is in fact an owner of at least 1 qty of NFT token ID.
     @param nft NFT address
     @param potentialOwner suspected owner of the NFT token ID
     @param tokenID id of the token
     @return quantity of held token, possibly zero
    */
    function quantityOf(
        address nft,
        address potentialOwner,
        uint256 tokenID
    ) internal view returns (uint256) {
        try IERC721(nft).ownerOf(tokenID) returns (address owner) {
            if (owner == potentialOwner) {
                return 1;
            } else {
                return 0;
            }
        } catch (bytes memory) {
            try IERC1155(nft).balanceOf(potentialOwner, tokenID) returns (
                uint256 amount
            ) {
                return amount;
            } catch (bytes memory) {
                return 0;
            }
        }
    }

    function approveCommon(
        address nft,
        address to,
        uint256 tokenId
    ) internal returns (bool) {
        try IERC721(nft).approve(to, tokenId) {
            return true;
        } catch (bytes memory) {
            try IERC1155(nft).setApprovalForAll(to, true) {
                return true;
            } catch (bytes memory) {
                return false;
            }
        }
    }

    function revokesCommon(
        address nft,
        address to,
        uint256 tokenId
    ) internal returns (bool) {
        try IERC721(nft).approve(address(0), tokenId) {
            return true;
        } catch (bytes memory) {
            try IERC1155(nft).setApprovalForAll(to, false) {
                return true;
            } catch (bytes memory) {
                return false;
            }
        }
    }

    function getApproved(
        address nft,
        address owner,
        address to,
        uint256 tokenId
    ) internal view returns (bool) {
        try IERC721(nft).getApproved(tokenId) returns (address operator) {
            if (operator == to) {
                return true;
            } else {
                return false;
            }
        } catch (bytes memory) {
            try IERC1155(nft).isApprovedForAll(owner, to) returns (bool isApproved) {
                return isApproved;
            } catch (bytes memory) {
                return false;
            }
        }
    }
}
