/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.sarah.vpn

import android.util.Log
import android.content.Context

class InAppPurchase () {

    companion object {

        private const val TAG = "InAppPurchase"

        @JvmStatic
        fun startBillingClient(c: Context, p: String) {
            Log.v(TAG, "startBillingClient manual")
        }


    }
}
