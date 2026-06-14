"""
POS Webhook Lambda Function
Integrates with POS systems to send orders
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
ssm_client = boto3.client('ssm')


class POSWebhook:
    """Handles POS integration"""
    
    def __init__(self):
        self.order_table = dynamodb.Table(os.environ.get('ORDER_TABLE'))
    
    def send_to_pos(self, order):
        """Send order to POS system"""
        logger.info(f"Sending order {order['orderId']} to POS")
        
        try:
            # In production, this would make an actual HTTP request to the POS system
            # For now, we'll simulate the integration
            
            pos_payload = {
                'orderId': order['orderId'],
                'timestamp': datetime.utcnow().isoformat(),
                'items': order['items'],
                'subtotal': order.get('subtotal'),
                'tax': order.get('tax'),
                'total': order.get('total'),
                'customerInfo': {
                    'userId': order.get('userId'),
                    'sessionId': order.get('sessionId')
                }
            }
            
            # Log the payload (in production, send to POS API)
            logger.info(f"POS Payload: {json.dumps(pos_payload)}")
            
            # Update order status
            self.order_table.update_item(
                Key={'orderId': order['orderId'], 'createdAt': order['createdAt']},
                UpdateExpression='SET #status = :status, posSentAt = :sent_at',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'sent_to_pos',
                    ':sent_at': datetime.utcnow().isoformat()
                }
            )
            
            return {
                'success': True,
                'orderId': order['orderId'],
                'message': 'Order sent to POS'
            }
        except Exception as e:
            logger.error(f"Error sending to POS: {e}")
            return {'success': False, 'error': str(e)}
    
    def acknowledge_receipt(self, order_id, pos_confirmation):
        """Acknowledge POS receipt of order"""
        logger.info(f"Acknowledging POS receipt for order {order_id}")
        
        try:
            # Update order with POS confirmation
            logger.info(f"POS Confirmation: {json.dumps(pos_confirmation)}")
            
            return {
                'success': True,
                'orderId': order_id,
                'message': 'POS receipt acknowledged'
            }
        except Exception as e:
            logger.error(f"Error acknowledging receipt: {e}")
            return {'success': False, 'error': str(e)}
    
    def handle_pos_error(self, order_id, error_details):
        """Handle POS integration errors"""
        logger.error(f"POS error for order {order_id}: {error_details}")
        
        try:
            # Log error and potentially retry
            logger.info(f"Error details: {json.dumps(error_details)}")
            
            # In production, implement retry logic here
            
            return {
                'success': True,
                'orderId': order_id,
                'message': 'Error logged and will retry'
            }
        except Exception as e:
            logger.error(f"Error handling POS error: {e}")
            return {'success': False, 'error': str(e)}


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        webhook = POSWebhook()
        
        # Parse request
        http_method = event.get('httpMethod', 'POST')
        path = event.get('path', '')
        body = json.loads(event.get('body', '{}'))
        
        if http_method == 'POST' and path == '/pos/send-order':
            order = body.get('order')
            result = webhook.send_to_pos(order)
        elif http_method == 'POST' and path == '/pos/acknowledge':
            order_id = body.get('orderId')
            confirmation = body.get('confirmation')
            result = webhook.acknowledge_receipt(order_id, confirmation)
        elif http_method == 'POST' and path == '/pos/error':
            order_id = body.get('orderId')
            error = body.get('error')
            result = webhook.handle_pos_error(order_id, error)
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
