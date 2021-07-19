/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.firefox.vpn

import android.content.Context
import com.android.billingclient.api.*
import com.android.billingclient.api.BillingClient.SkuType


class InAppPurchase () {

    companion object {
        @JvmStatic
        fun startBillingClient(c: Context, p: String) {

            val purchasesUpdatedListener =
                PurchasesUpdatedListener { billingResult, purchases ->
                    // To be implemented in a later section.
                }

            val skuDetailsResponseListener =
                SkuDetailsResponseListener {billingResult, skuDetails ->
                    // Can I log?
                }
            val billingClient = BillingClient.newBuilder(c)
                .setListener(purchasesUpdatedListener)
                .enablePendingPurchases()
                .build()

            billingClient.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode ==  BillingClient.BillingResponseCode.OK) {
                        val productList = ArrayList<String>()
                        productList.add(p)
                        val params = SkuDetailsParams.newBuilder()
                        params.setSkusList(productList).setType(SkuType.SUBS)

                        val productDetailsResult = billingClient.querySkuDetailsAsync(params.build(), skuDetailsResponseListener)
                        Log.v("ummm", productDetailsResult.toString())
                        // Process the result.
                    }
                }
                override fun onBillingServiceDisconnected() {
                    // Try to restart the connection on the next request to
                    // Google Play by calling the startConnection() method.
                }
            })
        }
    }
}
