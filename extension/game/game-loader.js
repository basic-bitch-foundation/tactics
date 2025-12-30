var GODOT_CONFIG = {
    "args": [],
    "canvasResizePolicy": 2,
    "emscriptenPoolSize": 8,
    "ensureCrossOriginIsolationHeaders": false,
    "executable": "index",
    "experimentalVK": false,
    "fileSizes": {
        "index.pck": 1285600,
        "index.wasm": 1588912
    },
    "focusCanvas": true,
    "gdextensionLibs": [],
    "godotPoolSize": 4,
    "serviceWorker": ""
};

var GODOT_THREADS_ENABLED = false;

(function() {
    var statusdiv = document.getElementById('status');
    var progbar = document.getElementById('status-progress');
    var notice = document.getElementById('status-notice');
    var isinit = true;
    var currentmode = '';

    function changemode(mode) {
        if (currentmode === mode || !isinit) {
            return;
        }
        if (mode === 'hidden') {
            statusdiv.remove();
            isinit = false;
            return;
        }
        statusdiv.style.visibility = 'visible';
        progbar.style.display = mode === 'progress' ? 'block' : 'none';
        notice.style.display = mode === 'notice' ? 'block' : 'none';
        currentmode = mode;
    }

    function showerror(err) {
        console.error(err);
        var txt = 'error';
        if (err instanceof Error) {
            txt = err.message;
        } else if (typeof err === 'string') {
            txt = err;
        }
        notice.textContent = txt;
        notice.style.display = 'block';
        changemode('notice');
        isinit = false;
    }

    var eng = new Engine(GODOT_CONFIG);

    changemode('progress');
    eng.startGame({
        'onProgress': function(cur, tot) {
            if (cur > 0 && tot > 0) {
                progbar.value = cur;
                progbar.max = tot;
            } else {
                progbar.removeAttribute('value');
                progbar.removeAttribute('max');
            }
        },
    }).then(function() {
        changemode('hidden');
        console.log('ok');
    }, showerror);
}());