"""
Upsell Service Lambda Function
Provides intelligent upsell recommendations using AI
"""
import json
import logging
import os
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
bedrock_client = boto3.client('bedrock-runtime')

# Sample upsell rules
UPSELL_RULES = {
    'Burger': [
        {'item': 'Fries', 'recommendation': 'Would you like to add fries?'},
        {'item': 'Drink', 'recommendation': 'How about a beverage?'}
    ],
    'Steak': [
        {'item': 'Wine', 'recommendation': 'A fine wine would pair well with your steak.'},
        {'item': 'Sides', 'recommendation': 'Would you like vegetables or potatoes?'}
    ],
    'Salmon': [
        {'item': 'Wine', 'recommendation': 'A crisp white wine would complement your salmon.'},
        {'item': 'Dessert', 'recommendation': 'Save room for our delicious desserts!'}
    ]
}


class UpsellService:
    """Handles upsell recommendations"""
    
    def get_upsell_recommendations(self, items):
        """Get upsell recommendations based on ordered items"""
        logger.info(f"Getting upsell recommendations for items: {items}")
        
        try:
            recommendations = []
            
            for item in items:
                item_name = item.get('name', '')
                
                # Check predefined rules
                for category, rules in UPSELL_RULES.items():
                    if category.lower() in item_name.lower():
                        for rule in rules:
                            recommendations.append({
                                'itemName': item_name,
                                'suggestedItem': rule['item'],
                                'message': rule['recommendation'],
                                'confidence': 0.85
                            })
            
            return {
                'success': True,
                'recommendations': recommendations,
                'count': len(recommendations)
            }
        except Exception as e:
            logger.error(f"Error getting recommendations: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_ai_recommendation(self, items, context=''):
        """Get AI-powered recommendation using Bedrock"""
        logger.info(f"Getting AI recommendation for items: {items}")
        
        try:
            # Prepare prompt for Claude
            items_str = ', '.join([item.get('name', '') for item in items])
            prompt = f"""You are a restaurant assistant. Based on the customer's order of {items_str}, 
            suggest one complementary item they might want to add. Be friendly and concise. 
            Return just the suggestion, no explanation needed."""
            
            # Call Bedrock (Claude Sonnet)
            response = bedrock_client.invoke_model(
                modelId='anthropic.claude-3-5-sonnet-20241022',
                body=json.dumps({
                    'anthropic_version': 'bedrock-2023-06-01',
                    'max_tokens': 100,
                    'messages': [
                        {
                            'role': 'user',
                            'content': prompt
                        }
                    ]
                })
            )
            
            result = json.loads(response['body'].read())
            suggestion = result['content'][0]['text']
            
            return {
                'success': True,
                'suggestion': suggestion,
                'source': 'ai'
            }
        except Exception as e:
            logger.error(f"Error getting AI recommendation: {e}")
            # Fallback to rule-based recommendations
            return self.get_upsell_recommendations(items)
    
    def calculate_upsell_value(self, items, recommendations):
        """Calculate potential upsell revenue"""
        logger.info("Calculating upsell value")
        
        try:
            # Simple calculation: assume 30% of customers accept upsells
            base_value = sum([item.get('price', 0) for item in items])
            upsell_potential = base_value * 0.30
            
            return {
                'success': True,
                'baseValue': base_value,
                'upsellPotential': upsell_potential,
                'conversionRate': 0.30
            }
        except Exception as e:
            logger.error(f"Error calculating upsell value: {e}")
            return {'success': False, 'error': str(e)}


def lambda_handler(event, context):
    """AWS Lambda handler"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        service = UpsellService()
        
        # Parse request
        http_method = event.get('httpMethod', 'POST')
        path = event.get('path', '')
        body = json.loads(event.get('body', '{}'))
        
        items = body.get('items', [])
        
        if http_method == 'POST' and path == '/upsell/recommendations':
            result = service.get_upsell_recommendations(items)
        elif http_method == 'POST' and path == '/upsell/ai-recommendation':
            result = service.get_ai_recommendation(items, body.get('context', ''))
        elif http_method == 'POST' and path == '/upsell/value':
            recommendations = body.get('recommendations', [])
            result = service.calculate_upsell_value(items, recommendations)
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
