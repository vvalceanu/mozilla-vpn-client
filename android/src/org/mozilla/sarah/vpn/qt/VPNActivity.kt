/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.mozilla.sarah.vpn.qt

import android.util.Log
import android.view.KeyEvent
import org.qtproject.qt5.android.bindings.QtActivity
import android.os.Bundle
import androidx.lifecycle.MutableLiveData
import com.android.billingclient.api.*

class VPNActivity : QtActivity() {

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && event.repeatCount == 0) {
            onBackPressed()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onBackPressed() {
        try {
            if (!handleBackButton()) {
                // Move the activity into paused state if back button was pressed
                moveTaskToBack(true)
            }
        } catch (e: Exception) {
        }
    }

    // Returns true if MVPN has handled the back button
    external fun handleBackButton(): Boolean
}