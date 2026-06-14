"""
Alexa Skill Handler Lambda Function
Handles all Alexa skill intents for the Restaurant Ordering Assistant
"""
import json
import logging
import os
import uuid
from datetime import datetime, timedelta
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
dynamodb = boto3.resource('dynamodb')
events_client = boto3.client('events')

# Environment variables
SESSION_TABLE = os.environ.get('SESSION_TABLE')
EVENTBRIDGE_BUS = os.environ.get('EVENTBRIDGE_BUS')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')


class AlexaSkillHandler:
    """Handles Alexa skill requests"""
    
    def __init__(self):
        self.session_table = dynamodb.Table(SESSION_TABLE)
    
    def handle_launch_intent(self, request):
        """Handle LaunchIntent"""
        logger.info("LaunchIntent received")
        session_id = request['session']['sessionId']
        user_id = request['session']['user']['userId']
        
        # Create or retrieve session
        session = self._get_or_create_session(session_id, user_id)
        
        return {
            "version": "1.0",
            "sessionAttributes": session,
            "response": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": "Welcome to Restaurant Ordering Assistant. You can browse our menu, add items to your cart, or place an order. What would you like to do?"
                },
                "shouldEndSession": False
            }
        }
    
    def handle_browse_menu_intent(self, request):
        """Handle BrowseMenuIntent"""
        logger.info("BrowseMenuIntent received")
        session_id = request['session']['sessionId']
        
        # Get menu categories
        categories = self._get_menu_categories()
        
        category_list = ", ".join([cat['name'] for cat in categories[:5]])
        
        return {
            "version": "1.0",
            "sessionAttributes": request.get('session', {}).get('attributes', {}),
            "response": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": f"Our menu categories are: {category_list}. Which would you like to explore?"
                },
                "shouldEndSession": False
            }
        }
    
    def handle_add_item_intent(self, request):
        """Handle AddItemIntent"""
        logger.info("AddItemIntent received")
        session_id = request['session']['sessionId']
        slots = request['request'].get('intent', {}).get('slots', {})
        
        item_name = slots.get('itemName', {}).get('value')
        quantity = int(slots.get('quantity', {}).get('value', 1))
        
        if not item_name:
            return self._alexa_response("Please specify which item you'd like to add.")
        
        # Add to cart
        self._add_to_cart(session_id, item_name, quantity)
        
        return self._alexa_response(
            f"Added {quantity} {item_name} to your cart. Would you like to add more items or proceed to review your order?"
        )
    
    def handle_review_cart_intent(self, request):
        """Handle ReviewCartIntent"""
        logger.info("ReviewCartIntent received")
        session_id = request['session']['sessionId']
        
        cart = self._get_cart(session_id)
        
        if not cart.get('items'):
            return self._alexa_response("Your cart is empty. Would you like to browse our menu?")
        
        # Format cart summary
        items_summary = ", ".join([f"{item['quantity']} {item['name']}" for item in cart['items']])
        total = cart.get('total', 0)
        
        response_text = f"You have {items_summary}. Your total is ${total:.2f}. Would you like to proceed to checkout or make any changes?"
        
        return self._alexa_response(response_text)
    
    def handle_confirm_order_intent(self, request):
        """Handle ConfirmOrderIntent"""
        logger.info("ConfirmOrderIntent received")
        session_id = request['session']['sessionId']
        
        # Create order from cart
        order = self._create_order(session_id)
        
        if not order:
            return self._alexa_response("There was an error processing your order. Please try again.")
        
        # Publish order event to EventBridge
        self._publish_order_event(order)
        
        order_id = order['orderId']
        total = order['total']
        
        response_text = f"Your order has been confirmed. Your order ID is {order_id}. Your total is ${total:.2f}. Your order will be ready soon!"
        
        return self._alexa_response(response_text, end_session=True)
    
    def handle_help_intent(self, request):
        """Handle HelpIntent"""
        logger.info("HelpIntent received")
        
        help_text = """
        You can:
        - Browse our menu by saying 'Browse menu'
        - Add items to your cart by saying 'Add [item name]'
        - View your cart by saying 'Review cart'
        - Place an order by saying 'Confirm order'
        - Cancel your order by saying 'Cancel'
        What would you like to do?
        """
        
        return self._alexa_response(help_text)
    
    def _get_or_create_session(self, session_id, user_id):
        """Get or create a user session"""
        try:
            response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' in response:
                return response['Item']
        except Exception as e:
            logger.error(f"Error retrieving session: {e}")
        
        # Create new session
        session = {
            'sessionId': session_id,
            'userId': user_id,
            'cart': [],
            'guestCount': 1,
            'conversationState': 'browsing',
            'createdAt': datetime.utcnow().isoformat(),
            'expiresAt': int((datetime.utcnow() + timedelta(hours=2)).timestamp())
        }
        
        try:
            self.session_table.put_item(Item=session)
        except Exception as e:
            logger.error(f"Error creating session: {e}")
        
        return session
    
    def _get_menu_categories(self):
        """Get menu categories from Menu Service"""
        # This would call the Menu Service Lambda
        return [
            {'name': 'Appetizers'},
            {'name': 'Main Courses'},
            {'name': 'Desserts'},
            {'name': 'Beverages'},
            {'name': 'Sides'}
        ]
    
    def _add_to_cart(self, session_id, item_name, quantity):
        """Add item to cart in session"""
        try:
            self.session_table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #cart = list_append(if_not_exists(#cart, :empty), :item)',
                ExpressionAttributeNames={'#cart': 'cart'},
                ExpressionAttributeValues={
                    ':empty': [],
                    ':item': [{'name': item_name, 'quantity': quantity, 'timestamp': datetime.utcnow().isoformat()}]
                }
            )
        except Exception as e:
            logger.error(f"Error adding to cart: {e}")
    
    def _get_cart(self, session_id):
        """Get cart from session"""
        try:
            response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' in response:
                cart_items = response['Item'].get('cart', [])
                return {
                    'items': cart_items,
                    'total': len(cart_items) * 15.00  # Simplified calculation
                }
        except Exception as e:
            logger.error(f"Error getting cart: {e}")
        
        return {'items': [], 'total': 0}
    
    def _create_order(self, session_id):
        """Create order from session cart"""
        try:
            session_response = self.session_table.get_item(Key={'sessionId': session_id})
            if 'Item' not in session_response:
                return None
            
            session = session_response['Item']
            cart_items = session.get('cart', [])
            
            if not cart_items:
                return None
            
            order = {
                'orderId': str(uuid.uuid4()),
                'sessionId': session_id,
                'userId': session.get('userId'),
                'items': cart_items,
                'subtotal': len(cart_items) * 15.00,
                'tax': len(cart_items) * 15.00 * 0.08,
                'total': len(cart_items) * 15.00 * 1.08,
                'status': 'confirmed',
                'createdAt': datetime.utcnow().isoformat(),
                'expiresAt': int((datetime.utcnow() + timedelta(days=90)).timestamp())
            }
            
            return order
        except Exception as e:
            logger.error(f"Error creating order: {e}")
            return None
    
    def _publish_order_event(self, order):
        """Publish order event to EventBridge"""
        try:
            events_client.put_events(
                Entries=[
                    {
                        'Source': 'restaurant.ordering',
                        'DetailType': 'OrderConfirmed',
                        'Detail': json.dumps(order),
                        'EventBusName': EVENTBRIDGE_BUS
                    }
                ]
            )
            logger.info(f"Order event published: {order['orderId']}")
        except Exception as e:
            logger.error(f"Error publishing order event: {e}")
    
    def _alexa_response(self, text, end_session=False):
        """Generate Alexa response"""
        return {
            "version": "1.0",
            "response": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": text
                },
                "shouldEndSession": end_session
            }
        }


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        handler = AlexaSkillHandler()
        
        request_type = event['request']['type']
        intent_name = event['request'].get('intent', {}).get('name')
        
        if request_type == 'LaunchRequest':
            return handler.handle_launch_intent(event)
        elif request_type == 'IntentRequest':
            if intent_name == 'BrowseMenuIntent':
                return handler.handle_browse_menu_intent(event)
            elif intent_name == 'AddItemIntent':
                return handler.handle_add_item_intent(event)
            elif intent_name == 'ReviewCartIntent':
                return handler.handle_review_cart_intent(event)
            elif intent_name == 'ConfirmOrderIntent':
                return handler.handle_confirm_order_intent(event)
            elif intent_name == 'HelpIntent':
                return handler.handle_help_intent(event)
        
        return handler._alexa_response("I didn't understand that. Please try again.")
    
    except Exception as e:
        logger.error(f"Error processing request: {e}", exc_info=True)
        return {
            "version": "1.0",
            "response": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": "I encountered an error. Please try again later."
                },
                "shouldEndSession": True
            }
        }
