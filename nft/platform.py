import uuid
from typing import Dict, List, Optional
from nft.om109_algorithm import OM109Algorithm

class NFTPlatform:
    """
    NFT Platform Core business engine.
    Manages minting, listing, auctions, bids, sales, and royalties calculations.
    """
    
    def __init__(self):
        self.algo = OM109Algorithm()
        self.tokens: Dict[str, dict] = {}
        self.listings: Dict[str, dict] = {}
        self.auctions: Dict[str, dict] = {}
        self.bids: Dict[str, List[dict]] = {}
        self.sales: List[dict] = {}
        self.balances: Dict[str, float] = {}  # User balances for testing
        
    def mint_token(self, creator: str, metadata: dict, royalty_pct: float) -> dict:
        """
        Mints a new unique NFT, generates cryptographic signatures, and calculates rarity.
        """
        token_id = str(uuid.uuid4())
        signature = self.algo.generate_token_signature(metadata)
        
        token = {
            "id": token_id,
            "creator": creator,
            "owner": creator,
            "metadata": metadata,
            "royalty_pct": royalty_pct,
            "signature": signature,
            "is_burnt": False,
            "attributes": metadata.get("attributes", [])
        }
        
        self.tokens[token_id] = token
        return token
        
    def list_token(self, token_id: str, price: float, auction_config: Optional[dict] = None) -> dict:
        """
        Lists a token for standard fixed-price sale or schedules a competitive auction.
        """
        if token_id not in self.tokens:
            raise ValueError("Token does not exist")
            
        token = self.tokens[token_id]
        if token["is_burnt"]:
            raise ValueError("Cannot list a burnt token")
            
        listing_id = str(uuid.uuid4())
        
        if auction_config:
            auction = {
                "id": listing_id,
                "token_id": token_id,
                "seller": token["owner"],
                "reserve_price": price,
                "buyout_price": auction_config.get("buyout_price"),
                "ends_at": auction_config.get("ends_at"),
                "status": "active"
            }
            self.auctions[listing_id] = auction
            self.bids[listing_id] = []
            return auction
        else:
            listing = {
                "id": listing_id,
                "token_id": token_id,
                "seller": token["owner"],
                "price": price,
                "status": "active"
            }
            self.listings[listing_id] = listing
            return listing
            
    def place_bid(self, auction_id: str, bidder: str, amount: float) -> dict:
        """
        Places a bid on an active NFT auction. Evaluates if high enough.
        """
        if auction_id not in self.auctions:
            raise ValueError("Auction not found")
            
        auction = self.auctions[auction_id]
        if auction["status"] != "active":
            raise ValueError("Auction is not active")
            
        existing_bids = self.bids.get(auction_id, [])
        highest_bid = max([b["amount"] for b in existing_bids], default=auction["reserve_price"])
        
        if len(existing_bids) > 0 and amount <= highest_bid:
            raise ValueError(f"Bid must be higher than current highest bid of {highest_bid}")
        elif len(existing_bids) == 0 and amount < auction["reserve_price"]:
            raise ValueError(f"Bid must meet reserve price of {auction['reserve_price']}")
            
        bid = {
            "bid_id": str(uuid.uuid4()),
            "bidder": bidder,
            "amount": amount,
            "status": "placed"
        }
        self.bids[auction_id].append(bid)
        return bid
        
    def execute_sale(self, listing_id: str, buyer: str) -> dict:
        """
        Executes a marketplace sale, processes payments, transfers ownership, and splits royalties.
        """
        if listing_id not in self.listings:
            raise ValueError("Listing not found")
            
        listing = self.listings[listing_id]
        if listing["status"] != "active":
            raise ValueError("Listing is no longer active")
            
        token_id = listing["token_id"]
        token = self.tokens[token_id]
        seller = listing["seller"]
        price = listing["price"]
        
        # Calculate royalties and transfer ownership
        royalties = self.calculate_royalties(price, token_id)
        net_seller_payout = price - royalties["royalty_amount"]
        
        # Transfer ownership in system memory
        token["owner"] = buyer
        listing["status"] = "sold"
        
        sale_receipt = {
            "listing_id": listing_id,
            "token_id": token_id,
            "buyer": buyer,
            "seller": seller,
            "price": price,
            "royalty_payout": royalties,
            "net_seller_payout": net_seller_payout
        }
        return sale_receipt
        
    def calculate_royalties(self, sale_price: float, token_id: str) -> dict:
        """
        Computes platform fee and creator royalty split.
        """
        if token_id not in self.tokens:
            raise ValueError("Token not found")
            
        token = self.tokens[token_id]
        royalty_pct = token["royalty_pct"]
        royalty_amount = sale_price * (royalty_pct / 100.0)
        
        return {
            "token_id": token_id,
            "creator": token["creator"],
            "royalty_percentage": royalty_pct,
            "royalty_amount": round(royalty_amount, 6)
        }
