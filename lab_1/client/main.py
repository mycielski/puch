import os
from datetime import datetime

from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.data.tables import TableServiceClient

# Connection details from tfstate
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING")
TABLE_NAME = "lab1"


class AzureTableStorage:
    def __init__(self):
        self.table_service = TableServiceClient.from_connection_string(
            STORAGE_CONNECTION_STRING
        )
        self.table_client = self.table_service.get_table_client(table_name=TABLE_NAME)

    def create_entity(self, partition_key, row_key, data):
        """
        Create a new entity in the table
        """
        try:
            entity = {
                "PartitionKey": partition_key,
                "RowKey": row_key,
                "Timestamp": datetime.utcnow(),
                **data,
            }
            self.table_client.create_entity(entity=entity)
            print(f"Entity created successfully: {partition_key}/{row_key}")
            return True
        except ResourceExistsError:
            print(f"Entity already exists: {partition_key}/{row_key}")
            return False

    def read_entity(self, partition_key, row_key):
        """
        Read an entity from the table
        """
        try:
            entity = self.table_client.get_entity(partition_key, row_key)
            print(f"Entity found: {entity}")
            return entity
        except ResourceNotFoundError:
            print(f"Entity not found: {partition_key}/{row_key}")
            return None

    def update_entity(self, partition_key, row_key, data):
        """
        Update an existing entity in the table
        """
        try:
            entity = self.table_client.get_entity(partition_key, row_key)
            entity.update(data)
            self.table_client.update_entity(entity=entity, mode="merge")
            print(f"Entity updated successfully: {partition_key}/{row_key}")
            return True
        except ResourceNotFoundError:
            print(f"Entity not found: {partition_key}/{row_key}")
            return False

    def delete_entity(self, partition_key, row_key):
        """
        Delete an entity from the table
        """
        try:
            self.table_client.delete_entity(partition_key, row_key)
            print(f"Entity deleted successfully: {partition_key}/{row_key}")
            return True
        except ResourceNotFoundError:
            print(f"Entity not found: {partition_key}/{row_key}")
            return False

    def list_entities(self, partition_key=None):
        """
        List all entities or entities with specific partition key
        """
        if partition_key:
            entities = self.table_client.query_entities(
                f"PartitionKey eq '{partition_key}'"
            )
        else:
            entities = self.table_client.list_entities()

        for entity in entities:
            print(entity)
        return entities


def main():
    # Example usage
    table_storage = AzureTableStorage()

    # Create example
    sample_data = {"name": "John Doe", "email": "john@example.com", "department": "IT"}
    table_storage.create_entity("employees", "emp001", sample_data)

    # Read example
    table_storage.read_entity("employees", "emp001")

    # Update example
    update_data = {"department": "HR", "title": "Manager"}
    table_storage.update_entity("employees", "emp001", update_data)

    # List example
    print("\nListing all entities in partition 'employees':")
    table_storage.list_entities("employees")

    # Delete example
    table_storage.delete_entity("employees", "emp001")

    # List example
    print("\nListing all entities in partition 'employees':")
    table_storage.list_entities("employees")


if __name__ == "__main__":
    main()
