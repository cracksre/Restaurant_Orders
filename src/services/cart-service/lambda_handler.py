"""
Cart Service Lambda Function
Handles shopping cart operations
"""
import json
import logging
import os
from datetime import datetime
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
SESSION_TABLE = os.environ.get('SESSION_TABLE')


class CartService:
    """Handles cart operations"""
    
    def __init__(self):
        self.session_table = dynamodb.Table(SESSION_TABLE)
    
    def add_item(self, session_id, item):
        """Add item to cart"""
        logger.info(f"Adding item to cart for session: {session_id}")
        
        try:
            self.session_table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #cart = list_append(if_not_exists(#cart, :empty), :item)',
                ExpressionAttributeNames={'#cart': 'cart'},
                ExpressionAttributeValues={
                    ':empty': [],
                    ':item': [item]
                },
                ReturnValues='ALL_NEW'
            )
            return {'success': True}
        except Exception as e:
            logger.error(f"Error adding item: {e}")
            return {'success': False, 'error': str(e)}
    
    def remove_item(self, session_id, item_index):
        """Remove item from cart"""
        logger.info(f"Removing item {item_index} from cart for session: {session_id}")
        
        try:
            response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' not in response:
                return {'success': False, 'error': 'Session not found'}
            
            cart = response['Item'].get('cart', [])
            if item_index < 0 or item_index >= len(cart):
                return {'success': False, 'error': 'Invalid item index'}
            
            cart.pop(item_index)
            
            self.session_table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #cart = :cart',
                ExpressionAttributeNames={'#cart': 'cart'},
                ExpressionAttributeValues={':cart': cart},
                ReturnValues='ALL_NEW'
            )
            return {'success': True}
        except Exception as e:
            logger.error(f"Error removing item: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_cart(self, session_id):
        """Get cart contents"""
        logger.info(f"Getting cart for session: {session_id}")
        
        try:
            response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' not in response:
                return {'success': False, 'error': 'Session not found'}
            
            cart_items = response['Item'].get('cart', [])
            subtotal = sum([item.get('price', 0) * item.get('quantity', 1) for item in cart_items])
            tax = subtotal * 0.08
            total = subtotal + tax
            
            return {
                'success': True,
                'cart': {
                    'items': cart_items,
                    'subtotal': subtotal,
                    'tax': tax,
                    'total': total
                }
            }
        except Exception as e:
            logger.error(f"Error getting cart: {e}")
            return {'success': False, 'error': str(e)}
    
    def clear_cart(self, session_id):
        """Clear cart"""
        logger.info(f"Clearing cart for session: {session_id}")
        
        try:
            self.session_table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #cart = :empty',
                ExpressionAttributeNames={'#cart': 'cart'},
                ExpressionAttributeValues={':empty': []},
                ReturnValues='ALL_NEW'
            )
            return {'success': True}
        except Exception as e:
            logger.error(f"Error clearing cart: {e}")
            return {'success': False, 'error': str(e)}
    
    def update_item_quantity(self, session_id, item_index, quantity):
        """Update item quantity"""
        logger.info(f"Updating item {item_index} quantity to {quantity} for session: {session_id}")
        
        try:
            response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' not in response:
                return {'success': False, 'error': 'Session not found'}
            
            cart = response['Item'].get('cart', [])
            if item_index < 0 or item_index >= len(cart):
                return {'success': False, 'error': 'Invalid item index'}
            
            if quantity <= 0:
                cart.pop(item_index)
            else:
                cart[item_index]['quantity'] = quantity
            
            self.session_table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #cart = :cart',
                ExpressionAttributeNames={'#cart': 'cart'},
                ExpressionAttributeValues={':cart': cart},
                ReturnValues='ALL_NEW'
            )
            return {'success': True}
        except Exception as e:
            logger.error(f"Error updating quantity: {e}")
            return {'success': False, 'error': str(e)}


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        service = CartService()
        
        # Parse request
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '')
        body = json.loads(event.get('body', '{}'))
        query_params = event.get('queryStringParameters', {}) or {}
        
        session_id = query_params.get('sessionId') or body.get('sessionId')
        
        if not session_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'sessionId required'})
            }
        
        if http_method == 'GET' and path == '/cart':
            result = service.get_cart(session_id)
        elif http_method == 'POST' and path == '/cart/add':
            result = service.add_item(session_id, body.get('item'))
        elif http_method == 'DELETE' and path == '/cart/item':
            result = service.remove_item(session_id, body.get('index'))
        elif http_method == 'DELETE' and path == '/cart':
            result = service.clear_cart(session_id)
        elif http_method == 'PATCH' and path == '/cart/item':
            result = service.update_item_quantity(
                session_id,
                body.get('index'),
                body.get('quantity')
            )
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
