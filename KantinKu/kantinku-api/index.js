const express = require('express');
const midtransClient = require('midtrans-client');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// Konfigurasi Midtrans
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-XXXXXXXXXXXXXXXXXXXXXXXX' // Ganti dengan server key dari dashboard Midtrans
});

// Endpoint untuk ambil Snap Token
app.post('/get-snap-token', async (req, res) => {
  try {
    const { amount, name } = req.body;

    const parameter = {
      transaction_details: {
        order_id: 'order-id-' + Math.floor(Math.random() * 1000000),
        gross_amount: amount
      },
      item_details: [
        {
          id: 'item01',
          price: amount,
          quantity: 1,
          name: name
        }
      ],
      customer_details: {
        first_name: "Budi",
        last_name: "Santoso",
        email: "budi@example.com",
        phone: "081234567890"
      }
    };

    const snapToken = await snap.createTransaction(parameter);
    res.json({ snap_token: snapToken.token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to generate snap token' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
