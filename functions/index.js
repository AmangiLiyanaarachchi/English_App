const admin = require('firebase-admin');
const crypto = require('crypto');
const { logger } = require('firebase-functions');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

admin.initializeApp();

const payhereMerchantIdSecret = defineSecret('PAYHERE_MERCHANT_ID');
const payhereMerchantSecretSecret = defineSecret('PAYHERE_MERCHANT_SECRET');

function md5Upper(value) {
    return crypto.createHash('md5').update(value, 'utf8').digest('hex').toUpperCase();
}

function normalizeMerchantSecret(rawSecret) {
    const secret = toStringSafe(rawSecret).trim();
    if (!secret) return '';

    try {
        const decoded = Buffer.from(secret, 'base64').toString('utf8');
        return decoded.trim() || secret;
    } catch (_) {
        return secret;
    }
}

function toDateSafe(value) {
    if (!value) return null;
    if (value instanceof Date) return value;
    if (typeof value.toDate === 'function') return value.toDate();
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function parseNotifyPayload(req) {
    const body = req.body || {};
    const rawBody = req.rawBody ? req.rawBody.toString() : '';

    let payload = body;
    if ((!payload || Object.keys(payload).length === 0) && rawBody.includes('=')) {
        payload = Object.fromEntries(new URLSearchParams(rawBody));
    }

    return payload || {};
}

function computeExpectedMd5Sig(payload, merchantSecret) {
    const merchantId = toStringSafe(payload.merchant_id);
    const orderId = toStringSafe(payload.order_id);
    const payhereAmount = toStringSafe(payload.payhere_amount);
    const payhereCurrency = toStringSafe(payload.payhere_currency).toUpperCase();
    const statusCode = toStringSafe(payload.status_code);
    const merchantSecretMd5 = md5Upper(normalizeMerchantSecret(merchantSecret));
    const sigString = `${merchantId}${orderId}${payhereAmount}${payhereCurrency}${statusCode}${merchantSecretMd5}`;
    return md5Upper(sigString);
}

function parseAmount(value) {
    const n = Number(value);
    if (!Number.isFinite(n)) return null;
    return Number(n.toFixed(2));
}

function getExpiryDateFromDuration(duration) {
    const text = toStringSafe(duration).toLowerCase();
    const now = new Date();

    if (text.includes('week')) {
        return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    }

    if (text.includes('6 month')) {
        return new Date(now.getTime() + 180 * 24 * 60 * 60 * 1000);
    }

    return new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
}

function buildAllUnlockedFeaturesFromSubscriptions(subscriptions) {
    const allUnlocked = [];

    Object.entries(subscriptions || {}).forEach(([key, value]) => {
        if (!value || typeof value !== 'object') return;

        const expiry = toDateSafe(value.expiryDate);
        if (!expiry || expiry <= new Date()) return;

        if (key === 'community' && !allUnlocked.includes('community')) {
            allUnlocked.push('community');
        }
        if (key === 'ai_agent' && !allUnlocked.includes('ai_agent')) {
            allUnlocked.push('ai_agent');
        }
    });

    return allUnlocked;
}

function packageNameFromFeatures(features) {
    const hasCommunity = features.includes('community');
    const hasAiAgent = features.includes('ai_agent');

    if (hasCommunity && hasAiAgent) return 'Community + AI Agent';
    if (hasCommunity) return 'Community Plan';
    if (hasAiAgent) return 'AI Agent';
    return 'None';
}

async function grantEntitlementsFromVerifiedPayment(paymentRef, payload) {
    await admin.firestore().runTransaction(async (tx) => {
        const paymentSnap = await tx.get(paymentRef);
        if (!paymentSnap.exists) {
            throw new Error('Payment document not found for entitlement grant');
        }

        const payment = paymentSnap.data() || {};
        if (payment.entitlementGrantedAt) {
            return;
        }

        const userId = toStringSafe(payment.userId);
        const orderId = toStringSafe(payment.orderId || payload.order_id);
        const paymentId = toStringSafe(payload.payment_id || payment.paymentId);
        const selectedPlan = toStringSafe(payment.plan);
        const selectedDuration = toStringSafe(payment.duration);
        const amount = parseAmount(payment.amount) || parseAmount(payload.payhere_amount) || 0;
        const currency = toStringSafe(payment.currency || payload.payhere_currency || 'LKR').toUpperCase();
        const type = toStringSafe(payment.type);

        if (!userId) {
            throw new Error('Missing userId in payment document');
        }

        const userRef = admin.firestore().collection('users').doc(userId);
        const userSnap = await tx.get(userRef);
        const userData = userSnap.exists ? (userSnap.data() || {}) : {};

        if (type === 'voice_topup') {
            const explicitMinutes = Number(payment.minutesAdded || 0);
            const parsedMinutes = Number(toStringSafe(selectedDuration).replace(/[^0-9]/g, ''));
            const minutesAdded = explicitMinutes > 0 ? explicitMinutes : (Number.isFinite(parsedMinutes) ? parsedMinutes : 0);
            const currentTotal = Number(userData.voiceTotalMinutes || 0);
            const newTotal = currentTotal + Math.max(0, minutesAdded);

            tx.set(userRef, {
                voiceTotalMinutes: newTotal,
                voiceEnabled: true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            tx.set(paymentRef, {
                status: 'verified',
                paymentId,
                amount,
                currency,
                minutesAdded: Math.max(0, minutesAdded),
                entitlementGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
                verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                verifiedBy: 'payhere_notify',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

            return;
        }

        const expiryDate = getExpiryDateFromDuration(selectedDuration);
        const subscriptions = (userData.subscriptions && typeof userData.subscriptions === 'object')
            ? { ...userData.subscriptions }
            : {};

        const currentPurchaseFeatures = [];

        if (selectedPlan.includes('Community')) {
            let voiceTotalMinutes = 0;
            if (selectedDuration === '1 Month') voiceTotalMinutes = 255;
            if (selectedDuration === '6 Months') voiceTotalMinutes = 540;

            subscriptions.community = {
                expiryDate,
                plan: selectedPlan,
                duration: selectedDuration,
                price: amount,
                voiceTotalMinutes,
            };
            currentPurchaseFeatures.push('community');
        }

        if (selectedPlan.includes('AI Agent')) {
            let aiTotalSeconds = 0;
            let planType = '';
            if (selectedDuration === '1000 Credits') {
                aiTotalSeconds = 1200;
                planType = 'AI_1000';
            } else if (selectedDuration === '2500 Credits') {
                aiTotalSeconds = 2700;
                planType = 'AI_2500';
            }

            subscriptions.ai_agent = {
                expiryDate,
                plan: selectedPlan,
                duration: selectedDuration,
                price: amount,
                aiTotalSeconds,
                planType,
            };
            currentPurchaseFeatures.push('ai_agent');
        }

        const allUnlockedFeatures = buildAllUnlockedFeaturesFromSubscriptions(subscriptions);
        currentPurchaseFeatures.forEach((feature) => {
            if (!allUnlockedFeatures.includes(feature)) {
                allUnlockedFeatures.push(feature);
            }
        });

        const packageName = packageNameFromFeatures(allUnlockedFeatures);

        const userUpdate = {
            package: packageName,
            subscriptions,
            duration: selectedDuration,
            price: amount,
            paymentStatus: 'paid',
            expiryDate,
            unlockedFeatures: allUnlockedFeatures,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (toStringSafe(payment.firstName)) userUpdate.firstName = toStringSafe(payment.firstName);
        if (toStringSafe(payment.lastName)) userUpdate.lastName = toStringSafe(payment.lastName);
        if (toStringSafe(payment.phone)) userUpdate.phone = toStringSafe(payment.phone);

        if (subscriptions.ai_agent) {
            userUpdate.planType = subscriptions.ai_agent.planType;
            userUpdate.aiTotalSeconds = subscriptions.ai_agent.aiTotalSeconds;
            userUpdate.aiUsedSeconds = Number(userData.aiUsedSeconds || 0);
            userUpdate.aiEnabled = true;
        }

        if (subscriptions.community) {
            userUpdate.voiceTotalMinutes = Number(subscriptions.community.voiceTotalMinutes || 0);
            userUpdate.voiceUsedMinutes = Number(userData.voiceUsedMinutes || 0);
            userUpdate.voiceEnabled = true;
            userUpdate.communityPlan = selectedDuration === '1 Month' ? '1_MONTH' : '6_MONTH';
        }

        tx.set(userRef, userUpdate, { merge: true });

        tx.set(paymentRef, {
            orderId,
            paymentId,
            status: 'verified',
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            verifiedBy: 'payhere_notify',
            entitlementGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
            amount,
            currency,
            unlockedFeatures: allUnlockedFeatures,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
}

exports.payhereNotify = onRequest(
    {
        region: 'us-central1',
        secrets: [payhereMerchantIdSecret, payhereMerchantSecretSecret],
    },
    async (req, res) => {
        if (req.method !== 'POST') {
            res.status(405).send('Method Not Allowed');
            return;
        }

        try {
            const payload = parseNotifyPayload(req);
            const orderId = toStringSafe(payload.order_id);
            const incomingMerchantId = toStringSafe(payload.merchant_id);
            const incomingMd5Sig = toStringSafe(payload.md5sig).toUpperCase();
            const statusCode = toStringSafe(payload.status_code);
            const payhereAmount = parseAmount(payload.payhere_amount);
            const payhereCurrency = toStringSafe(payload.payhere_currency).toUpperCase();

            const expectedMerchantId = toStringSafe(payhereMerchantIdSecret.value());
            const expectedMerchantSecret = toStringSafe(payhereMerchantSecretSecret.value());

            const merchantMatched =
                expectedMerchantId.length === 0 || incomingMerchantId === expectedMerchantId;
            const expectedMd5Sig = computeExpectedMd5Sig(payload, expectedMerchantSecret);
            const signatureMatched = incomingMd5Sig.length > 0 && incomingMd5Sig === expectedMd5Sig;
            const statusSuccess = statusCode === '2';

            let paymentRef = admin.firestore().collection('payments').doc(orderId);
            let paymentSnap = await paymentRef.get();

            if (!paymentSnap.exists && orderId) {
                const querySnap = await admin.firestore()
                    .collection('payments')
                    .where('orderId', '==', orderId)
                    .limit(1)
                    .get();
                if (!querySnap.empty) {
                    paymentRef = querySnap.docs[0].ref;
                    paymentSnap = querySnap.docs[0];
                }
            }

            const paymentData = paymentSnap.exists ? (paymentSnap.data() || {}) : {};
            const expectedAmount = parseAmount(paymentData.amount);
            const expectedCurrency = toStringSafe(paymentData.currency).toUpperCase();

            const amountMatched =
                expectedAmount === null || payhereAmount === null || expectedAmount === payhereAmount;
            const currencyMatched =
                !expectedCurrency || !payhereCurrency || expectedCurrency === payhereCurrency;

            const verificationPassed =
                merchantMatched && signatureMatched && statusSuccess && amountMatched && currencyMatched;

            await admin.firestore().collection('payhereNotifications').add({
                payload,
                receivedAt: admin.firestore.FieldValue.serverTimestamp(),
                userAgent: toStringSafe(req.get('user-agent')),
                ip: toStringSafe(req.ip),
                verification: {
                    orderId,
                    incomingMerchantId,
                    expectedMerchantId,
                    signatureMatched,
                    statusSuccess,
                    amountMatched,
                    currencyMatched,
                    verificationPassed,
                },
            });

            if (!paymentSnap.exists && orderId) {
                await paymentRef.set({
                    orderId,
                    status: verificationPassed ? 'verified' : 'notify_received',
                    payhereStatusCode: statusCode,
                    payherePaymentId: toStringSafe(payload.payment_id),
                    amount: payhereAmount,
                    currency: payhereCurrency,
                    notifyPayload: payload,
                    verification: {
                        signatureMatched,
                        merchantMatched,
                        amountMatched,
                        currencyMatched,
                        verificationPassed,
                    },
                    verifiedAt: verificationPassed
                        ? admin.firestore.FieldValue.serverTimestamp()
                        : null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            } else {
                await paymentRef.set({
                    status: verificationPassed ? 'verified' : 'notify_received',
                    payhereStatusCode: statusCode,
                    payherePaymentId: toStringSafe(payload.payment_id),
                    amount: payhereAmount,
                    currency: payhereCurrency,
                    notifyPayload: payload,
                    verification: {
                        signatureMatched,
                        merchantMatched,
                        amountMatched,
                        currencyMatched,
                        verificationPassed,
                    },
                    verifiedAt: verificationPassed
                        ? admin.firestore.FieldValue.serverTimestamp()
                        : null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            }

            if (verificationPassed) {
                await grantEntitlementsFromVerifiedPayment(paymentRef, payload);
            }

            logger.info('PayHere notify received', {
                orderId,
                paymentId: toStringSafe(payload.payment_id),
                statusCode,
                verified: verificationPassed,
            });

            // PayHere expects 200 OK on successful notify delivery.
            res.status(200).send('OK');
        } catch (error) {
            logger.error('PayHere notify failed', error);
            res.status(500).send('ERROR');
        }
    }
);

function toStringSafe(value) {
    if (value === null || value === undefined) return '';
    return String(value);
}

async function getUserTokens(userId) {
    if (!userId) return [];

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    const data = userDoc.data() || {};
    const tokenList = [];

    if (Array.isArray(data.fcmTokens)) {
        tokenList.push(...data.fcmTokens.filter(Boolean));
    }

    if (data.fcmToken) {
        tokenList.push(data.fcmToken);
    }

    return [...new Set(tokenList)];
}

async function cleanupInvalidTokens(userId, tokens, response) {
    if (!userId || !Array.isArray(tokens) || !response || !response.responses) {
        return;
    }

    const invalidTokens = [];

    response.responses.forEach((result, index) => {
        if (!result.success) {
            const code = result.error?.code || '';
            if (
                code === 'messaging/registration-token-not-registered' ||
                code === 'messaging/invalid-registration-token'
            ) {
                invalidTokens.push(tokens[index]);
            }
        }
    });

    if (invalidTokens.length === 0) return;

    await admin.firestore().collection('users').doc(userId).set(
        {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        },
        { merge: true }
    );
}

exports.notifyIncomingCall = onDocumentCreated(
    {
        document: 'calls/{callId}',
        region: 'us-central1',
    },
    async (event) => {
        const snap = event.data;
        if (!snap) {
            return null;
        }

        const call = snap.data() || {};

        if (call.status !== 'calling') {
            return null;
        }

        const receiverId = toStringSafe(call.receiverId);
        const tokens = await getUserTokens(receiverId);

        if (tokens.length === 0) {
            logger.info(`No FCM tokens found for receiver: ${receiverId}`);
            return null;
        }

        const dataPayload = {
            type: 'call',
            callId: toStringSafe(call.callId || event.params.callId),
            callerId: toStringSafe(call.callerId),
            callerName: toStringSafe(call.callerName),
            callerPhotoUrl: toStringSafe(call.callerPhotoUrl),
            receiverId: receiverId,
            receiverName: toStringSafe(call.receiverName),
            receiverPhotoUrl: toStringSafe(call.receiverPhotoUrl),
            agoraChannelId: toStringSafe(call.agoraChannelId),
            status: 'calling',
            timestamp: toStringSafe(call.timestamp || new Date().toISOString()),
            title: 'Incoming Call',
            body: `${toStringSafe(call.callerName || 'Global Gate')} is calling you`,
        };

        const message = {
            tokens,
            data: dataPayload,
            android: {
                priority: 'high',
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                    'apns-push-type': 'background',
                },
                payload: {
                    aps: {
                        contentAvailable: true,
                    },
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        await cleanupInvalidTokens(receiverId, tokens, response);

        logger.info(
            `Incoming call notification sent: success=${response.successCount}, failure=${response.failureCount}`
        );

        return null;
    }
);

exports.notifyNewMessage = onDocumentCreated(
    {
        document: 'chatRooms/{chatId}/messages/{messageId}',
        region: 'us-central1',
    },
    async (event) => {
        const snap = event.data;
        if (!snap) {
            return null;
        }

        const messageData = snap.data() || {};

        const senderId = toStringSafe(messageData.senderUid);
        const receiverId = toStringSafe(messageData.receiverUid);

        if (!receiverId || senderId === receiverId) {
            return null;
        }

        const tokens = await getUserTokens(receiverId);
        if (tokens.length === 0) {
            logger.info(`No FCM tokens found for message receiver: ${receiverId}`);
            return null;
        }

        let senderName = toStringSafe(messageData.senderName);
        if (!senderName) {
            const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
            senderName = toStringSafe(senderDoc.data()?.displayName || 'Global Gate User');
        }

        const messageText = toStringSafe(messageData.text || 'New message');

        const dataPayload = {
            type: 'message',
            chatId: toStringSafe(event.params.chatId),
            messageId: toStringSafe(event.params.messageId),
            senderId,
            senderName,
            receiverId,
            title: senderName,
            body: messageText,
        };

        const pushMessage = {
            tokens,
            data: dataPayload,
            notification: {
                title: senderName,
                body: messageText,
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'chat_messages',
                    sound: 'default',
                    priority: 'high',
                    visibility: 'private',
                },
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
                payload: {
                    aps: {
                        sound: 'default',
                        contentAvailable: true,
                    },
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast(pushMessage);
        await cleanupInvalidTokens(receiverId, tokens, response);

        logger.info(
            `Message notification sent: success=${response.successCount}, failure=${response.failureCount}`
        );

        return null;
    }
);
