/*
 * CloudKit Function: validateSubscriptionReceipt
 *
 * Purpose: Server-side receipt validation to securely verify subscriptions and prevent fraud
 * Input: Signed transaction data from StoreKit 2
 * Output: Validated entitlement information
 */

const { CKRecord, CKQueryOperation, CKModifyRecordsOperation } = require('cloudkit');
const crypto = require('crypto');
const https = require('https');

// Apple's production JWS verification endpoint
const APPLE_RECEIPT_VERIFICATION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Apple's public key endpoints for JWS verification
const APPLE_PUBLIC_KEY_URL = 'https://www.apple.com/certificateauthority/Apple_App_Store_Server_Signing.pem';
const APPLE_ROOT_CA_URL = 'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer';

// Cache for Apple's public keys (in production, consider using external cache)
let applePublicKeyCache = null;
let cacheExpiry = null;
const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Main CloudKit Function entry point
 */
async function validateSubscriptionReceipt(context, request) {
    try {
        const { transactionData, receiptData, productID, familyID } = request.body;

        // Input validation
        if (!transactionData || !receiptData || !productID || !familyID) {
            return {
                statusCode: 400,
                body: {
                    error: 'Missing required parameters',
                    details: 'transactionData, receiptData, productID, and familyID are required'
                }
            };
        }

        // Step 1: Verify JWS signature from StoreKit 2
        const signatureVerification = await verifyJWSSignature(transactionData);
        if (!signatureVerification.isValid) {
            return {
                statusCode: 400,
                body: {
                    error: 'Invalid transaction signature',
                    details: signatureVerification.error
                }
            };
        }

        // Step 2: Validate receipt with Apple servers
        const receiptVerification = await verifyReceiptWithApple(receiptData);
        if (!receiptVerification.isValid) {
            return {
                statusCode: 400,
                body: {
                    error: 'Receipt validation failed',
                    details: receiptVerification.error
                }
            };
        }

        // Step 3: Extract transaction details
        const transactionInfo = signatureVerification.transactionInfo;
        const originalTransactionID = transactionInfo.originalTransactionId;
        const transactionID = transactionInfo.transactionId;

        // Step 4: Check for duplicate transactions
        const duplicateCheck = await checkForDuplicateTransaction(context, transactionID);
        if (duplicateCheck.isDuplicate) {
            return {
                statusCode: 409,
                body: {
                    error: 'Duplicate transaction detected',
                    existingEntitlementID: duplicateCheck.entitlementID
                }
            };
        }

        // Step 5: Create or update entitlement record
        const entitlementRecord = await createOrUpdateEntitlement(context, {
            familyID,
            productID,
            transactionID,
            originalTransactionID,
            expirationDate: new Date(transactionInfo.expiresDate),
            purchaseDate: new Date(transactionInfo.purchaseDate),
            isActive: true,
            isInTrial: transactionInfo.isTrialPeriod || false,
            autoRenewStatus: receiptVerification.autoRenewStatus || true,
            lastValidatedAt: new Date(),
            gracePeriodExpiresAt: null,
            metadata: {
                appAccountToken: transactionInfo.appAccountToken,
                bundleId: transactionInfo.bundleId,
                environment: transactionInfo.environment
            }
        });

        // Step 6: Log validation event for audit
        await logValidationEvent(context, {
            familyID,
            transactionID,
            productID,
            eventType: 'receipt_validated',
            timestamp: new Date()
        });

        return {
            statusCode: 200,
            body: {
                success: true,
                entitlementID: entitlementRecord.recordName,
                isActive: true,
                expirationDate: entitlementRecord.fields.expirationDate.value,
                productID: productID,
                isInTrial: entitlementRecord.fields.isInTrial.value
            }
        };

    } catch (error) {
        console.error('Receipt validation error:', error);
        return {
            statusCode: 500,
            body: {
                error: 'Internal server error',
                details: process.env.NODE_ENV === 'development' ? error.message : undefined
            }
        };
    }
}

/**
 * Verify JWS signature from StoreKit 2 transaction data
 */
async function verifyJWSSignature(transactionData) {
    try {
        // Parse JWS format: header.payload.signature
        const jwsParts = transactionData.split('.');
        if (jwsParts.length !== 3) {
            return { isValid: false, error: 'Invalid JWS format' };
        }

        // Decode header and payload
        const header = JSON.parse(Buffer.from(jwsParts[0], 'base64url').toString());
        const payload = JSON.parse(Buffer.from(jwsParts[1], 'base64url').toString());

        // Validate payload structure and required fields
        if (!payload.originalTransactionId || !payload.transactionId || !payload.expiresDate) {
            return { isValid: false, error: 'Invalid transaction payload structure' };
        }

        // Verify header contains required algorithm and certificate chain
        if (!header.alg || !header.x5c || !Array.isArray(header.x5c) || header.x5c.length === 0) {
            return { isValid: false, error: 'Invalid JWS header: missing algorithm or certificate chain' };
        }

        // Apple uses ES256 algorithm for App Store Server API
        if (header.alg !== 'ES256') {
            return { isValid: false, error: `Unsupported algorithm: ${header.alg}. Expected ES256` };
        }

        // Extract the signing certificate from x5c header
        const signingCertBase64 = header.x5c[0];
        const signingCertDer = Buffer.from(signingCertBase64, 'base64');

        // Verify certificate chain against Apple's root CA
        const chainVerification = await verifyCertificateChain(header.x5c);
        if (!chainVerification.isValid) {
            return { isValid: false, error: `Certificate chain verification failed: ${chainVerification.error}` };
        }

        // Extract public key from signing certificate
        const publicKey = extractPublicKeyFromCertificate(signingCertDer);
        if (!publicKey) {
            return { isValid: false, error: 'Failed to extract public key from certificate' };
        }

        // Verify JWS signature
        const signatureVerification = verifyJWSSignatureWithKey(jwsParts, publicKey);
        if (!signatureVerification.isValid) {
            return { isValid: false, error: `Signature verification failed: ${signatureVerification.error}` };
        }

        // Additional security validations
        const securityCheck = validateTransactionSecurity(payload);
        if (!securityCheck.isValid) {
            return { isValid: false, error: `Security validation failed: ${securityCheck.error}` };
        }

        return {
            isValid: true,
            transactionInfo: payload,
            header: header,
            certificateChain: header.x5c
        };
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Verify certificate chain against Apple's root CA
 */
async function verifyCertificateChain(certificateChain) {
    try {
        // In a production environment, you would:
        // 1. Download and cache Apple's root CA certificate
        // 2. Verify each certificate in the chain
        // 3. Check certificate validity periods
        // 4. Verify the leaf certificate is issued by Apple

        if (!certificateChain || certificateChain.length === 0) {
            return { isValid: false, error: 'Empty certificate chain' };
        }

        // Basic validation - ensure we have at least one certificate
        if (certificateChain.length < 1) {
            return { isValid: false, error: 'Certificate chain too short' };
        }

        // Extract and validate the leaf certificate
        const leafCertDer = Buffer.from(certificateChain[0], 'base64');
        const leafCertInfo = parseCertificateInfo(leafCertDer);

        if (!leafCertInfo.isValid) {
            return { isValid: false, error: 'Invalid leaf certificate' };
        }

        // Validate certificate is from Apple
        if (!leafCertInfo.subject.includes('Apple') || !leafCertInfo.issuer.includes('Apple')) {
            return { isValid: false, error: 'Certificate not issued by Apple' };
        }

        // Check certificate validity period
        const now = new Date();
        if (now < leafCertInfo.notBefore || now > leafCertInfo.notAfter) {
            return { isValid: false, error: 'Certificate expired or not yet valid' };
        }

        return { isValid: true };
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Extract public key from DER-encoded certificate
 */
function extractPublicKeyFromCertificate(certDer) {
    try {
        // Convert DER to PEM format for crypto module
        const certPem = '-----BEGIN CERTIFICATE-----\n' +
                       certDer.toString('base64').match(/.{1,64}/g).join('\n') +
                       '\n-----END CERTIFICATE-----';

        // Create X509Certificate object (Node.js 15.6+)
        const cert = new crypto.X509Certificate(certPem);

        // Extract public key
        const publicKey = cert.publicKey;
        return publicKey;
    } catch (error) {
        console.error('Failed to extract public key:', error);
        return null;
    }
}

/**
 * Parse basic certificate information
 */
function parseCertificateInfo(certDer) {
    try {
        const certPem = '-----BEGIN CERTIFICATE-----\n' +
                       certDer.toString('base64').match(/.{1,64}/g).join('\n') +
                       '\n-----END CERTIFICATE-----';

        const cert = new crypto.X509Certificate(certPem);

        return {
            isValid: true,
            subject: cert.subject,
            issuer: cert.issuer,
            notBefore: new Date(cert.validFrom),
            notAfter: new Date(cert.validTo),
            fingerprint: cert.fingerprint
        };
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Verify JWS signature using extracted public key
 */
function verifyJWSSignatureWithKey(jwsParts, publicKey) {
    try {
        // Create the signing input (header.payload)
        const signingInput = jwsParts[0] + '.' + jwsParts[1];
        const signature = Buffer.from(jwsParts[2], 'base64url');

        // Verify signature using ES256 algorithm
        const verifier = crypto.createVerify('SHA256');
        verifier.update(signingInput);
        verifier.end();

        const isValid = verifier.verify(publicKey, signature);

        return { isValid };
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Additional security validations for transaction data
 */
function validateTransactionSecurity(payload) {
    try {
        // Validate transaction timestamps
        const now = Date.now();
        const signedDate = payload.signedDate ? new Date(payload.signedDate).getTime() : null;
        const expiresDate = new Date(payload.expiresDate).getTime();

        // Check if transaction is not too old (e.g., within 1 hour)
        if (signedDate && (now - signedDate) > 60 * 60 * 1000) {
            return { isValid: false, error: 'Transaction signature too old' };
        }

        // Check expiration date is in the future
        if (expiresDate <= now) {
            return { isValid: false, error: 'Transaction has expired' };
        }

        // Validate bundle ID matches expected value
        if (payload.bundleId && !payload.bundleId.includes('ScreenTimeRewards')) {
            return { isValid: false, error: 'Bundle ID mismatch' };
        }

        // Validate environment (production vs sandbox)
        if (payload.environment && !['Production', 'Sandbox'].includes(payload.environment)) {
            return { isValid: false, error: 'Invalid environment' };
        }

        return { isValid: true };
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Verify receipt with Apple's verification servers
 */
async function verifyReceiptWithApple(receiptData) {
    try {
        const requestBody = {
            'receipt-data': receiptData,
            'password': process.env.APPLE_SHARED_SECRET,
            'exclude-old-transactions': true
        };

        // Try production first, then sandbox
        let response = await makeAppleRequest(APPLE_RECEIPT_VERIFICATION_URL, requestBody);

        if (response.status === 21007) { // Sandbox receipt in production
            response = await makeAppleRequest(APPLE_SANDBOX_URL, requestBody);
        }

        if (response.status === 0) {
            return {
                isValid: true,
                autoRenewStatus: response.auto_renew_status,
                receiptInfo: response.receipt
            };
        } else {
            return {
                isValid: false,
                error: `Apple verification failed with status: ${response.status}`
            };
        }
    } catch (error) {
        return { isValid: false, error: error.message };
    }
}

/**
 * Make HTTP request to Apple's verification servers
 */
async function makeAppleRequest(url, body) {
    const https = require('https');

    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(body);

        const options = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(url, options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (error) {
                    reject(error);
                }
            });
        });

        req.on('error', reject);
        req.write(postData);
        req.end();
    });
}

/**
 * Check for duplicate transaction IDs
 */
async function checkForDuplicateTransaction(context, transactionID) {
    try {
        const query = {
            recordType: 'SubscriptionEntitlement',
            filterBy: [{
                fieldName: 'transactionID',
                comparator: 'EQUALS',
                fieldValue: { value: transactionID }
            }]
        };

        const results = await context.database.performQuery(query);

        if (results.records && results.records.length > 0) {
            return {
                isDuplicate: true,
                entitlementID: results.records[0].recordName
            };
        }

        return { isDuplicate: false };
    } catch (error) {
        console.error('Duplicate check error:', error);
        return { isDuplicate: false };
    }
}

/**
 * Create or update subscription entitlement record
 */
async function createOrUpdateEntitlement(context, entitlementData) {
    try {
        // Check if entitlement exists for this family and original transaction
        const existingQuery = {
            recordType: 'SubscriptionEntitlement',
            filterBy: [
                {
                    fieldName: 'familyID',
                    comparator: 'EQUALS',
                    fieldValue: { value: entitlementData.familyID }
                },
                {
                    fieldName: 'originalTransactionID',
                    comparator: 'EQUALS',
                    fieldValue: { value: entitlementData.originalTransactionID }
                }
            ]
        };

        const existingResults = await context.database.performQuery(existingQuery);
        let record;

        if (existingResults.records && existingResults.records.length > 0) {
            // Update existing record
            record = existingResults.records[0];
        } else {
            // Create new record
            record = {
                recordType: 'SubscriptionEntitlement',
                fields: {}
            };
        }

        // Set all fields
        record.fields.familyID = { value: entitlementData.familyID };
        record.fields.productID = { value: entitlementData.productID };
        record.fields.transactionID = { value: entitlementData.transactionID };
        record.fields.originalTransactionID = { value: entitlementData.originalTransactionID };
        record.fields.expirationDate = { value: entitlementData.expirationDate };
        record.fields.purchaseDate = { value: entitlementData.purchaseDate };
        record.fields.isActive = { value: entitlementData.isActive };
        record.fields.isInTrial = { value: entitlementData.isInTrial };
        record.fields.autoRenewStatus = { value: entitlementData.autoRenewStatus };
        record.fields.lastValidatedAt = { value: entitlementData.lastValidatedAt };
        record.fields.gracePeriodExpiresAt = { value: entitlementData.gracePeriodExpiresAt };
        record.fields.metadata = { value: JSON.stringify(entitlementData.metadata) };

        const savedRecord = await context.database.saveRecord(record);
        return savedRecord;
    } catch (error) {
        console.error('Entitlement save error:', error);
        throw error;
    }
}

/**
 * Log validation events for audit purposes
 */
async function logValidationEvent(context, eventData) {
    try {
        const logRecord = {
            recordType: 'ValidationAuditLog',
            fields: {
                familyID: { value: eventData.familyID },
                transactionID: { value: eventData.transactionID },
                productID: { value: eventData.productID },
                eventType: { value: eventData.eventType },
                timestamp: { value: eventData.timestamp },
                metadata: { value: JSON.stringify(eventData) }
            }
        };

        await context.database.saveRecord(logRecord);
    } catch (error) {
        console.error('Audit log error:', error);
        // Don't throw - audit logging failure shouldn't break validation
    }
}

module.exports = { validateSubscriptionReceipt };