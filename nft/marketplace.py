from typing import List, Dict
from nft.om109_algorithm import OM109Algorithm

class MarketplaceEngine:
    """
    Marketplace engine providing search, filter, sorting, floor price tracking,
    and volume analytics for OMEGA AGENT NFT platform.
    """
    
    def __init__(self, platform):
        self.platform = platform
        self.algo = OM109Algorithm()
        
    def search_tokens(self, query: str = "", min_price: float = None, max_price: float = None, sort_by: str = "price_asc") -> List[dict]:
        """
        Search, filter, and sort across active listings.
        """
        results = []
        for l_id, listing in self.platform.listings.items():
            if listing["status"] != "active":
                continue
                
            token_id = listing["token_id"]
            token = self.platform.tokens[token_id]
            price = listing["price"]
            
            # Text query check
            name = token["metadata"].get("name", "").lower()
            description = token["metadata"].get("description", "").lower()
            if query and query.lower() not in name and query.lower() not in description:
                continue
                
            # Range price check
            if min_price is not None and price < min_price:
                continue
            if max_price is not None and price > max_price:
                continue
                
            results.append({
                "listing_id": l_id,
                "token_id": token_id,
                "name": token["metadata"].get("name"),
                "price": price,
                "owner": token["owner"],
                "rarity_score": token.get("rarity_score", 1.0)
            })
            
        # Sorters
        if sort_by == "price_asc":
            results.sort(key=lambda x: x["price"])
        elif sort_by == "price_desc":
            results.sort(key=lambda x: x["price"], reverse=True)
        elif sort_by == "rarity":
            results.sort(key=lambda x: x["rarity_score"], reverse=True)
            
        return results
        
    def get_collection_floor_price(self, collection_id: str) -> float:
        """
        Dynamically calculates the floor price (lowest active listing) of a collection.
        """
        active_prices = []
        for l_id, listing in self.platform.listings.items():
            if listing["status"] != "active":
                continue
            token = self.platform.tokens.get(listing["token_id"])
            if token and token["metadata"].get("collection_id") == collection_id:
                active_prices.append(listing["price"])
                
        return min(active_prices) if active_prices else 0.0
        
    def get_collection_volume(self, collection_id: str) -> Dict[str, float]:
        """
        Calculates total traded volume and transaction counts for analytics.
        """
        total_volume = 0.0
        sales_count = 0
        
        for sale in self.platform.sales:
            token_id = sale["token_id"]
            token = self.platform.tokens.get(token_id)
            if token and token["metadata"].get("collection_id") == collection_id:
                total_volume += sale["price"]
                sales_count += 1
                
        return {
            "collection_id": collection_id,
            "total_volume": round(total_volume, 6),
            "sales_count": sales_count
        }
