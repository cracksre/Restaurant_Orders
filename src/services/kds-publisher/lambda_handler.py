"""
KDS Publisher Lambda Function
Publishes orders to Kitchen Display System
"""
import json
import logging
import os
import boto3
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
kinesis_client = boto3.client('kinesis')


class KDSPublisher:
    """Handles Kitchen Display System integration"""
    
    def publish_to_kds(self, order):
        """Publish order to KDS"""
        logger.info(f"Publishing order {order['orderId']} to KDS")
        
        try:
            # Prepare KDS payload
            kds_payload = {
                'orderId': order['orderId'],
                'timestamp': datetime.utcnow().isoformat(),
                'priority': self._calculate_priority(order),
                'items': self._format_kds_items(order['items']),
                'specialInstructions': order.get('specialInstructions', ''),
                'estimatedTime': 20  # minutes
            }
            
            # In production, publish to Kinesis stream
            logger.info(f"KDS Payload: {json.dumps(kds_payload)}")
            
            # For simulation, just log
            response = {
                'success': True,
                'orderId': order['orderId'],
                'message': 'Order sent to KDS'
            }
            
            return response
        except Exception as e:
            logger.error(f"Error publishing to KDS: {e}")
            return {'success': False, 'error': str(e)}
    
    def update_preparation_status(self, order_id, status):
        """Update order preparation status"""
        logger.info(f"Updating preparation status for order {order_id}: {status}")
        
        try:
            status_update = {
                'orderId': order_id,
                'status': status,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            logger.info(f"Status update: {json.dumps(status_update)}")
            
            return {
                'success': True,
                'orderId': order_id,
                'status': status
            }
        except Exception as e:
            logger.error(f"Error updating status: {e}")
            return {'success': False, 'error': str(e)}
    
    def handle_item_ready(self, order_id, item_names):
        """Handle item ready notification"""
        logger.info(f"Items ready for order {order_id}: {item_names}")
        
        try:
            ready_notification = {
                'orderId': order_id,
                'readyItems': item_names,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            logger.info(f"Ready notification: {json.dumps(ready_notification)}")
            
            return {
                'success': True,
                'orderId': order_id,
                'message': 'Item ready notification sent'
            }
        except Exception as e:
            logger.error(f"Error handling ready notification: {e}")
            return {'success': False, 'error': str(e)}
    
    def _calculate_priority(self, order):
        """Calculate order priority"""
        # Simple priority: based on number of items
        item_count = len(order.get('items', []))
        if item_count > 5:
            return 'high'
        elif item_count > 2:
            return 'medium'
        else:
            return 'low'
    
    def _format_kds_items(self, items):
        """Format items for KDS display"""
        formatted = []
        for item in items:
            formatted.append({
                'name': item.get('name'),
                'quantity': item.get('quantity', 1),
                'modifications': item.get('modifications', [])
            })
        return formatted


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        publisher = KDSPublisher()
        
        # Parse request
        http_method = event.get('httpMethod', 'POST')
        path = event.get('path', '')
        body = json.loads(event.get('body', '{}'))
        
        if http_method == 'POST' and path == '/kds/publish':
            order = body.get('order')
            result = publisher.publish_to_kds(order)
        elif http_method == 'PATCH' and path == '/kds/status':
            order_id = body.get('orderId')
            status = body.get('status')
            result = publisher.update_preparation_status(order_id, status)
        elif http_method == 'POST' and path == '/kds/item-ready':
            order_id = body.get('orderId')
            items = body.get('items', [])
            result = publisher.handle_item_ready(order_id, items)
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
