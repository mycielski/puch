import json
import os
import uuid
from datetime import datetime

from azure.cosmos import CosmosClient, exceptions


class CosmosDBManager:
    def __init__(self):
        # Connection details from your tfstate
        endpoint = os.getenv("ENDPOINT")
        primary_key = os.getenv("PRIMARY_KEY")

        # Initialize the Cosmos Client
        self.client = CosmosClient(endpoint, primary_key)

        # Get database and container
        self.database = self.client.get_database_client("puch-cosmosdb-lab1")
        self.container = self.database.get_container_client("main-container")

    def create_item(self, name, description, category):
        """Create a new item in the container"""
        try:
            item = {
                "id": str(uuid.uuid4()),
                "name": name,
                "description": description,
                "category": category,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
            }

            created_item = self.container.create_item(body=item)
            print(f"Created item: {created_item['id']}")
            return created_item

        except exceptions.CosmosHttpResponseError as e:
            print(f"Error creating item: {e.message}")
            return None

    def read_item(self, item_id):
        """Read an item from the container"""
        try:
            item = self.container.read_item(item=item_id, partition_key=item_id)
            return item

        except exceptions.CosmosResourceNotFoundError:
            print(f"Item with id {item_id} not found")
            return None
        except exceptions.CosmosHttpResponseError as e:
            print(f"Error reading item: {e.message}")
            return None

    def update_item(self, item_id, updates):
        """Update an existing item in the container"""
        try:
            # First read the item
            item = self.container.read_item(item=item_id, partition_key=item_id)

            # Update the item with new values
            item.update(updates)
            item["updated_at"] = datetime.utcnow().isoformat()

            # Replace the item in the container
            updated_item = self.container.replace_item(item=item_id, body=item)
            print(f"Updated item: {updated_item['id']}")
            return updated_item

        except exceptions.CosmosResourceNotFoundError:
            print(f"Item with id {item_id} not found")
            return None
        except exceptions.CosmosHttpResponseError as e:
            print(f"Error updating item: {e.message}")
            return None

    def delete_item(self, item_id):
        """Delete an item from the container"""
        try:
            self.container.delete_item(item=item_id, partition_key=item_id)
            print(f"Deleted item: {item_id}")
            return True

        except exceptions.CosmosResourceNotFoundError:
            print(f"Item with id {item_id} not found")
            return False
        except exceptions.CosmosHttpResponseError as e:
            print(f"Error deleting item: {e.message}")
            return False

    def list_items(self, category=None):
        """List all items, optionally filtered by category"""
        try:
            if category:
                query = f"SELECT * FROM c WHERE c.category = '{category}'"
            else:
                query = "SELECT * FROM c"

            items = list(
                self.container.query_items(
                    query=query, enable_cross_partition_query=True
                )
            )
            return items

        except exceptions.CosmosHttpResponseError as e:
            print(f"Error listing items: {e.message}")
            return []


def main():
    # Create an instance of the CosmosDB manager
    cosmos_manager = CosmosDBManager()

    # Demo usage
    print("\n=== Creating new items ===")
    item1 = cosmos_manager.create_item("Sample Item 1", "This is a test item", "test")

    item2 = cosmos_manager.create_item(
        "Sample Item 2", "This is another test item", "test"
    )

    if item1:
        print("\n=== Reading item ===")
        retrieved_item = cosmos_manager.read_item(item1["id"])
        print(f"Retrieved item: {json.dumps(retrieved_item, indent=2)}")

        print("\n=== Updating item ===")
        updates = {
            "description": "This is an updated description",
            "category": "updated",
        }
        updated_item = cosmos_manager.update_item(item1["id"], updates)
        print(f"Updated item: {json.dumps(updated_item, indent=2)}")

    print("\n=== Listing all items ===")
    all_items = cosmos_manager.list_items()
    print(f"Found {len(all_items)} items:")
    for item in all_items:
        print(f"- {item['name']} ({item['id']})")

    if item1 and item2:
        print("\n=== Deleting items ===")
        cosmos_manager.delete_item(item1["id"])
        cosmos_manager.delete_item(item2["id"])


if __name__ == "__main__":
    main()
