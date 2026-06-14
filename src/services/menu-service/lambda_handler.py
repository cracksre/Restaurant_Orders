"""
Menu Service Lambda Function
Handles menu browsing and item lookup
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
MENU_TABLE = os.environ.get('MENU_TABLE')

# Sample menu data
SAMPLE_MENU = {
    'Appetizers': [
        {'id': '1', 'name': 'Bruschetta', 'price': 8.99, 'description': 'Toasted bread with tomatoes'},
        {'id': '2', 'name': 'Calamari', 'price': 10.99, 'description': 'Fried squid rings'},
        {'id': '3', 'name': 'Mozzarella Sticks', 'price': 7.99, 'description': 'Fried cheese sticks'}
    ],
    'Main Courses': [
        {'id': '4', 'name': 'Grilled Salmon', 'price': 24.99, 'description': 'Fresh salmon fillet'},
        {'id': '5', 'name': 'Ribeye Steak', 'price': 32.99, 'description': 'Prime cut steak'},
        {'id': '6', 'name': 'Pasta Carbonara', 'price': 18.99, 'description': 'Classic Italian pasta'}
    ],
    'Desserts': [
        {'id': '7', 'name': 'Tiramisu', 'price': 8.99, 'description': 'Italian layered dessert'},
        {'id': '8', 'name': 'Chocolate Cake', 'price': 7.99, 'description': 'Rich chocolate cake'},
        {'id': '9', 'name': 'Cheesecake', 'price': 9.99, 'description': 'New York style cheesecake'}
    ],
    'Beverages': [
        {'id': '10', 'name': 'Coca Cola', 'price': 2.99, 'description': 'Classic soft drink'},
        {'id': '11', 'name': 'Wine - Cabernet', 'price': 12.99, 'description': 'House red wine'},
        {'id': '12', 'name': 'Beer - Craft IPA', 'price': 6.99, 'description': 'Local craft beer'}
    ]
}


class MenuService:
    """Handles menu operations"""
    
    def __init__(self):
        self.menu_table = dynamodb.Table(MENU_TABLE)
    
    def get_categories(self):
        """Get all menu categories"""
        logger.info("Getting menu categories")
        return {
            'categories': list(SAMPLE_MENU.keys()),
            'count': len(SAMPLE_MENU)
        }
    
    def get_category_items(self, category):
        """Get items in a specific category"""
        logger.info(f"Getting items for category: {category}")
        items = SAMPLE_MENU.get(category, [])
        return {
            'category': category,
            'items': items,
            'count': len(items)
        }
    
    def get_item(self, item_id):
        """Get specific menu item"""
        logger.info(f"Getting item: {item_id}")
        for category, items in SAMPLE_MENU.items():
            for item in items:
                if item['id'] == item_id:
                    return {'item': item}
        
        return {'error': f'Item {item_id} not found'}
    
    def search_items(self, query):
        """Search menu items"""
        logger.info(f"Searching for: {query}")
        results = []
        query_lower = query.lower()
        
        for category, items in SAMPLE_MENU.items():
            for item in items:
                if query_lower in item['name'].lower() or query_lower in item['description'].lower():
                    results.append({**item, 'category': category})
        
        return {
            'query': query,
            'results': results,
            'count': len(results)
        }


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        service = MenuService()
        
        # Parse request
        path = event.get('path', '')
        http_method = event.get('httpMethod', 'GET')
        query_params = event.get('queryStringParameters', {}) or {}
        
        if path == '/menu/categories' and http_method == 'GET':
            result = service.get_categories()
        elif path == '/menu/category' and http_method == 'GET':
            category = query_params.get('category')
            if not category:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'category parameter required'})
                }
            result = service.get_category_items(category)
        elif path == '/menu/item' and http_method == 'GET':
            item_id = query_params.get('id')
            if not item_id:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'id parameter required'})
                }
            result = service.get_item(item_id)
        elif path == '/menu/search' and http_method == 'GET':
            query = query_params.get('q')
            if not query:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'q parameter required'})
                }
            result = service.search_items(query)
        else:
            result = service.get_categories()
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(result)
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
