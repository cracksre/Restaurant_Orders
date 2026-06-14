"""
Inventory Service Lambda Function
Checks item availability and handles 86'd items
"""
import json
import logging
import os
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
INVENTORY_TABLE = os.environ.get('INVENTORY_TABLE')

# Sample inventory
SAMPLE_INVENTORY = {
    '1': {'available': True, 'quantity': 50},
    '2': {'available': True, 'quantity': 30},
    '3': {'available': False, 'quantity': 0},  # 86'd
    '4': {'available': True, 'quantity': 20},
    '5': {'available': True, 'quantity': 15},
    '6': {'available': True, 'quantity': 40},
    '7': {'available': True, 'quantity': 25},
    '8': {'available': True, 'quantity': 35},
    '9': {'available': False, 'quantity': 0},  # 86'd
    '10': {'available': True, 'quantity': 100},
    '11': {'available': True, 'quantity': 50},
    '12': {'available': True, 'quantity': 60}
}


class InventoryService:
    """Handles inventory operations"""
    
    def __init__(self):
        self.inventory_table = dynamodb.Table(INVENTORY_TABLE)
    
    def check_availability(self, item_id):
        """Check if item is available"""
        logger.info(f"Checking availability for item: {item_id}")
        
        try:
            inventory = SAMPLE_INVENTORY.get(item_id)
            if inventory:
                return {
                    'success': True,
                    'itemId': item_id,
                    'available': inventory['available'],
                    'quantity': inventory['quantity']
                }
            else:
                return {
                    'success': False,
                    'error': 'Item not found'
                }
        except Exception as e:
            logger.error(f"Error checking availability: {e}")
            return {'success': False, 'error': str(e)}
    
    def check_multiple_items(self, item_ids):
        """Check availability of multiple items"""
        logger.info(f"Checking availability for items: {item_ids}")
        
        try:
            results = []
            for item_id in item_ids:
                inventory = SAMPLE_INVENTORY.get(item_id)
                if inventory:
                    results.append({
                        'itemId': item_id,
                        'available': inventory['available'],
                        'quantity': inventory['quantity']
                    })
            
            return {
                'success': True,
                'items': results
            }
        except Exception as e:
            logger.error(f"Error checking multiple items: {e}")
            return {'success': False, 'error': str(e)}
    
    def update_inventory(self, item_id, quantity):
        """Update inventory quantity"""
        logger.info(f"Updating inventory for item {item_id}: {quantity}")
        
        try:
            if item_id in SAMPLE_INVENTORY:
                SAMPLE_INVENTORY[item_id]['quantity'] = max(0, quantity)
                if quantity <= 0:
                    SAMPLE_INVENTORY[item_id]['available'] = False
                return {'success': True}
            else:
                return {'success': False, 'error': 'Item not found'}
        except Exception as e:
            logger.error(f"Error updating inventory: {e}")
            return {'success': False, 'error': str(e)}
    
    def mark_86(self, item_id):
        """Mark item as 86'd (out of stock/unavailable)"""
        logger.info(f"Marking item {item_id} as 86'd")
        
        try:
            if item_id in SAMPLE_INVENTORY:
                SAMPLE_INVENTORY[item_id]['available'] = False
                SAMPLE_INVENTORY[item_id]['quantity'] = 0
                return {'success': True}
            else:
                return {'success': False, 'error': 'Item not found'}
        except Exception as e:
            logger.error(f"Error marking item as 86'd: {e}")
            return {'success': False, 'error': str(e)}
    
    def unmark_86(self, item_id, quantity):
        """Unmark item as 86'd"""
        logger.info(f"Unmarking item {item_id} as 86'd with quantity: {quantity}")
        
        try:
            if item_id in SAMPLE_INVENTORY:
                SAMPLE_INVENTORY[item_id]['available'] = True
                SAMPLE_INVENTORY[item_id]['quantity'] = quantity
                return {'success': True}
            else:
                return {'success': False, 'error': 'Item not found'}
        except Exception as e:
            logger.error(f"Error unmarking item: {e}")
            return {'success': False, 'error': str(e)}


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        service = InventoryService()
        
        # Parse request
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '')
        body = json.loads(event.get('body', '{}'))
        query_params = event.get('queryStringParameters', {}) or {}
        
        if http_method == 'GET' and path == '/inventory':
            item_ids = query_params.get('items', '').split(',')
            if len(item_ids) == 1:
                result = service.check_availability(item_ids[0])
            else:
                result = service.check_multiple_items(item_ids)
        elif http_method == 'PATCH' and path == '/inventory/quantity':
            item_id = body.get('itemId')
            quantity = body.get('quantity')
            result = service.update_inventory(item_id, quantity)
        elif http_method == 'POST' and path == '/inventory/86':
            item_id = body.get('itemId')
            result = service.mark_86(item_id)
        elif http_method == 'POST' and path == '/inventory/unmark-86':
            item_id = body.get('itemId')
            quantity = body.get('quantity', 10)
            result = service.unmark_86(item_id, quantity)
        else:
            result = {'error': 'Method not allowed'}
        
        status_code = 200 if result.get('success', False) else 400
        
        return {
            'statusCode': status_code,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(result)
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
