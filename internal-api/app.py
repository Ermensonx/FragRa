#!/usr/bin/env python3
"""
Internal Metadata API - Cloud Fragment CTF
Simulates cloud instance metadata service (like AWS IMDSv1)
Contains USER_FLAG
"""

import os
from flask import Flask, jsonify, request

app = Flask(__name__)

# Configuration from environment
USER_FLAG = os.environ.get('USER_FLAG', 'HTB{default_flag_not_set}')
SERVICE_NAME = os.environ.get('SERVICE_NAME', 'ops-metadata')

@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'service': SERVICE_NAME
    })

@app.route('/')
def index():
    return jsonify({
        'service': SERVICE_NAME,
        'version': '1.2.0',
        'endpoints': [
            '/health',
            '/v1/instance/id',
            '/v1/instance/hostname',
            '/v1/instance/user-data',
            '/v1/service-discovery'
        ]
    })

@app.route('/v1/instance/id')
def instance_id():
    return jsonify({
        'instance_id': 'i-0a1b2c3d4e5f67890',
        'region': 'us-east-1',
        'availability_zone': 'us-east-1a'
    })

@app.route('/v1/instance/hostname')
def hostname():
    return jsonify({
        'hostname': 'ops-console-prod-01.internal',
        'internal_ip': '192.168.100.1',
        'mac': '02:42:c0:a8:64:01'
    })

@app.route('/v1/instance/user-data')
def user_data():
    """This endpoint contains the USER flag!"""
    return jsonify({
        'flag': USER_FLAG,
        'note': 'Congratulations! You exploited CVE-2025-55182 and reached the internal metadata service.',
        'next_hint': 'Look for mounted service account tokens at /run/secrets/kubernetes.io/serviceaccount/'
    })

@app.route('/v1/service-discovery')
def service_discovery():
    """Hints for finding the secrets-vault service"""
    return jsonify({
        'services': {
            'internal-api': '192.168.100.10:8080',
            'secrets-vault': '192.168.100.20:443',
            'internal-dns': '192.168.100.53:53'
        },
        'note': 'secrets-vault requires valid service account token'
    })

@app.route('/v1/iam/security-credentials')
def iam_creds():
    """Red herring - simulates AWS metadata but returns nothing useful"""
    return jsonify({
        'error': 'No IAM role attached to this instance',
        'hint': 'Try /v1/instance/user-data instead'
    }), 404

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({
        'error': 'Endpoint not found',
        'available': '/'
    }), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
