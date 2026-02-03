import Foundation

internal struct HTMLTemplate {
    static func generate(videoId: String) -> String {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body { margin: 0; padding: 0; background-color: black; }
                    #player { width: 100%; height: 100%; position: absolute; }
                </style>
            </head>
            <body>
                <div id="player"></div>
                <script>
                    var tag = document.createElement('script');
                    tag.src = "https://www.youtube.com/iframe_api";
                    var firstScriptTag = document.getElementsByTagName('script')[0];
                    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

                    var player;
                    function onYouTubeIframeAPIReady() {
                        player = new YT.Player('player', {
                            height: '100%',
                            width: '100%',
                            videoId: '\(videoId)',
                            playerVars: {
                                'playsinline': 1
                            },
                            events: {
                                'onReady': onReady,
                                'onStateChange': onStateChange,
                                'onError': onError
                            }
                        });
                    }

                    function onReady(event) {
                        window.webkit.messageHandlers.youTubeKitBridge.postMessage({
                            'event': 'onReady'
                        });
                    }

                    function onStateChange(event) {
                        window.webkit.messageHandlers.youTubeKitBridge.postMessage({
                            'event': 'onStateChange',
                            'data': event.data
                        });
                    }

                    function onError(event) {
                        window.webkit.messageHandlers.youTubeKitBridge.postMessage({
                            'event': 'onError',
                            'data': event.data
                        });
                    }
                </script>
            </body>
            </html>
            """
    }
}
