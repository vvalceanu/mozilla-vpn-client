/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.sarah.vpn

import android.util.Log
import android.content.Context

import com.android.billingclient.api.*
import kotlinx.serialization.*
import kotlinx.serialization.json.*

@Serializable
data class MozillaSubscriptionInfo(
    val featured_product: Boolean,
    val type: String,
    val id: String
)

@Serializable
data class MozillaSubscriptions(
    val products: List<MozillaSubscriptionInfo>
)

@Serializable
data class GooglePlaySubscriptionInfo(
    val sku: String, // matches MozillaSubscriptionInfo.id
    val description: String,
    val price: String,
    val priceCurrencyCode: String,
)

@Serializable
data class GooglePlaySubscriptions(
    val products: ArrayList<GooglePlaySubscriptionInfo>
)

class InAppPurchase () {

    companion object {

        private const val TAG = "InAppPurchase"

        @JvmStatic
        fun startBillingClient(c: Context, p: String) {
            Log.v(TAG, "startBillingClient manual with string: $p")
            val mozillaProducts = Json.decodeFromString<MozillaSubscriptions>(p)
            var googleProducts = GooglePlaySubscriptions(products=arrayListOf<GooglePlaySubscriptionInfo>())

            val purchasesUpdatedListener =
                PurchasesUpdatedListener { billingResult: BillingResult, purchases ->
                    // To be implemented in a later section.
                }

            val billingClient = BillingClient.newBuilder(c)
                .setListener(purchasesUpdatedListener)
                .enablePendingPurchases()
                .build()

            billingClient.startConnection(object : BillingClientStateListener, SkuDetailsResponseListener {

                override fun onSkuDetailsResponse(billingResult: BillingResult, skuDetailsList: MutableList<SkuDetails>?) {
                    val responseCode = billingResult.responseCode
                    val debugMessage = billingResult.debugMessage
                    when (responseCode) {
                        BillingClient.BillingResponseCode.OK -> {
                            Log.i(TAG, "onSkuDetailsResponse: $responseCode $debugMessage")
                            val expectedSkuDetailsCount = 1
                            if (skuDetailsList == null) {
                                Log.e(TAG, "onSkuDetailsResponse: " +
                                        "Expected ${expectedSkuDetailsCount}, " +
                                        "Found null SkuDetails. " +
                                        "Check to see if the SKUs you requested are correctly published " +
                                        "in the Google Play Console.")
                            } else {
                                for (details in skuDetailsList) {
                                    googleProducts.products.add(
                                        GooglePlaySubscriptionInfo(
                                            description = details.description,
                                            price = details.price,
                                            priceCurrencyCode = details.priceCurrencyCode,
                                            sku = details.sku
                                        )
                                    )
                                }
                                Log.v(TAG, Json.encodeToString(googleProducts))
                            }
                        }
                        BillingClient.BillingResponseCode.SERVICE_DISCONNECTED,
                        BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE,
                        BillingClient.BillingResponseCode.BILLING_UNAVAILABLE,
                        BillingClient.BillingResponseCode.ITEM_UNAVAILABLE,
                        BillingClient.BillingResponseCode.DEVELOPER_ERROR,
                        BillingClient.BillingResponseCode.ERROR -> {
                            Log.e(TAG, "onSkuDetailsResponse: $responseCode $debugMessage")
                        }
                        BillingClient.BillingResponseCode.USER_CANCELED,
                        BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED,
                        BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED,
                        BillingClient.BillingResponseCode.ITEM_NOT_OWNED -> {
                            // These response codes are not expected.
                            Log.wtf(TAG, "onSkuDetailsResponse: $responseCode $debugMessage")
                        }
                    }
                }

                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode ==  BillingClient.BillingResponseCode.OK) {
                        val productList = ArrayList<String>()
                        for (product in mozillaProducts.products) {
                            productList.add(product.id)
                        }
                        val params = SkuDetailsParams.newBuilder()
                            .setType(BillingClient.SkuType.SUBS)
                            .setSkusList(productList)
                            .build()
                        Log.v(TAG, "The params list is: ${params.skuType} ${params.skusList.toString()}")
                        params.let { skuDetailsParams ->
                            Log.i(TAG, "querySkuDetailsAsync")
                            billingClient.querySkuDetailsAsync(skuDetailsParams, this)
                        }

                    }
                }

                override fun onBillingServiceDisconnected() {
                    // Try to restart the connection on the next request to
                    // Google Play by calling the startConnection() method.
                    Log.v(TAG, "BILLING SERVICE DISCONNECTED")
                }
            })

        }


    }
}
