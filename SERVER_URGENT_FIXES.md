# 🚨 SERVER SIDE URGENT FIXES REQUIRED

## 1. 📝 **FCM Notification Timestamp Issue**

### **Problem:** 
Notifikasi terlambat masih masuk setelah 1-2 menit karena server **tidak mengirim timestamp** dalam FCM data.

### **Solution - Add to Node.js Server:**

```javascript
// Update your FCM notification sending function
async function sendNotificationWithTimestamp(fcmToken, title, body, data = {}) {
  const notificationData = {
    ...data,
    sent_at: new Date().toISOString(), // ✅ CRITICAL: Add this line
    created_at: new Date().toISOString(), // ✅ Alternative key
    timestamp: Date.now().toString(), // ✅ Unix timestamp as fallback
    timezone: 'Asia/Jakarta',
    utc_offset: '+07:00'
  };

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body
    },
    data: notificationData, // ✅ Include timestamp in data
    android: {
      ttl: 120000, // ✅ Reduce TTL to 2 minutes to match client filtering
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-expiration': Math.floor(Date.now() / 1000) + 120, // 2 minutes
        'apns-priority': '10'
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent with timestamp:', {
      response,
      sentAt: notificationData.sent_at,
      ttl: '2 minutes'
    });
    return response;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    throw error;
  }
}

// Example usage for new report
async function sendNewReportNotification(fcmToken, reportId, reportTitle) {
  await sendNotificationWithTimestamp(
    fcmToken,
    'Laporan Baru',
    `Laporan "${reportTitle}" telah dibuat`,
    {
      type: 'new_report',
      reportId: reportId.toString(),
      action: 'view_report'
    }
  );
}
```

### **Test this immediately:**
1. Send FCM notification from server
2. Check Flutter logs for: `FCM message data keys: [sent_at, created_at, timestamp, ...]`
3. Force stop app, wait 3 minutes, restart → old notifications should be blocked

---

## 2. 📝 **Report Endpoint Parameter Issue**

### **Problem:**
Tidak bisa kirim laporan karena API endpoint tidak sesuai dengan client calls.

### **Solution - Update Node.js Route:**

```javascript
// Make sure your /report endpoint accepts these parameters:
app.post('/report', authenticateToken, async (req, res) => {
  try {
    const {
      jenis_laporan,
      address,
      phone,
      use_account_data,
      is_officer_report,
      rw,
      reporter_name,
      created_at,    // ✅ From timezone helper
      timestamp,     // ✅ From timezone helper
      timezone,      // ✅ From timezone helper
      utc_offset     // ✅ From timezone helper
    } = req.body;

    console.log('📝 Report request:', {
      jenis_laporan,
      use_account_data,
      is_officer_report,
      has_address: !!address,
      has_phone: !!phone,
      created_at,
      timezone
    });

    // Validation
    if (!jenis_laporan) {
      return res.status(400).json({
        error: 'jenis_laporan is required'
      });
    }

    // If not using account data, address and phone are required
    if (!use_account_data) {
      if (!address) {
        return res.status(400).json({
          error: 'address is required when not using account data'
        });
      }
      if (!phone) {
        return res.status(400).json({
          error: 'phone is required when not using account data'
        });
      }
    }

    // Create report record
    const reportData = {
      user_id: req.user.id,
      jenis_laporan,
      created_at: created_at || new Date().toISOString(),
      timezone: timezone || 'Asia/Jakarta',
      is_officer_report: is_officer_report || false,
    };

    // Add address/phone based on use_account_data flag
    if (use_account_data) {
      // Use data from user account
      reportData.address = req.user.address;
      reportData.phone = req.user.phone;
      reportData.reporter_name = req.user.name;
    } else {
      // Use provided custom data
      reportData.address = address;
      reportData.phone = phone;
      reportData.reporter_name = reporter_name || req.user.name;
      if (rw) {
        reportData.rw = rw;
      }
    }

    // Insert to database
    const result = await db.query(
      'INSERT INTO reports (user_id, jenis_laporan, address, phone, reporter_name, created_at, timezone, is_officer_report, rw) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        reportData.user_id,
        reportData.jenis_laporan,
        reportData.address,
        reportData.phone,
        reportData.reporter_name,
        reportData.created_at,
        reportData.timezone,
        reportData.is_officer_report,
        reportData.rw
      ]
    );

    const reportId = result.insertId;

    console.log('✅ Report created:', {
      id: reportId,
      jenis_laporan,
      use_account_data,
      created_at: reportData.created_at
    });

    // Send FCM notification with timestamp
    try {
      await sendNewReportNotification(
        req.user.fcm_token,
        reportId,
        jenis_laporan
      );
    } catch (fcmError) {
      console.error('FCM notification failed:', fcmError);
      // Don't fail the request if notification fails
    }

    res.json({
      success: true,
      report: {
        id: reportId,
        ...reportData
      }
    });

  } catch (error) {
    console.error('❌ Error creating report:', error);
    res.status(500).json({
      error: 'Failed to create report',
      details: error.message
    });
  }
});
```

---

## 3. 🧪 **Testing Steps**

### **Test Report Creation:**
1. Login as admin
2. Go to report form
3. Fill form and submit
4. Check server logs for proper parameter handling
5. Verify report appears in database with UTC+7 timestamp

### **Test Delayed Notification Blocking:**
1. Send FCM notification from server
2. Force stop app immediately
3. Wait 3+ minutes
4. Restart app and send new notification
5. ✅ Should only see new notification
6. ❌ Should NOT see old notification

### **Check Server Logs:**
```bash
# Look for these patterns:
✅ Notification sent with timestamp: {...}
📝 Report request: {...}
✅ Report created: {...}
```

---

## 4. 🚀 **Client Side Changes Made**

✅ **API Service:** Updated to handle `useAccountData` parameter properly
✅ **FCM Service:** Enhanced timestamp checking with multiple fallbacks
✅ **Timezone Helper:** UTC+7 timestamp generation for reports
✅ **Debugging:** Enhanced logging for troubleshooting

---

## 5. ⚡ **URGENT: Deploy These Changes**

1. **Update FCM notification function** with timestamps
2. **Update /report endpoint** parameter handling
3. **Reduce FCM TTL** to 2 minutes
4. **Test immediately** with force stop scenario

**Priority: HIGH** - These issues affect core functionality!
