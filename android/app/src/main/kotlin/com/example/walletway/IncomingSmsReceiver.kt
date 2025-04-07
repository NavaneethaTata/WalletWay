package com.example.walletway

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import android.util.Log

class IncomingSmsReceiver : BroadcastReceiver() {
    private val TAG = "IncomingSmsReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        val bundle: Bundle? = intent.extras
        try {
            if (bundle != null) {
                val pdus = bundle.get("pdus") as Array<*>?
                if (pdus != null) {
                    for (pdu in pdus) {
                        val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray)
                        val sender = smsMessage.displayOriginatingAddress
                        val messageBody = smsMessage.displayMessageBody
                        Log.d(TAG, "SMS received from: $sender - Message: $messageBody")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception in onReceive: $e")
        }
    }
}
