/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.sarah.vpn

import android.app.Activity
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

    external fun onSkuDetailsReceived(subscriptionsDataJSONBlob: String);

    companion object {

        private const val TAG = "InAppPurchase"

        @JvmStatic
        fun lookupProductsInPlayStore(c: Context, productsToLookup: String) {
            Log.v(TAG, "startBillingClient for purchaseLookUp: $productsToLookup")
            val mozillaProducts = Json.decodeFromString<MozillaSubscriptions>(productsToLookup)
            var googleProducts = GooglePlaySubscriptions(products=arrayListOf<GooglePlaySubscriptionInfo>())

            val purchasesUpdatedListener =
                PurchasesUpdatedListener { billingResult: BillingResult, purchases ->
                    Log.i(TAG, "I'm in the purchasesUpdatedListener that's used for looking up products. Nothing should happen here.")
                    Log.v(TAG, purchases.toString())
                }

            Log.i(TAG, "A")

            // This billingClient only listens for the skudetails
            val billingClient = BillingClient.newBuilder(c)
                .setListener(purchasesUpdatedListener)
                .enablePendingPurchases()
                .build()

            Log.i(TAG, "B")

            billingClient.startConnection(object : BillingClientStateListener, SkuDetailsResponseListener {
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode ==  BillingClient.BillingResponseCode.OK) {
                        val productList = ArrayList<String>()
                        for (product in mozillaProducts.products) {
                            Log.i(TAG, "C")
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
                override fun onSkuDetailsResponse(billingResult: BillingResult, skuDetailsList: MutableList<SkuDetails>?) {
                    val responseCode = billingResult.responseCode
                    val debugMessage = billingResult.debugMessage
                    when (responseCode) {
                        BillingClient.BillingResponseCode.OK -> {
                            Log.i(TAG, "onSkuDetailsResponse: $responseCode $debugMessage")
                            if (skuDetailsList == null) {
                                Log.e(TAG,"Found null SkuDetails.")
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
                                val subscriptionsDataJSONBlob = Json.encodeToString(googleProducts)
                                Log.d(TAG, subscriptionsDataJSONBlob)
                                InAppPurchase().onSkuDetailsReceived(subscriptionsDataJSONBlob)
                                billingClient.endConnection();
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
                override fun onBillingServiceDisconnected() {
                    Log.i(TAG, "SkuDetails Billing Service Disconnected")
                }
            })
        }

        @JvmStatic
        fun purchaseProduct(c: Context, productData: String, a: Activity) {
            Log.v(TAG, "purchaseProduct: $productData")
            val mozillaProducts = Json.decodeFromString<MozillaSubscriptions>(productData)
            var googleProducts = GooglePlaySubscriptions(products=arrayListOf<GooglePlaySubscriptionInfo>())

            val purchasesUpdatedListener =
                PurchasesUpdatedListener { billingResult: BillingResult, purchases ->
                    Log.i(TAG, "I'm in the purchasesUpdatedListener")
                    Log.v(TAG, purchases.toString())
                }

            val billingClient = BillingClient.newBuilder(c)
                .setListener(purchasesUpdatedListener)
                .enablePendingPurchases()
                .build()

            billingClient.startConnection(object : BillingClientStateListener, SkuDetailsResponseListener {
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode ==  BillingClient.BillingResponseCode.OK) {
                        require(mozillaProducts.products.size == 1)
                        val params = SkuDetailsParams.newBuilder()
                            .setType(BillingClient.SkuType.SUBS)
                            .setSkusList(listOf(mozillaProducts.products[0].id))
                            .build()
                        params.let { skuDetailsParams ->
                            billingClient.querySkuDetailsAsync(skuDetailsParams, this)
                        }

                    }
                }
                override fun onSkuDetailsResponse(billingResult: BillingResult, skuDetailsList: MutableList<SkuDetails>?) {
                    val responseCode = billingResult.responseCode
                    val debugMessage = billingResult.debugMessage
                    when (responseCode) {
                        BillingClient.BillingResponseCode.OK -> {
                            Log.i(TAG, "onSkuDetailsResponse: $responseCode $debugMessage")
                            if (skuDetailsList == null) {
                                Log.e(TAG,"Found null SkuDetails.")
                            } else {
                                require(skuDetailsList.size == 1)
                                val skuDetails = skuDetailsList[0]
                                val billingParams = BillingFlowParams.newBuilder()
                                    .setSkuDetails(skuDetails)
                                    .build()
                                val billingResult = billingClient.launchBillingFlow(a, billingParams);
                                val responseCode = billingResult.responseCode
                                val debugMessage = billingResult.debugMessage
                                Log.d(TAG, "launchBillingFlow: BillingResponse $responseCode $debugMessage")
                            }
                        }
                        BillingClient.BillingResponseCode.SERVICE_DISCONNECTED,
                        BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE,
                        BillingClient.BillingResponseCode.BILLING_UNAVAILABLE,
                        BillingClient.BillingResponseCode.ITEM_UNAVAILABLE,
                        BillingClient.BillingResponseCode.DEVELOPER_ERROR,
                        BillingClient.BillingResponseCode.ERROR -> {
                            Log.e(TAG, "purchaseProduct onSkuDetailsResponse: $responseCode $debugMessage")
                        }
                        BillingClient.BillingResponseCode.USER_CANCELED,
                        BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED,
                        BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED,
                        BillingClient.BillingResponseCode.ITEM_NOT_OWNED -> {
                            // These response codes are not expected.
                            Log.wtf(TAG, "purchaseProduct onSkuDetailsResponse: $responseCode $debugMessage")
                        }
                    }
                }
                override fun onBillingServiceDisconnected() {
                    Log.i(TAG, "purchaseProduct Billing Service Disconnected")
                }
            })
        }
    }
}
