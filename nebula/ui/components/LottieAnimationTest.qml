/*
 * Copyright 2018 Kai Uwe Broulik <kde@broulik.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9

import "qrc:/nebula/resources/lottie/lottie_shim.js" as Lottie

/**
 * LottieAnimation
 */
Item {
    id: lottieItem

    /**
     * Animation to display, can be
     * \li URL: absolute URL to an animation JSON file, including qrc:/
     * \li filename: relative path to an animation JSON file
     * \li JSON data (must be an Object at root level)
     * \li a JavaScript Object
     */
    property var source

    /**
     * Load the image asynchronously, default is false.
     *
     * @note the animation is always created/processed synchronously,
     * this is only about loading the file itself, e.g. downloading it from a remote location
     */
    // TODO
    //property bool asynchronous: false

    /**
     * Load status of the animation file
     * \li Image.Null: no source set
     * \li Image.Ready: animation file was successfully loaded and processed
     * \li Image.Loading: animation file is currently being downloaded
     * \li Image.Error: animation file failed to load or process,
                        \c errorString will contain more details
     */
    property int status: Image.Null

    /**
     * Error string explaining why the animation file failed to load
     * Only set when \c status is \c Image.Error
     */
    property string errorString

    /**
     * Whether the animation is and should be running
     * Setting this to true or false is the same as calling start() or pause(), respectively.
     */
    property bool running: false

    /**
     * How often to repeat the animation, default is 0, i.e. it runs only once.
     *
     * Set to Animation.Infinite to repeat the animation indefinitely
     *
     * @note Changing this property causes the animation to be recreated
     */
    property int loops: 0

    /**
     * Speed modifier at which the animation is played, default is 1x speed.
     */
    property real speed: 1

    /**
     * Play the animation in reverse (from end to start)
     */
    property bool reverse: false

    /**
     * Whether to clear the canvas before rendering, default is true.
     *
     * Disable if you are painting a full screen scene anyway.
     * @note Changing this property causes the animation to be recreated
     * @note Disabling this can cause unwanted side-effects in the QtQuick
     * canvas when it tries to re-render only specific areas.
     */
    property bool clearBeforeRendering: true

    /**
     * How to behave when the image item has a sice different from the animation's native size,
     * \li Image.Stretch (default): the animation is scaled to fit
     * \li Image.PreserveAspectFit: the image is scaled uniformly to fit without cropping
     * \li Image.PreserveAspectCrop: the image is scaled uniformly to fill, cropping if necessary
     * \li Image.Pad: the image is not transformed
     *
     * @note implicitWidth and implicitHeight of this item are set to the animation's native size
     * so by default this item will have the correct size
     * @note Changing this property causes the animation to be recreated
     */
    property int fillMode: Image.Stretch

    /**
     * When the animation finishes, call stop(), default is false.
     *
     * This will revert the animation to its first frame when finished
     */
    //property bool stopWhenComplete: false

    property alias renderStrategy: canvas.renderStrategy

    property alias renderTarget: canvas.renderTarget

    /**
     * Emitted when the last loop of the animation finishes.
     * @note This does not work right now
     */
    signal finished()

    /**
     * Emitted when a loop of the animation finishes.
     * @param currentLoop The number of the loop that just finished.
     * @note This does not work right now
     */
    signal loopFinished(int currentLoop)

    /**
     * Start the animation.
     *
     * This is the same as setting running to true.
     */
    // Start the animation, restarts if already running
    function start() {
        if (d.animationItem) {
            d.animationItem.play();
            running = true;
        }
    }

    /**
     * Pause the animation.
     *
     * This is the same as setting running to false.
     */
    function pause() {
        if (d.animationItem) {
            d.animationItem.pause();
            running = false;
        }
    }

    /**
     * Stop the animation.
     *
     * Stops playback and rewinds the animation to the beginning.
     */
    function stop() {
        if (d.animationItem) {
            d.animationItem.stop();
            running = false;
        }
    }

    /**
     * Clear the animation canvas
     */
    function clear() {
        if (!canvas.available) {
            return;
        }

        var ctx = canvas.getContext("2d");
        if (ctx) {
            ctx.reset();
        }
        canvas.requestPaint();
    }

    // Private API
    QtObject {
        id: d

        property bool componentComplete: false

        // The actual animation data used
        property var animationData

        // The "AnimationItem" created by lottie.js that does the animation and everything
        property var animationItem

        // When recreating the animation when changing properties, jump to this frame
        // to provide a seamless experience
        property real pendingRawFrame: -1

        readonly property LoggingCategory log: LoggingCategory {
            name: "org.kde.lottie"
            // TODO needs bump to Qt 5.12, is it worth it?
            //defaultLogLevel: LoggingCategory.Info
        }

        onAnimationDataChanged: {
            destroyAnimation();

            // Avoid repeated access to this property containing lots of data
            var data = animationData;

            if (!data) {
                errorString = "";
                status = Image.Null;
                return;
            }

            if (typeof data !== "object") {
                errorString = "animationData is not an object, this should not happen";
                status = Image.Error;
                return;
            }

            var width = data.w || 0;
            var height = data.h || 0;

            if (width <= 0 || height <= 0) {
                errorString = "Animation data does not contain valid size information";
                status = Image.Error;
                return;
            }

            lottieItem.implicitWidth = width;
            lottieItem.implicitHeight = height;

            playIfShould();
        }

        // TODO clean that up a bit
        readonly property bool shouldPlay: canvas.available && componentComplete
                                           && lottieItem.width > 0 && lottieItem.height > 0

        onShouldPlayChanged: {
            if (!shouldPlay) {
                // TODO stop
                return;
            }

            playIfShould();
        }

        function setAnimationDataJson(json) {
            animationData = undefined;
            try {
                animationData = JSON.parse(json);
            } catch (e) {
                errorString = e.toString();
                status = Image.Error;
            }
        }

        function playIfShould() { // TODO better name
            if (!shouldPlay) {
                return;
            }

            var data = animationData;
            if (!data) {
                return;
            }

            console.log(d.log, "Initializing Lottie Animation");
            var lottie = Lottie.initialize(canvas, d.log);

            var aspectRatio = "none";

            switch (lottieItem.fillMode) {
            case Image.Pad:
                aspectRatio = "orig"; // something other than empty string
                break;
            case Image.PreserveAspectCrop:
                // TODO make position also configurable like Image has it
                aspectRatio = "xMidYMid slice";
                break;
            case Image.PreserveAspectFit:
                aspectRatio = "xMidYMid meet";
                break;
            }

            var loop = false;
            if (lottieItem.loops === Animation.Infinite) {
                loop = true;
            } else if (lottieItem.loops > 0) {
                loop = lottieItem.loops;
            }

            animationItem = lottie.loadAnimation({
                container: container,
                renderer: "canvas",
                rendererSettings: {
                    clearCanvas: lottieItem.clearBeforeRendering,
                    preserveAspectRatio: aspectRatio
                },
                loop: loop,
                autoplay: lottieItem.running,
                animationData: data
            });

            animationItem.setSpeed(lottieItem.speed);
            animationItem.setDirection(lottieItem.reverse ? -1 : 1);

            // TODO should we expose enterFrame event?
            animationItem.addEventListener("complete", function(e) {
                running = false;
                // FIXME throws "lottieAnim is not defined" at times
                //lottieAnim.finished();

                // Cannot do "Play" again when complete
                // Figure out a better way than this, or call stop/rewind automatically when complete
            });

            animationItem.addEventListener("loopComplete", function(e) {
                // FIXME throws "lottieAnim is not defined" at times
                //lottieAnim.loopFinished(e.currentLoop);
            });

            if (pendingRawFrame >= 0) {
                animationItem.setCurrentRawFrameValue(pendingRawFrame);
            }
            pendingRawFrame = -1;

            status = Image.Ready;
            errorString = "";
        }

        function destroyAndRecreate() {
            console.log(d.log, "destroy and recreate");
            if (animationItem) {
                d.pendingRawFrame = animationItem.currentRawFrame;
            }

            destroyAnimation();
            playIfShould();
        }

        function destroyAnimation() {
            if (animationItem) {
                animationItem.destroy();
                animationItem = null;
            }
            lottieItem.clear();
        }

        function updateAnimationSize() {
            if (animationItem) {
                lottieItem.clear();
                animationItem.resize();
            }
        }

        Component.onCompleted: {
            componentComplete = true;
        }
    }

    // Should we move these handlers into a Connections {} within the private?
    onRunningChanged: {
        if (running) {
            start();
        } else {
            pause();
        }
    }

    onWidthChanged: Qt.callLater(d.updateAnimationSize)
    onHeightChanged: Qt.callLater(d.updateAnimationSize)

    // TODO Would be lovely if we could change those at runtime without recreating the animation
    onLoopsChanged: Qt.callLater(d.destroyAndRecreate)
    onClearBeforeRenderingChanged: Qt.callLater(d.destroyAndRecreate)
    onFillModeChanged: Qt.callLater(d.destroyAndRecreate)

    onSpeedChanged: {
        if (d.animationItem) {
            d.animationItem.setSpeed(speed);
        }
    }
    onReverseChanged: {
        if (d.animationItem) {
            d.animationItem.setDirection(reverse ? -1 : 1);
        }
    }

    onSourceChanged: {
        // is already JS object, use verbatim
        // if (typeof source === "object") { // TODO what about QUrl, I think it is treated as {} here
        //     console.log(d.log, "Using source verbatim as it is an object");
        //     d.animationData = source;
        //     return;
        // }

        // var sourceString = source.toString();

        // if (sourceString.indexOf("{") === 0) { // startsWith("{"), assume JSON
        //     console.log(d.log, "Using source as JSON");
        //     d.setAnimationDataJson(sourceString);
        //     return;
        // }

        // d.animationData = null;
        // if (!source) {
        //     return;
        // }

        // var url = source.toString(); // toString in case is QUrl
        // if (url.indexOf("/") === 0) { // assume local file
        //     url = "file://" + url;
        // } else if (url.indexOf(":/") === -1) { // assume relative url
        //     // FIXME figure out how to do relative URLs with Ajax
        //     // Qt.resolvedUrl is relative to *this* file, not the one where the item is actually used from
        // }

        // // NOTE QML LoggingCategory {} has its internal QLoggingCategory created in
        // // componentCompleted(). There seems to be a situation where this console.log
        // // is executed before the LoggingCategory {} object above has completed.
        // //console.log(d.log, "Fetching source from", url);

        // var xhr = new XMLHttpRequest()
        // // FIXME allow asynchronous
        // xhr.open("GET", url, false /*synchronous*/);
        // xhr.send(null /*payload*/);

        // // NOTE KIO AccessManager in contrast to QNetworkAccessManager doesn't set a HTTP status code
        // // when loading local files via Ajax so we can't check xhr.status === 200 here

        // var text = xhr.responseText;
        // if (text.length < 10) {
        //     errorString = xhr.statusText || xhr.status || "Failed to load " + url;
        //     status = Image.Error;
        //     return;
        // }

        var text = '{"v":"5.7.4","fr":30,"ip":0,"op":150,"w":1240,"h":708,"nm":"Clock","ddd":0,"assets":[{"id":"comp_0","layers":[{"ddd":0,"ind":1,"ty":3,"nm":"▽ Layer 2","sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[461.158,232.654,0],"ix":2,"l":2},"a":{"a":0,"k":[461.173,230.331,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":2,"ty":3,"nm":"▽ Layer 1","parent":1,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[461.173,230.331,0],"ix":2,"l":2},"a":{"a":0,"k":[461.173,230.331,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":3,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":1,"k":[{"i":{"x":[0.32],"y":[1.27]},"o":{"x":[0.17],"y":[0.89]},"t":30,"s":[0]},{"i":{"x":[0.32],"y":[1.396]},"o":{"x":[0.17],"y":[1.305]},"t":60,"s":[480]},{"t":82,"s":[360]}],"ix":10},"p":{"a":0,"k":[512.813,263.584,0],"ix":2,"l":2},"a":{"a":0,"k":[-48,-31.5,0],"ix":1,"l":2},"s":{"a":0,"k":[-100,-100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-3.721,2.742],[-64.107,30.036],[0,0],[11.16,-8.862],[0,0],[4.441,-1.318],[4.608,0.497],[4.052,2.234],[2.858,3.62],[1.216,4.437],[-0.618,4.557],[-2.354,3.961]],"o":[[11.16,-8.862],[0,0],[-43.417,55.471],[0,0],[-3.576,2.926],[-4.441,1.318],[-4.608,-0.497],[-4.052,-2.234],[-2.858,-3.62],[-1.216,-4.437],[0.618,-4.557],[2.354,-3.961]],"v":[[-68.055,6.509],[82.072,-68.613],[81.947,-68.582],[-24.637,60.27],[-25.233,60.736],[-37.38,67.167],[-51.091,68.412],[-64.212,64.274],[-74.683,55.405],[-80.856,43.198],[-81.762,29.571],[-77.259,16.665]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[0.435294121504,0.290196090937,0.905882358551,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":67.826,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":4,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[495.869,154.807,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[-20.079,28.066],[-32.538,10.821],[-32.629,-10.537],[-20.317,-27.89],[0,0],[25.91,7.912],[25.62,-8.823],[15.752,-22.259],[-0.006,-27.373]],"o":[[-0.013,-34.642],[20.079,-28.066],[32.538,-10.821],[32.629,10.537],[0,0],[-16.512,-21.688],[-25.91,-7.912],[-25.62,8.823],[-15.752,22.259],[0,0]],"v":[[-146.76,77.19],[-115.891,-19.279],[-34.945,-79.102],[65.308,-79.539],[146.76,-20.424],[85.666,7.331],[20.434,-38.186],[-58.804,-36.784],[-122.423,11.012],[-146.636,87.332]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"fl","c":{"a":0,"k":[0.678431391716,0.474509805441,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":5,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[495.869,154.807,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[-20.079,28.066],[-32.538,10.821],[-32.629,-10.537],[-20.317,-27.89],[0,0],[25.91,7.912],[25.62,-8.823],[15.752,-22.259],[-0.006,-27.373]],"o":[[-0.013,-34.642],[20.079,-28.066],[32.538,-10.821],[32.629,10.537],[0,0],[-16.512,-21.688],[-25.91,-7.912],[-25.62,8.823],[-15.752,22.259],[0,0]],"v":[[-146.76,77.19],[-115.891,-19.279],[-34.945,-79.102],[65.308,-79.539],[146.76,-20.424],[85.666,7.331],[20.434,-38.186],[-58.804,-36.784],[-122.423,11.012],[-146.636,87.332]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0.760784327984,0.776470601559,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":0.3,"ix":5},"lc":1,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[0.764705896378,0.772549033165,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":1},{"ddd":0,"ind":6,"ty":3,"nm":"▽ Cloud-2","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[154.125,213.189,0],"ix":2,"l":2},"a":{"a":0,"k":[154.125,213.189,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":7,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[360.949,250.592,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[11.951,0],[-11.951,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":8,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[203.523,106.282,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[104.727,0],[-104.727,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":9,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[259.45,417.241,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-0.2,-0.084],[-0.216,0],[0,0],[-0.2,0.086],[-0.151,0.158],[-0.077,0.205],[0.008,0.22],[0,0],[0.081,0.198],[0.15,0.152],[0.196,0.082],[0.212,0],[0.199,-0.08],[0.153,-0.152],[0.083,-0.2],[0,-0.217],[0,0],[-0.083,-0.202],[-0.153,-0.155]],"o":[[0.2,0.084],[0,0],[0.217,0],[0.2,-0.086],[0.151,-0.158],[0.077,-0.205],[0,0],[0,-0.214],[-0.081,-0.198],[-0.15,-0.152],[-0.196,-0.082],[-0.215,-0.004],[-0.199,0.08],[-0.153,0.152],[-0.083,0.2],[0,0],[0,0.219],[0.083,0.202],[0.153,0.155]],"v":[[-0.615,9.01],[0.015,9.137],[0.015,9.137],[0.647,9.007],[1.179,8.637],[1.525,8.085],[1.629,7.441],[1.629,-7.504],[1.506,-8.129],[1.156,-8.658],[0.633,-9.012],[0.015,-9.136],[-0.612,-9.021],[-1.147,-8.669],[-1.505,-8.136],[-1.63,-7.504],[-1.63,7.473],[-1.505,8.11],[-1.149,8.649]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":0.6,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[1,1,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":10,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[157.067,73.13,0],"to":[-1.667,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[147.067,73.13,0],"to":[0,0,0],"ti":[-1.667,0,0]},{"t":149.5,"s":[157.067,73.13,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[1.735,-9.881],[0,0],[0,0],[3.223,4.98],[5.39,2.39],[5.806,-0.978],[4.334,-4.027],[9.126,7.713],[11.819,1.339],[10.587,-5.48],[5.839,-10.479],[0,0],[7.624,-6.423]],"o":[[0,0],[0,0],[-0.009,-5.953],[-3.223,-4.98],[-5.39,-2.39],[-5.806,0.978],[-3.402,-11.526],[-9.126,-7.713],[-11.819,-1.339],[-10.587,5.48],[0,0],[-9.922,-0.058],[-7.624,6.423]],"v":[[-102.492,33.15],[102.398,33.15],[102.492,33.15],[97.538,16.396],[84.338,5.101],[67.18,2.937],[51.642,10.607],[32.434,-18.89],[0.321,-32.769],[-34.032,-26.42],[-59.216,-1.952],[-60.831,-1.952],[-88,7.904]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":11,"ty":4,"nm":"Vector","sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[228.073,59.744,0],"to":[1.667,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[238.073,59.744,0],"to":[0,0,0],"ti":[1.667,0,0]},{"t":149.5,"s":[228.073,59.744,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[1.734,-10.04],[0,0],[0,0],[3.228,5.088],[5.403,2.439],[5.818,-1.004],[4.337,-4.121],[9.149,7.88],[11.85,1.367],[10.613,-5.601],[5.849,-10.708],[0.543,0],[7.585,-6.55]],"o":[[0,0],[0,0],[-0.001,-6.079],[-3.228,-5.088],[-5.403,-2.439],[-5.818,1.004],[-3.407,-11.775],[-9.149,-7.88],[-11.85,-1.367],[-10.613,5.601],[-0.524,0],[-9.896,0.002],[-7.585,6.55]],"v":[[-102.583,33.855],[102.583,33.855],[102.583,33.845],[97.635,16.73],[84.407,5.194],[67.209,2.994],[51.646,10.849],[32.394,-19.288],[0.197,-33.466],[-34.244,-26.974],[-59.485,-1.969],[-61.096,-1.969],[-88.157,8.173]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"fl","c":{"a":0,"k":[0.658823549747,0.51372551918,0.972549021244,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":12,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[104.727,128.541,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[104.727,0],[-104.727,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":13,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[275.234,7.378,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-4.029,0],[0,4.075],[4.029,0],[0,-4.075]],"o":[[4.029,0],[0,-4.075],[-4.029,0],[0,4.075]],"v":[[0,7.378],[7.295,0],[0,-7.378],[-7.295,0]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":14,"ty":4,"nm":"Vector","parent":6,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[259.465,417.225,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-0.083,0.2],[0,0.217],[0,0],[0.282,0.309],[0.414,0.032],[0,0],[0.198,-0.084],[0.15,-0.155],[0.079,-0.202],[-0.004,-0.217],[-0.303,-0.306],[-0.428,0],[0,0],[-0.199,0.08],[-0.153,0.152]],"o":[[0.083,-0.2],[0,0],[0.001,-0.42],[-0.282,-0.309],[0,0],[-0.215,0],[-0.198,0.084],[-0.15,0.155],[-0.079,0.202],[0,0.433],[0.303,0.306],[0,0],[0.215,0.004],[0.199,-0.08],[0.153,-0.152]],"v":[[8.908,0.648],[9.034,0.016],[9.034,0.016],[8.597,-1.119],[7.513,-1.649],[-7.419,-1.649],[-8.044,-1.521],[-8.572,-1.159],[-8.92,-0.619],[-9.034,0.016],[-8.561,1.17],[-7.419,1.648],[7.389,1.648],[8.016,1.533],[8.55,1.181]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":0.6,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[1,1,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":15,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[242.685,198.682,0],"to":[1.667,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[252.685,198.682,0],"to":[0,0,0],"ti":[1.667,0,0]},{"t":149.5,"s":[242.685,198.682,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":1,"k":[{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":0,"s":[100,100,100]},{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":75,"s":[73,73,100]},{"t":149.5,"s":[100,100,100]}],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-88.537,0],[88.537,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":16,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[242.685,303.394,0],"to":[1.833,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[253.685,303.394,0],"to":[0,0,0],"ti":[1.833,0,0]},{"t":149.5,"s":[242.685,303.394,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":1,"k":[{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":0,"s":[100,100,100]},{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":75,"s":[73,73,100]},{"t":149.5,"s":[100,100,100]}],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-88.537,0],[88.537,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":17,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[275.254,249.986,0],"to":[-7.833,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[228.254,249.986,0],"to":[0,0,0],"ti":[-7.833,0,0]},{"t":149.5,"s":[275.254,249.986,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":1,"k":[{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":0,"s":[100,100,100]},{"i":{"x":[0.58,0.58,0.58],"y":[1,1,1]},"o":{"x":[0.42,0.42,0.42],"y":[0,0,0]},"t":75,"s":[94,94,100]},{"t":149.5,"s":[100,100,100]}],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-88.537,0],[88.537,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":18,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[407.4,357.868,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-8.879,8.98],[8.879,-8.98]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":-0.5,"op":149.5,"st":-0.5,"bm":0},{"ddd":0,"ind":19,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[618.716,354.744,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[8.879,8.995],[-8.879,-8.995]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":20,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[661.789,255.608,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[12.557,0],[-12.557,0]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":21,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[511.832,401.779,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[0,12.7],[0,-12.7]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":22,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[511.795,332.475,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[0,0],[-29.43,-30.795],[-42.327,-1.321],[-31.252,28.901],[-2.478,42.755],[0,0]],"o":[[-0.134,42.829],[29.43,30.795],[42.326,1.321],[31.252,-28.901],[0,0],[0,0]],"v":[[-162.561,-82.489],[-116.873,32.326],[-4.969,82.411],[109.775,39.4],[162.376,-72.348],[162.562,-76.304]],"c":false},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[0,0,0,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":2,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":23,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[512.988,250.08,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-114.992,0],[0,116.301],[114.992,0],[0,-116.301]],"o":[[114.992,0],[0,-116.301],[-114.992,0],[0,116.301]],"v":[[0,210.582],[208.212,0],[0,-210.582],[-208.212,0]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"fl","c":{"a":0,"k":[1,1,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":24,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[899.871,268.857,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-0.303,0.306],[0,0.433],[0.079,0.202],[0.15,0.155],[0.198,0.084],[0.215,0],[0,0],[0.309,-0.312],[0,-0.441],[-0.083,-0.2],[-0.153,-0.152],[-0.199,-0.08],[-0.215,0.004],[0,0]],"o":[[0.303,-0.306],[0.004,-0.217],[-0.079,-0.202],[-0.15,-0.155],[-0.198,-0.084],[0,0],[-0.436,0],[-0.309,0.312],[0,0.217],[0.083,0.2],[0.153,0.152],[0.199,0.08],[0,0],[0.428,0]],"v":[[8.561,1.17],[9.034,0.016],[8.92,-0.619],[8.572,-1.159],[8.044,-1.521],[7.419,-1.649],[-7.389,-1.649],[-8.552,-1.161],[-9.034,0.016],[-8.908,0.648],[-8.55,1.181],[-8.016,1.533],[-7.389,1.648],[7.419,1.648]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":0.6,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[1,1,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":25,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[899.87,268.889,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-0.198,-0.084],[-0.215,0],[0,0],[-0.307,0.299],[-0.016,0.43],[0,0],[0.083,0.2],[0.153,0.152],[0.199,0.08],[0.215,-0.004],[0.303,-0.306],[0,-0.433],[0,0],[-0.079,-0.202],[-0.15,-0.155]],"o":[[0.198,0.084],[0,0],[0.426,0],[0.307,-0.299],[0,0],[0,-0.217],[-0.083,-0.2],[-0.153,-0.152],[-0.199,-0.08],[-0.428,0],[-0.303,0.306],[0,0],[-0.004,0.217],[0.079,0.202],[0.15,0.155]],"v":[[-0.64,8.978],[-0.015,9.105],[-0.015,9.105],[1.127,8.64],[1.63,7.504],[1.63,-7.472],[1.504,-8.105],[1.146,-8.638],[0.612,-8.99],[-0.015,-9.105],[-1.157,-8.627],[-1.63,-7.472],[-1.63,7.441],[-1.516,8.076],[-1.168,8.616]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":0.6,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"fl","c":{"a":0,"k":[1,1,1,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":3,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":26,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[782.4,171.288,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[-4.029,0],[0,4.075],[4.029,0],[0,-4.075]],"o":[[4.029,0],[0,-4.075],[-4.029,0],[0,4.075]],"v":[[0,7.378],[7.295,0],[0,-7.378],[-7.295,0]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":1,"lj":1,"ml":4,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":27,"ty":4,"nm":"Vector","parent":2,"sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[791.256,397.798,0],"to":[-1.667,0,0],"ti":[0,0,0]},{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":75,"s":[781.256,397.798,0],"to":[0,0,0],"ti":[-1.667,0,0]},{"t":149.5,"s":[791.256,397.798,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[1.874,-10.673],[0,0],[0,0],[3.495,5.412],[5.853,2.595],[6.303,-1.068],[4.698,-4.382],[9.907,8.365],[12.826,1.449],[11.488,-5.948],[6.337,-11.371],[0,0],[8.213,-6.964]],"o":[[0,0],[0,0],[0.003,-6.463],[-3.495,-5.412],[-5.853,-2.595],[-6.303,1.068],[-3.7,-12.505],[-9.907,-8.365],[-12.826,-1.449],[-11.488,5.948],[0,0],[-10.717,0.003],[-8.213,6.964]],"v":[[-111.091,35.974],[111.091,35.974],[111.06,35.942],[105.709,17.743],[91.383,5.472],[72.754,3.131],[55.895,11.484],[35.032,-20.515],[0.177,-35.562],[-37.102,-28.665],[-64.432,-2.111],[-66.17,-2.111],[-95.476,8.672]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"st","c":{"a":0,"k":[1,1,1,1],"ix":3},"o":{"a":0,"k":100,"ix":4},"w":{"a":0,"k":4,"ix":5},"lc":1,"lj":2,"bm":0,"nm":"Stroke 1","mn":"ADBE Vector Graphic - Stroke","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":28,"ty":4,"nm":"Vector","sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":1,"k":[{"i":{"x":0.58,"y":1},"o":{"x":0.42,"y":0},"t":0,"s":[852.453,381.363,0],"to":[1.667,0,0],"ti":[0,0,0]},{"i":{"x":0.592,"y":1},"o":{"x":0.429,"y":0},"t":75,"s":[862.453,381.363,0],"to":[0,0,0],"ti":[0.881,0,0]},{"t":150,"s":[852.453,381.363,0]}],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ind":0,"ty":"sh","ix":1,"ks":{"a":0,"k":{"i":[[1.885,-10.926],[0,0],[0,0],[3.51,5.537],[5.876,2.655],[6.327,-1.093],[4.716,-4.484],[9.948,8.576],[12.885,1.487],[11.541,-6.095],[6.36,-11.652],[0.591,0],[8.248,-7.128]],"o":[[0,0],[0,0],[-0.001,-6.615],[-3.51,-5.537],[-5.876,-2.655],[-6.327,1.093],[-3.705,-12.814],[-9.948,-8.576],[-12.885,-1.487],[-11.541,6.095],[-0.57,0],[-10.761,0.002],[-8.248,7.128]],"v":[[-111.547,36.842],[111.547,36.842],[111.547,36.831],[106.166,18.207],[91.782,5.652],[73.082,3.259],[56.158,11.806],[35.224,-20.99],[0.215,-36.419],[-37.236,-29.354],[-64.683,-2.143],[-66.434,-2.143],[-95.86,8.894]],"c":true},"ix":2},"nm":"Path 1","mn":"ADBE Vector Shape - Group","hd":false},{"ty":"fl","c":{"a":0,"k":[0.658823549747,0.51372551918,0.972549021244,1],"ix":4},"o":{"a":0,"k":100,"ix":5},"r":1,"bm":0,"nm":"Fill 1","mn":"ADBE Vector Graphic - Fill","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Vector","np":2,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0},{"ddd":0,"ind":29,"ty":4,"nm":"Clock","sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[492,233,0],"ix":2,"l":2},"a":{"a":0,"k":[0,0,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"shapes":[{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[984,466],"ix":2},"p":{"a":0,"k":[0,0],"ix":3},"r":{"a":0,"k":0,"ix":4},"nm":"Rectangle Path 1","mn":"ADBE Vector Shape - Rect","hd":false},{"ty":"tr","p":{"a":0,"k":[0,0],"ix":2},"a":{"a":0,"k":[0,0],"ix":1},"s":{"a":0,"k":[100,100],"ix":3},"r":{"a":0,"k":0,"ix":6},"o":{"a":0,"k":100,"ix":7},"sk":{"a":0,"k":0,"ix":4},"sa":{"a":0,"k":0,"ix":5},"nm":"Transform"}],"nm":"Clock","np":1,"cix":2,"bm":0,"ix":1,"mn":"ADBE Vector Group","hd":false}],"ip":0,"op":150,"st":0,"bm":0}]}],"layers":[{"ddd":0,"ind":1,"ty":0,"nm":"Clock 2","refId":"comp_0","sr":1,"ks":{"o":{"a":0,"k":100,"ix":11},"r":{"a":0,"k":0,"ix":10},"p":{"a":0,"k":[620,354,0],"ix":2,"l":2},"a":{"a":0,"k":[492,233,0],"ix":1,"l":2},"s":{"a":0,"k":[100,100,100],"ix":6,"l":2}},"ao":0,"w":984,"h":466,"ip":0,"op":150,"st":0,"bm":0}],"markers":[]}';

        d.setAnimationDataJson(text);
    }

    // When re-parenting the item, re-initialize the animation
    // as the drawing context might become invalidated and since it's
    // stored in a variable by Lottie, we would crash somewhere in Qt.
    onParentChanged: Qt.callLater(d.destroyAndRecreate);

    Item {
        id: container
        anchors.fill: parent

        // HTML DOM compatibility API
        property real offsetWidth: width
        property real offsetHeight: height
        property var style: ({})
        property string innerHTML
        property string innerText
        property var itemData: []
        function appendChild(item) {
            item.parent = this;
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        // HTML DOM compatibility API
        property real offsetWidth: width
        property real offsetHeight: height
        property var style: ({})
        property var itemData: []
        function setAttribute(name, value) {
            // does nothing
        }
    }
}
