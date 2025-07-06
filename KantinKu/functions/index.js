// BAGIAN 1: Firebase Cloud Functions untuk Callback Tripay
// File: functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

// Inisialisasi Firebase Admin
admin.initializeApp();

// Private key dari Tripay (harus sama dengan di aplikasi mobile)
const TRIPAY_PRIVATE_KEY = 'Eaykr-yV5PA-2ZxD2-pHKq6-3Z6lV';

// Fungsi untuk memverifikasi signature dari Tripay
function verifyTripaySignature(data, signature) {
  const hmac = crypto.createHmac('sha256', TRIPAY_PRIVATE_KEY);
  const expectedSignature = hmac.update(JSON.stringify(data)).digest('hex');
  return expectedSignature === signature;
}

// Cloud Function untuk menerima callback dari Tripay
exports.tripayCallback = functions.https.onRequest(async (request, response) => {
  try {
    // Tripay mengirim data dalam body
    const { data, signature } = request.body;
    
    // Log untuk debugging
    console.log('Menerima callback dari Tripay:', JSON.stringify(request.body));
    
    // Verifikasi signature untuk keamanan
    if (!verifyTripaySignature(data, signature)) {
      console.error('Signature tidak valid');
      return response.status(400).send('Invalid signature');
    }
    
    // Data dari callback Tripay
    const {
      reference,      // ID referensi dari Tripay
      merchant_ref,   // ID referensi dari merchant (aplikasi Anda)
      status,         // Status pembayaran: UNPAID, PAID, EXPIRED, FAILED
      paid_at,        // Waktu pembayaran (jika status PAID)
      amount,         // Jumlah yang dibayarkan
      payment_method  // Metode pembayaran yang digunakan
    } = data;
    
    // Update status pembayaran di Firestore
    const orderRef = admin.firestore().collection('orders').doc(merchant_ref);
    
    // Ambil data order
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      console.error(`Order dengan ref ${merchant_ref} tidak ditemukan`);
      return response.status(404).send('Order not found');
    }
    
    // Update status pembayaran
    await orderRef.update({
      payment_status: status,
      tripay_reference: reference,
      paid_at: status === 'PAID' ? admin.firestore.Timestamp.fromDate(new Date(paid_at)) : null,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Jika status PAID, proses order (update stok, kirim notifikasi, dll)
    if (status === 'PAID') {
      const orderData = orderDoc.data();
      
      // Update stok produk
      const orderItems = orderData.items || [];
      
      // Proses setiap item dalam order
      const batch = admin.firestore().batch();
      
      for (const item of orderItems) {
        const productRef = admin.firestore().collection('products').doc(item.product_id);
        
        // Gunakan transaction untuk update stok dengan aman
        await admin.firestore().runTransaction(async (transaction) => {
          const productDoc = await transaction.get(productRef);
          if (!productDoc.exists) {
            console.error(`Produk ${item.product_id} tidak ditemukan`);
            return;
          }
          
          const productData = productDoc.data();
          const newStock = Math.max(0, (productData.stock || 0) - item.quantity);
          
          transaction.update(productRef, { stock: newStock });
        });
      }
      
      // Kirim notifikasi ke pemilik toko (opsional)
      const storeOwnerUid = orderData.store_owner_uid;
      if (storeOwnerUid) {
        await admin.firestore().collection('notifications').add({
          user_id: storeOwnerUid,
          title: 'Pembayaran Diterima',
          body: `Order #${merchant_ref} telah dibayar sebesar Rp${amount.toLocaleString('id-ID')}`,
          is_read: false,
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      
      // Kirim notifikasi ke pembeli (opsional)
      const buyerUid = orderData.user_id;
      if (buyerUid) {
        await admin.firestore().collection('notifications').add({
          user_id: buyerUid,
          title: 'Pembayaran Berhasil',
          body: `Pembayaran order #${merchant_ref} telah diterima. Terima kasih!`,
          is_read: false,
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
    
    // Berikan respons ke Tripay
    return response.status(200).send('Payment callback processed successfully');
  } catch (error) {
    console.error('Error processing Tripay callback:', error);
    return response.status(500).send('Internal server error');
  }
});

// Cloud Function untuk mendapatkan status pembayaran (dipanggil oleh aplikasi mobile)
exports.getPaymentStatus = functions.https.onCall(async (data, context) => {
  try {
    // Pastikan user terautentikasi
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User harus login untuk mengakses fungsi ini'
      );
    }
    
    const { merchantRef } = data;
    if (!merchantRef) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'merchantRef tidak boleh kosong'
      );
    }
    
    // Ambil data order dari Firestore
    const orderDoc = await admin.firestore().collection('orders')
      .doc(merchantRef)
      .get();
    
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Order tidak ditemukan'
      );
    }
    
    const orderData = orderDoc.data();
    
    // Pastikan user yang request adalah pemilik order
    if (orderData.user_id !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User tidak memiliki akses ke order ini'
      );
    }
    
    // Kembalikan status pembayaran
    return {
      success: true,
      data: {
        merchant_ref: merchantRef,
        payment_status: orderData.payment_status || 'UNPAID',
        paid_at: orderData.paid_at ? orderData.paid_at.toDate() : null,
        reference: orderData.tripay_reference || ''
      }
    };
  } catch (error) {
    console.error('Error getting payment status:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Terjadi kesalahan saat mengecek status pembayaran'
    );
  }
});
