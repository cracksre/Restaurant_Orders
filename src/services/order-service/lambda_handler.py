"""
Order Service Lambda Function
Handles order creation and management
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
ORDER_TABLE = os.environ.get('ORDER_TABLE')
EVENTBRIDGE_BUS = os.environ.get('EVENTBRIDGE_BUS')


class OrderService:
    """Handles order operations"""
    
    def __init__(self):
        self.order_table = dynamodb.Table(ORDER_TABLE)
    
    def create_order(self, order_data):
        """Create a new order"""
        logger.info("Creating new order")
        
        try:
            order_id = str(uuid.uuid4())
            
            order = {
                'orderId': order_id,
                'sessionId': order_data.get('sessionId'),
                'userId': order_data.get('userId'),
                'items': order_data.get('items', []),
                'subtotal': order_data.get('subtotal', 0),
                'tax': order_data.get('tax', 0),
                'total': order_data.get('total', 0),
                'status': 'confirmed',
                'createdAt': datetime.utcnow().isoformat(),
                'expiresAt': int((datetime.utcnow() + timedelta(days=90)).timestamp())
            }
            
            self.order_table.put_item(Item=order)
            
            # Publish event
            self._publish_event(order, 'OrderConfirmed')
            
            logger.info(f"Order created: {order_id}")
            return {'success': True, 'order': order}
        
        except Exception as e:
            logger.error(f"Error creating order: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_order(self, order_id):
        """Get order by ID"""
        logger.info(f"Getting order: {order_id}")
        
        try:
            response = self.order_table.get_item(Key={'orderId': order_id, 'createdAt': ''})
            if 'Item' in response:
                return {'success': True, 'order': response['Item']}
            else:
                return {'success': False, 'error': 'Order not found'}
        except Exception as e:
            logger.error(f"Error getting order: {e}")
            return {'success': False, 'error': str(e)}
    
    def update_order_status(self, order_id, status):
        """Update order status"""
        logger.info(f"Updating order {order_id} status to {status}")
        
        try:
            response = self.order_table.update_item(
                Key={'orderId': order_id, 'createdAt': ''},
                UpdateExpression='SET #status = :status, updatedAt = :updated_at',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': status,
                    ':updated_at': datetime.utcnow().isoformat()
                },
                ReturnValues='ALL_NEW'
            )
            
            # Publish event
            self._publish_event(response['Attributes'], f'Order{status.capitalize()}')
            
            return {'success': True, 'order': response['Attributes']}
        except Exception as e:
            logger.error(f"Error updating order: {e}")
            return {'success': False, 'error': str(e)}
    
    def _publish_event(self, order, event_type):
        """Publish order event to EventBridge"""
        try:
            events_client.put_events(
                Entries=[
                    {
                        'Source': 'restaurant.ordering',
                        'DetailType': event_type,
                        'Detail': json.dumps(order),
                        'EventBusName': EVENTBRIDGE_BUS
                    }
                ]
            )
            logger.info(f"Event published: {event_type}")
        except Exception as e:
            logger.error(f"Error publishing event: {e}")


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        service = OrderService()
        
        # Parse request
        http_method = event.get('httpMethod', 'POST')
        path = event.get('path', '')
        
        if http_method == 'POST' and path == '/order':
            body = json.loads(event.get('body', '{}'))
            result = service.create_order(body)
        elif http_method == 'GET':
            order_id = event.get('queryStringParameters', {}).get('id')
            if not order_id:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'order id required'})
                }
            result = service.get_order(order_id)
        elif http_method == 'PATCH':
            body = json.loads(event.get('body', '{}'))
            order_id = body.get('orderId')
            status = body.get('status')
            if not order_id or not status:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'orderId and status required'})
                }
            result = service.update_order_status(order_id, status)
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
